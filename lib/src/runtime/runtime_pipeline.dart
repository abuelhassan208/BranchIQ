import '../config/pruning_config.dart';
import '../config/scoring_config.dart';
import '../config/traversal_config.dart';
import '../debug/benchmark_snapshot.dart';
import '../debug/debug_snapshot.dart';
import '../debug/runtime_trace.dart';
import '../internal/allocation_tracker.dart';
import '../internal/execution_budget.dart';
import '../internal/runtime_guards.dart';
import '../internal/runtime_limits.dart';
import '../math/confidence.dart';
import '../math/score_calculator.dart';
import '../models/decision_node.dart';
import '../models/decision_tree.dart';
import '../models/evaluation_context.dart';
import '../models/evaluation_result.dart';
import '../plugins/plugin_registry.dart';
import '../plugins/plugin_registry_validator.dart';
import '../pruning/pruning_pipeline.dart';
import '../traversal/traversal_pipeline.dart';
import '../validation/tree_validator.dart';
import '../version/branchiq_version.dart';
import 'runtime_state.dart';

/// Orchestrates the entire Entscheidung tree processing lifecycle.
class RuntimePipeline {
  /// Synchronously runs the decision engine pipeline.
  ///
  /// Safe against crashes by catching tree validation errors and handling
  /// fallbacks gracefully. Returns an immutable [EvaluationResult].
  static EvaluationResult runPipeline({
    required DecisionTree tree,
    required ScoringConfig scoringConfig,
    required PruningConfig pruningConfig,
    required TraversalConfig traversalConfig,
    EvaluationContext? context,
    PluginRegistry? plugins,
    bool enableDebug = false,
    bool enableBenchmark = false,
  }) {
    if (plugins != null) {
      PluginRegistryValidator.validate(plugins);
    }
    final traces = <RuntimeTrace>[];
    final pluginProvenance = <Map<String, dynamic>>[];
    const startedAt = 1000;
    const completedAt = 1005;
    const durationMs = completedAt - startedAt;

    var tracker = const AllocationTracker();
    var budget = const ExecutionBudget(
      maxIterations: RuntimeLimits.defaultMaxTraversalIterations,
      maxVisitedNodes: RuntimeLimits.defaultMaxNodes,
    );

    void logTrace(TracePhase phase, String message, {String? nodeId}) {
      if (enableDebug) {
        traces
            .add(RuntimeTrace(phase: phase, message: message, nodeId: nodeId));
      }
    }

    try {
      logTrace(TracePhase.validation, 'Validation started.');

      // 1. Validation Phase & Guards
      // 1.1 Structural checks
      TreeValidator.validate(tree);

      // 1.2 Limit checks
      RuntimeGuards.validateNodeCount(tree.nodes.length,
          maxNodes: pruningConfig.maxNodeLimit);
      for (final node in tree.nodes.values) {
        RuntimeGuards.validateDepth(node.depth,
            maxDepth: pruningConfig.maxDepth);
        RuntimeGuards.validateChildCount(node.childIds.length);
      }

      logTrace(TracePhase.validation, 'Validation successful.');
      logTrace(TracePhase.scoring, 'Scoring started.');

      // 2. Scoring Phase (BFS level-by-level propagation)
      final root = tree.root;
      final scoredNodes = <String, DecisionNode>{};
      final queue = <String>[root.id];
      final visited = <String>{};
      int scoringSteps = 0;

      while (queue.isNotEmpty) {
        final currentId = queue.removeAt(0);
        if (!visited.add(currentId)) continue;

        final node = tree.nodes[currentId]!;
        tracker = tracker.trackNodeScored();
        scoringSteps++;

        double confidence;
        if (node.parentId == null) {
          confidence = node.confidence;
        } else {
          final parent = scoredNodes[node.parentId]!;
          confidence = propagateConfidence(parent.confidence, node.depth);
        }

        var evaluatedNode = node.copyWith(confidence: confidence);
        if (plugins != null && plugins.evaluators.isNotEmpty) {
          for (final evaluator in plugins.evaluators) {
            final beforeProbability = evaluatedNode.probability;
            final beforeImpact = evaluatedNode.impact;
            final beforeCost = evaluatedNode.cost;
            final beforeMetadata = evaluatedNode.metadata;
            final beforeTags = evaluatedNode.tags;

            evaluatedNode = evaluator.evaluate(
                evaluatedNode, context ?? const EvaluationContext.empty());

            // Track modifications made by this evaluator
            final modifiedFields = <String, dynamic>{};
            if (evaluatedNode.probability != beforeProbability) {
              modifiedFields['probability'] = evaluatedNode.probability;
            }
            if (evaluatedNode.impact != beforeImpact) {
              modifiedFields['impact'] = evaluatedNode.impact;
            }
            if (evaluatedNode.cost != beforeCost) {
              modifiedFields['cost'] = evaluatedNode.cost;
            }
            if (!_isMapEqual(evaluatedNode.metadata, beforeMetadata)) {
              modifiedFields['metadata'] =
                  Map<String, dynamic>.from(evaluatedNode.metadata);
            }
            if (!_isListEqual(evaluatedNode.tags, beforeTags)) {
              modifiedFields['tags'] = List<String>.from(evaluatedNode.tags);
            }

            if (modifiedFields.isNotEmpty) {
              pluginProvenance.add({
                'pluginId': evaluator.id,
                'nodeId': node.id,
                'modifiedFields': modifiedFields,
              });
            }
          }
          // Restore engine-owned structural identity and confidence metrics
          evaluatedNode = DecisionNode(
            id: node.id,
            parentId: node.parentId,
            childIds: node.childIds,
            depth: node.depth,
            confidence: confidence,
            probability: evaluatedNode.probability,
            impact: evaluatedNode.impact,
            cost: evaluatedNode.cost,
            metadata: evaluatedNode.metadata,
            tags: evaluatedNode.tags,
            pruningReason: evaluatedNode.pruningReason,
            score: evaluatedNode.score,
          );
        }

        final finalScore =
            ScoreCalculator.calculateNodeScore(evaluatedNode, scoringConfig);
        final scoredNode = evaluatedNode.copyWith(score: finalScore);
        scoredNodes[currentId] = scoredNode;

        for (final cid in node.childIds) {
          if (tree.nodes.containsKey(cid)) {
            queue.add(cid);
          }
        }
      }

      final scoredTree = DecisionTree.fromNodes(scoredNodes.values.toList());
      logTrace(TracePhase.scoring, 'Scoring completed.');
      logTrace(TracePhase.pruning, 'Pruning started.');

      // 3. Pruning Phase
      final pruningResult = PruningPipeline.runPruningPipeline(
        scoredTree.nodes.values.toList(),
        pruningConfig,
      );

      tracker = tracker.trackNodesPruned(pruningResult.prunedNodes.length);

      final prunedNodesMap = <String, DecisionNode>{};
      for (final n in pruningResult.retainedNodes) {
        prunedNodesMap[n.id] = n;
      }
      for (final n in pruningResult.prunedNodes) {
        prunedNodesMap[n.id] = n;
      }
      final prunedTree = DecisionTree.fromNodes(prunedNodesMap.values.toList());

      logTrace(TracePhase.pruning, 'Pruning completed.');

      final scoredRoot = scoredNodes[root.id]!;
      BestPathResult bestPath;
      double totalUtility;
      bool wasFallback;
      String runtimeStateName;

      if (pruningResult.wasFallbackRequired) {
        logTrace(TracePhase.fallback,
            'Fallback triggered: All child branches were pruned.');
        logTrace(
            TracePhase.completion, 'Pipeline completed in fallback state.');

        bestPath =
            BestPathResult(nodes: [scoredRoot], nodeIds: [scoredRoot.id]);
        totalUtility = scoredRoot.score;
        wasFallback = true;
        runtimeStateName = RuntimeState.fallback.name;
      } else {
        logTrace(TracePhase.traversal, 'Traversal started.');

        // 4. Traversal Phase
        final traversalResult = runTraversal(
          prunedTree,
          traversalConfig,
          pruningConfig,
          budget: budget,
          tracker: tracker,
        );

        if (traversalResult.budget != null) {
          budget = traversalResult.budget!;
        }
        if (traversalResult.tracker != null) {
          tracker = traversalResult.tracker!;
        }

        bestPath = BestPathResult(
          nodes: traversalResult.selectedNodes,
          nodeIds: traversalResult.selectedNodeIds,
        );
        totalUtility = traversalResult.totalUtility;
        wasFallback = traversalResult.wasFallback;
        runtimeStateName = traversalResult.wasFallback
            ? RuntimeState.fallback.name
            : RuntimeState.completed.name;

        if (traversalResult.wasFallback) {
          logTrace(TracePhase.fallback,
              'Traversal fallback: ${traversalResult.failureReason ?? "No valid child paths found"}.');
        }

        logTrace(TracePhase.traversal, 'Traversal completed.');
        logTrace(TracePhase.completion,
            'Pipeline completed in $runtimeStateName state.');
      }

      final sessionTraces = traces.map((t) => t.toString()).toList();
      final prunedNodeIds = pruningResult.prunedNodes.map((n) => n.id).toList()
        ..sort();

      final nodeSnapshots = <String, Map<String, dynamic>>{};
      for (final n in prunedTree.nodes.values) {
        nodeSnapshots[n.id] = {
          'id': n.id,
          if (n.parentId != null) 'parentId': n.parentId,
          'childIds': n.childIds.toList(),
          'probability': n.probability,
          'impact': n.impact,
          'cost': n.cost,
          'confidence': n.confidence,
          'score': n.score,
          'depth': n.depth,
          if (n.metadata.isNotEmpty)
            'metadata': Map<String, dynamic>.from(n.metadata),
          if (n.tags.isNotEmpty) 'tags': n.tags.toList(),
          if (n.pruningReason != null) 'pruningReason': n.pruningReason,
        };
      }

      // 5. Benchmark calculation
      final benchmarkSnapshot = enableBenchmark
          ? BenchmarkSnapshot(
              totalNodes: tree.nodes.length,
              traversalIterations: budget.currentIterations,
              executionSteps: scoringSteps +
                  pruningResult.retainedNodes.length +
                  pruningResult.prunedNodes.length +
                  budget.currentIterations,
              retainedNodes: pruningResult.retainedNodes.length,
              prunedNodes: pruningResult.prunedNodes.length,
              selectedPathLength: bestPath.nodeIds.length,
              estimatedAllocationCount: tree.nodes.length * 3 +
                  budget.currentIterations * 2 +
                  pruningResult.prunedNodes.length +
                  bestPath.nodeIds.length +
                  5,
              runtimeState: runtimeStateName,
            )
          : null;

      final snapshot = enableDebug
          ? DebugSnapshot(
              engineVersion: branchIQVersion,
              rootId: root.id,
              selectedPath: bestPath.nodeIds,
              nodeSnapshots: nodeSnapshots,
              pruningTraces:
                  sessionTraces.where((t) => t.contains('[PRUNING]')).toList(),
              metadata: context?.toJson() ?? const {},
              runtimeTraces: sessionTraces,
              prunedNodeIds: prunedNodeIds,
              scoringSummaries: {
                'costCeiling': scoringConfig.costCeiling,
                'wp': scoringConfig.wp,
                'wi': scoringConfig.wi,
                'wc': scoringConfig.wc,
              },
              traversalSummaries: {
                'strategy': traversalConfig.strategy.name,
                'maxDepth': pruningConfig.maxDepth,
                'maxNodeLimit': pruningConfig.maxNodeLimit,
                'totalUtility': totalUtility,
              },
              benchmarkSnapshot: benchmarkSnapshot,
              pluginProvenance: pluginProvenance,
            )
          : null;

      return EvaluationResult(
        bestPath: bestPath,
        traces: sessionTraces,
        durationMs: durationMs,
        wasFallback: wasFallback,
        debugSnapshot: snapshot,
        totalUtility: totalUtility,
        runtimeState: runtimeStateName,
        benchmarkSnapshot: benchmarkSnapshot,
      );
    } catch (e) {
      logTrace(TracePhase.validation, 'Execution failed: ${e.toString()}');
      logTrace(TracePhase.completion, 'Pipeline completed in failed state.');

      final bestPath = BestPathResult(nodes: const [], nodeIds: const []);
      final sessionTraces = traces.map((t) => t.toString()).toList();

      final benchmarkSnapshot = enableBenchmark
          ? BenchmarkSnapshot(
              totalNodes: tree.nodes.length,
              traversalIterations: budget.currentIterations,
              executionSteps: budget.currentIterations + 1,
              retainedNodes: 0,
              prunedNodes: 0,
              selectedPathLength: 0,
              estimatedAllocationCount:
                  tree.nodes.length + budget.currentIterations + 5,
              runtimeState: RuntimeState.failed.name,
            )
          : null;

      final snapshot = enableDebug
          ? DebugSnapshot(
              engineVersion: branchIQVersion,
              rootId: tree.nodes.isNotEmpty ? tree.nodes.keys.first : '',
              selectedPath: const [],
              nodeSnapshots: const {},
              pruningTraces: const [],
              metadata: context?.toJson() ?? const {},
              runtimeTraces: sessionTraces,
              prunedNodeIds: const [],
              scoringSummaries: {
                'costCeiling': scoringConfig.costCeiling,
                'wp': scoringConfig.wp,
                'wi': scoringConfig.wi,
                'wc': scoringConfig.wc,
              },
              traversalSummaries: {
                'strategy': traversalConfig.strategy.name,
                'maxDepth': pruningConfig.maxDepth,
                'maxNodeLimit': pruningConfig.maxNodeLimit,
                'totalUtility': 0.0,
              },
              benchmarkSnapshot: benchmarkSnapshot,
              pluginProvenance: pluginProvenance,
            )
          : null;

      return EvaluationResult(
        bestPath: bestPath,
        traces: sessionTraces,
        durationMs: durationMs,
        wasFallback: false,
        errorMessage: e.toString(),
        debugSnapshot: snapshot,
        totalUtility: 0.0,
        runtimeState: RuntimeState.failed.name,
        benchmarkSnapshot: benchmarkSnapshot,
      );
    }
  }

  static bool _isMapEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final valA = a[key];
      final valB = b[key];
      if (valA is Map && valB is Map) {
        if (!_isMapEqual(
            valA.cast<String, dynamic>(), valB.cast<String, dynamic>())) {
          return false;
        }
      } else if (valA is List && valB is List) {
        if (!_isListEqual(valA, valB)) {
          return false;
        }
      } else if (valA != valB) {
        return false;
      }
    }
    return true;
  }

  static bool _isListEqual(List<dynamic> a, List<dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final valA = a[i];
      final valB = b[i];
      if (valA is Map && valB is Map) {
        if (!_isMapEqual(
            valA.cast<String, dynamic>(), valB.cast<String, dynamic>())) {
          return false;
        }
      } else if (valA is List && valB is List) {
        if (!_isListEqual(valA, valB)) {
          return false;
        }
      } else if (valA != valB) {
        return false;
      }
    }
    return true;
  }
}
