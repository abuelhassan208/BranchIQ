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
import '../pruning/pruning_pipeline.dart';
import '../traversal/traversal_pipeline.dart';
import '../validation/tree_validator.dart';
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
    bool enableDebug = false,
    bool enableBenchmark = false,
  }) {
    final traces = <RuntimeTrace>[];
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

        final scoredNode = node.copyWith(
          confidence: confidence,
          score: ScoreCalculator.calculateNodeScore(
            node.copyWith(confidence: confidence),
            scoringConfig,
          ),
        );
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
          'score': n.score,
          'depth': n.depth,
          'confidence': n.confidence,
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
              engineVersion: '0.1.0',
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
              engineVersion: '0.1.0',
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
}
