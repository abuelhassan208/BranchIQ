/// Immutable execution budget tracker to manage traversal resource usage.
class ExecutionBudget {
  /// The maximum number of traversal iterations allowed.
  final int maxIterations;

  /// The current count of completed iterations.
  final int currentIterations;

  /// The maximum number of visited nodes allowed.
  final int maxVisitedNodes;

  /// The current count of visited nodes.
  final int currentVisitedNodes;

  /// Creates a new [ExecutionBudget] instance.
  const ExecutionBudget({
    required this.maxIterations,
    this.currentIterations = 0,
    required this.maxVisitedNodes,
    this.currentVisitedNodes = 0,
  });

  /// Returns a new copy of [ExecutionBudget] with [currentIterations] incremented by 1.
  ExecutionBudget incrementIterations() {
    return ExecutionBudget(
      maxIterations: maxIterations,
      currentIterations: currentIterations + 1,
      maxVisitedNodes: maxVisitedNodes,
      currentVisitedNodes: currentVisitedNodes,
    );
  }

  /// Returns a new copy of [ExecutionBudget] with [currentVisitedNodes] incremented by 1.
  ExecutionBudget incrementVisitedNodes() {
    return ExecutionBudget(
      maxIterations: maxIterations,
      currentIterations: currentIterations,
      maxVisitedNodes: maxVisitedNodes,
      currentVisitedNodes: currentVisitedNodes + 1,
    );
  }

  /// Checks if the budget constraints have been violated.
  bool isExhausted() {
    return currentIterations > maxIterations ||
        currentVisitedNodes > maxVisitedNodes;
  }
}
