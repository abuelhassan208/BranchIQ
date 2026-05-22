import '../config/pruning_config.dart';
import '../config/traversal_config.dart';
import '../internal/allocation_tracker.dart';
import '../internal/execution_budget.dart';
import '../models/decision_tree.dart';
import '../validation/tree_validator.dart';
import 'priority_traverser.dart';
import 'traversal_result.dart';

/// Runs the deterministic decision path traversal on a decision tree.
///
/// Validates the tree structure using [TreeValidator.validate] before performing
/// search operations. Throws validation errors immediately if structural
/// anomalies exist. Recoverable traversal issues (e.g. no valid paths, pruning
/// limitations) will result in a graceful [TraversalResult] return instead of throwing.
TraversalResult runTraversal(
  DecisionTree tree,
  TraversalConfig traversalConfig,
  PruningConfig pruningConfig, {
  ExecutionBudget? budget,
  AllocationTracker? tracker,
}) {
  // Validate tree structure first. Invalid structures will fail fast.
  TreeValidator.validate(tree);

  switch (traversalConfig.strategy) {
    case TraversalStrategy.priorityFirst:
      return PriorityTraverser.traverse(
        tree,
        traversalConfig,
        pruningConfig,
        budget: budget,
        tracker: tracker,
      );
  }
}
