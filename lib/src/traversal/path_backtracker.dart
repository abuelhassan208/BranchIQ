import '../models/decision_node.dart';

/// Result type representing either a successfully backtracked path or a backtracking failure reason.
class PathBacktrackResult {
  /// The reconstructed decision path from root to terminal node. Empty on failure.
  final List<DecisionNode> path;

  /// The description of the error if backtracking failed, or null if successful.
  final String? failureReason;

  /// Creates a [PathBacktrackResult] instance.
  const PathBacktrackResult({
    required this.path,
    this.failureReason,
  });
}

/// Helper utility to reconstruct decision paths by backtracking parent links.
class PathBacktracker {
  /// Reconstructs the root -> terminal node path iteratively starting from [terminalNodeId].
  ///
  /// Safe against infinite loops, missing nodes, and broken parent references.
  static PathBacktrackResult backtrack(
    String terminalNodeId,
    Map<String, DecisionNode> registry,
  ) {
    if (terminalNodeId.isEmpty) {
      return const PathBacktrackResult(
        path: [],
        failureReason: 'Terminal node ID must not be empty.',
      );
    }

    final path = <DecisionNode>[];
    final visited = <String>{};
    String? currentNodeId = terminalNodeId;

    while (currentNodeId != null) {
      if (!visited.add(currentNodeId)) {
        return PathBacktrackResult(
          path: const [],
          failureReason:
              'Backtracking cycle detected at node "$currentNodeId".',
        );
      }

      final node = registry[currentNodeId];
      if (node == null) {
        return PathBacktrackResult(
          path: const [],
          failureReason:
              'Broken parent chain: node "$currentNodeId" not found in registry.',
        );
      }

      path.add(node);
      currentNodeId = node.parentId;
    }

    // Reconstruct root -> terminal path by reversing the list
    return PathBacktrackResult(path: path.reversed.toList());
  }
}
