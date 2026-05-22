import '../config/pruning_config.dart';
import '../models/decision_node.dart';
import 'pruning_reason.dart';

/// Prunes decision nodes whose transition probability falls below the configuration threshold.
class ProbabilityPruner {
  /// Evaluates and filters the given list of nodes by their probability.
  ///
  /// - Non-root nodes (where [parentId] != null and [depth] > 0) with a probability
  ///   strictly less than [PruningConfig.minProbability] are pruned.
  /// - Root nodes are always retained.
  /// - Pruned nodes are copied with their [pruningReason] updated.
  /// - Preserves the original order of nodes in the lists.
  static ({List<DecisionNode> retained, List<DecisionNode> pruned})
      pruneByProbability(
    List<DecisionNode> nodes,
    PruningConfig config,
  ) {
    final retained = <DecisionNode>[];
    final pruned = <DecisionNode>[];

    for (final node in nodes) {
      final isRoot = node.parentId == null || node.depth == 0;
      if (isRoot) {
        retained.add(node);
        continue;
      }

      if (node.probability < config.minProbability) {
        pruned.add(node.copyWith(
          pruningReason: PruningReason.probabilityBelowThreshold.name,
        ));
      } else {
        retained.add(node);
      }
    }

    return (retained: retained, pruned: pruned);
  }
}
