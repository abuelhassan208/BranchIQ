/// Represents the current state phase in the decision engine execution pipeline.
enum RuntimeState {
  /// Engine is initialized and ready for execution.
  idle,

  /// Validating tree structure consistency and constraints.
  validating,

  /// Calculating node score metrics using MAUT and confidence propagation.
  scoring,

  /// Excluding branches based on score thresholds or beam width.
  pruning,

  /// Navigating the active frontier nodes to find the best path.
  traversing,

  /// Execution pipeline successfully completed.
  completed,

  /// Execution failed due to tree structural or validation errors.
  failed,

  /// Traversal completed using a fallback execution path.
  fallback;

  /// Returns the corresponding [RuntimeState] matching the provided string.
  static RuntimeState fromString(String val) {
    return RuntimeState.values.firstWhere(
      (e) => e.name == val,
      orElse: () => throw ArgumentError('Unknown RuntimeState: "$val".'),
    );
  }
}
