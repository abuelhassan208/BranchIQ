import '../config/pruning_config.dart';
import '../config/traversal_config.dart';
import '../internal/allocation_tracker.dart';
import '../internal/execution_budget.dart';
import '../internal/runtime_guards.dart';
import '../internal/runtime_limits.dart';
import '../models/decision_node.dart';
import '../models/decision_tree.dart';
import 'path_backtracker.dart';
import 'path_candidate.dart';
import 'traversal_result.dart';

/// Implements a deterministic priority-first decision path traverser.
class PriorityTraverser {
  /// Traverses the decision tree using utility-prioritized best-first search.
  ///
  /// - Starts exploration at the root node.
  /// - Ranks candidate search paths deterministically by:
  ///   1. Accumulated path utility descending.
  ///   2. Tip node utility score descending.
  ///   3. Tip node ID lexicographically ascending.
  /// - Excludes pruned branches (where [pruningReason] is not null, empty, or "none").
  /// - Restricts traversal depth to [PruningConfig.maxDepth] and limits search size using [PruningConfig.maxNodeLimit].
  /// - Safe against missing child references, cycles, and empty trees.
  static TraversalResult traverse(
    DecisionTree tree,
    TraversalConfig traversalConfig,
    PruningConfig pruningConfig, {
    ExecutionBudget? budget,
    AllocationTracker? tracker,
  }) {
    final resolvedBudget = budget ??
        const ExecutionBudget(
          maxIterations: RuntimeLimits.defaultMaxTraversalIterations,
          maxVisitedNodes: RuntimeLimits.defaultMaxNodes,
        );
    final resolvedTracker = tracker ?? const AllocationTracker();

    final registry = tree.nodes;
    if (registry.isEmpty) {
      return TraversalResult(
        selectedNodes: const [],
        selectedNodeIds: const [],
        terminalNodeId: '',
        totalUtility: 0.0,
        wasFallback: false,
        failureReason: 'Tree registry is empty.',
        budget: resolvedBudget,
        tracker: resolvedTracker,
      );
    }

    DecisionNode root;
    try {
      root = tree.root;
    } catch (e) {
      return TraversalResult(
        selectedNodes: const [],
        selectedNodeIds: const [],
        terminalNodeId: '',
        totalUtility: 0.0,
        wasFallback: true,
        failureReason: 'Failed to resolve root: ${e.toString()}',
        budget: resolvedBudget,
        tracker: resolvedTracker,
      );
    }

    final frontier = <PathCandidate>[
      PathCandidate(
        nodeId: root.id,
        parentPathIds: const [],
        accumulatedScore: root.score,
        depth: 0,
        isTerminal: false,
      )
    ];

    final terminalCandidates = <PathCandidate>[];
    var currentBudget = resolvedBudget;
    var currentTracker = resolvedTracker;

    while (frontier.isNotEmpty) {
      // Sort candidates such that the best is at the end (for O(1) removal)
      frontier.sort((a, b) => -_compareCandidates(a, b, registry));
      final candidate = frontier.removeLast();

      currentBudget = currentBudget.incrementIterations();
      currentTracker = currentTracker.trackNodeTraversed();

      if (currentBudget.isExhausted()) {
        throw TraversalBudgetExceededException(
          'Traversal iterations budget exceeded: performed ${currentBudget.currentIterations} iterations, which exceeds the limit of ${currentBudget.maxIterations}.',
        );
      }

      final node = registry[candidate.nodeId];
      if (node == null) {
        continue;
      }

      // Check visited node limits dynamically
      currentBudget = currentBudget.incrementVisitedNodes();
      if (currentBudget.isExhausted()) {
        throw TraversalBudgetExceededException(
          'Traversal visited nodes budget exceeded: visited ${currentBudget.currentVisitedNodes} nodes, which exceeds the limit of ${currentBudget.maxVisitedNodes}.',
        );
      }

      final isMaxNodeLimitReached =
          currentBudget.currentVisitedNodes >= pruningConfig.maxNodeLimit;
      final isMaxDepthReached = candidate.depth >= pruningConfig.maxDepth;

      final validChildren = <DecisionNode>[];
      if (!isMaxDepthReached && !isMaxNodeLimitReached) {
        for (final cid in node.childIds) {
          // Cycle defense: skip children already visited along this path
          if (candidate.nodeId == cid ||
              candidate.parentPathIds.contains(cid)) {
            continue;
          }

          final child = registry[cid];
          if (child == null) {
            continue; // Handle missing child references safely
          }

          // Check if pruned
          final reason = child.pruningReason;
          final isPruned =
              reason != null && reason.isNotEmpty && reason != 'none';

          if (!isPruned) {
            validChildren.add(child);
          }
        }
      }

      if (validChildren.isEmpty) {
        terminalCandidates.add(PathCandidate(
          nodeId: candidate.nodeId,
          parentPathIds: candidate.parentPathIds,
          accumulatedScore: candidate.accumulatedScore,
          depth: candidate.depth,
          isTerminal: true,
        ));
      } else {
        for (final child in validChildren) {
          frontier.add(PathCandidate(
            nodeId: child.id,
            parentPathIds: [...candidate.parentPathIds, candidate.nodeId],
            accumulatedScore: candidate.accumulatedScore + child.score,
            depth: candidate.depth + 1,
            isTerminal: false,
          ));
        }
      }

      if (isMaxNodeLimitReached) {
        break;
      }
    }

    if (terminalCandidates.isEmpty) {
      return TraversalResult(
        selectedNodes: [root],
        selectedNodeIds: [root.id],
        terminalNodeId: root.id,
        totalUtility: root.score,
        wasFallback: registry.length > 1,
        failureReason: 'No terminal path candidates found.',
        budget: currentBudget,
        tracker: currentTracker,
      );
    }

    // Sort terminal candidates to find the absolute best one
    terminalCandidates.sort((a, b) => _compareCandidates(a, b, registry));
    final bestCandidate = terminalCandidates.first;

    final backtrackResult =
        PathBacktracker.backtrack(bestCandidate.nodeId, registry);
    if (backtrackResult.failureReason != null) {
      return TraversalResult(
        selectedNodes: [root],
        selectedNodeIds: [root.id],
        terminalNodeId: root.id,
        totalUtility: root.score,
        wasFallback: true,
        failureReason: backtrackResult.failureReason,
        budget: currentBudget,
        tracker: currentTracker,
      );
    }

    final pathNodes = backtrackResult.path;
    final pathNodeIds = pathNodes.map((n) => n.id).toList();
    final totalUtility = pathNodes.fold<double>(0.0, (sum, n) => sum + n.score);
    final wasFallback = pathNodeIds.length == 1 && registry.length > 1;

    return TraversalResult(
      selectedNodes: pathNodes,
      selectedNodeIds: pathNodeIds,
      terminalNodeId: bestCandidate.nodeId,
      totalUtility: totalUtility,
      wasFallback: wasFallback,
      budget: currentBudget,
      tracker: currentTracker,
    );
  }

  static int _compareCandidates(
    PathCandidate a,
    PathCandidate b,
    Map<String, DecisionNode> registry,
  ) {
    // 1. Accumulated utility descending
    if (a.accumulatedScore > b.accumulatedScore) return -1;
    if (a.accumulatedScore < b.accumulatedScore) return 1;

    // 2. Node score descending
    final nodeA = registry[a.nodeId];
    final nodeB = registry[b.nodeId];
    if (nodeA != null && nodeB != null) {
      if (nodeA.score > nodeB.score) return -1;
      if (nodeA.score < nodeB.score) return 1;
    }

    // 3. Node ID lexicographically ascending
    return a.nodeId.compareTo(b.nodeId);
  }
}
