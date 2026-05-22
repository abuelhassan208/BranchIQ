import 'runtime_limits.dart';

/// Exception thrown when a structural or size limit is violated.
class RuntimeLimitExceededException implements Exception {
  /// Explanation of which limit was exceeded.
  final String message;

  /// Creates a [RuntimeLimitExceededException] with [message].
  const RuntimeLimitExceededException(this.message);

  @override
  String toString() => 'RuntimeLimitExceededException: $message';
}

/// Exception thrown when a traversal budget limit is exceeded.
class TraversalBudgetExceededException implements Exception {
  /// Explanation of which execution budget resource was exhausted.
  final String message;

  /// Creates a [TraversalBudgetExceededException] with [message].
  const TraversalBudgetExceededException(this.message);

  @override
  String toString() => 'TraversalBudgetExceededException: $message';
}

/// Deterministic runtime safety guards to protect the BranchIQ evaluation process.
class RuntimeGuards {
  RuntimeGuards._();

  /// Validates that the node count does not exceed the allowed maximum.
  static void validateNodeCount(int count, {int? maxNodes}) {
    final limit = maxNodes ?? RuntimeLimits.defaultMaxNodes;
    if (count > limit) {
      throw RuntimeLimitExceededException(
        'Node count limit exceeded: tree has $count nodes, which exceeds the limit of $limit.',
      );
    }
  }

  /// Validates that the tree depth does not exceed the allowed maximum.
  static void validateDepth(int depth, {int? maxDepth}) {
    final limit = maxDepth ?? RuntimeLimits.defaultMaxDepth;
    if (depth > limit) {
      throw RuntimeLimitExceededException(
        'Depth limit exceeded: tree depth is $depth, which exceeds the limit of $limit.',
      );
    }
  }

  /// Validates that the traversal iterations do not exceed the allowed budget.
  static void validateTraversalIterations(int iterations,
      {int? maxIterations}) {
    final limit = maxIterations ?? RuntimeLimits.defaultMaxTraversalIterations;
    if (iterations > limit) {
      throw TraversalBudgetExceededException(
        'Traversal iterations budget exceeded: performed $iterations iterations, which exceeds the limit of $limit.',
      );
    }
  }

  /// Validates that the single-node child count does not exceed the allowed maximum.
  static void validateChildCount(int count, {int? maxChildren}) {
    final limit = maxChildren ?? RuntimeLimits.defaultMaxChildrenPerNode;
    if (count > limit) {
      throw RuntimeLimitExceededException(
        'Child count limit exceeded: node has $count children, which exceeds the limit of $limit.',
      );
    }
  }
}
