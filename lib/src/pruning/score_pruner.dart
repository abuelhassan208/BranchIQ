import '../config/pruning_config.dart';
import '../models/decision_node.dart';
import 'pruning_reason.dart';

/// Prunes decision nodes whose utility score falls below the configuration threshold.
class ScorePruner {
  /// Evaluates and filters the given list of nodes by their utility score.
  ///
  /// - Non-root nodes (where [parentId] != null and [depth] > 0) with an aggregate
  ///   utility score strictly less than [PruningConfig.minScore] are pruned.
  /// - Root nodes are always retained.
  /// - Pruned nodes are copied with their [pruningReason] updated.
  /// - Preserves the original order of nodes in the lists.
  static ({List<DecisionNode> retained, List<DecisionNode> pruned})
      pruneByScore(
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

      if (node.score < config.minScore) {
        pruned.add(node.copyWith(
          pruningReason: PruningReason.scoreBelowThreshold.name,
        ));
      } else {
        retained.add(node);
      }
    }

    return (retained: retained, pruned: pruned);
  }
}
