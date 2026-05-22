import '../config/pruning_config.dart';
import '../math/deterministic_ordering.dart';
import '../models/decision_node.dart';
import 'pruning_reason.dart';

/// Prunes decision nodes that exceed the configuration's search beam width limit.
class BeamPruner {
  /// Evaluates and filters the given list of nodes by sorting and limiting candidates.
  ///
  /// - All root nodes (where [parentId] == null or [depth] == 0) are always retained.
  /// - Non-root nodes are sorted descending by score (with tie-breaking lexicographically
  ///   by node ID ascending).
  /// - The top [PruningConfig.beamWidth] non-root nodes are retained.
  /// - Remaining non-root nodes are pruned with [PruningReason.beamWidthExceeded].
  /// - Returns a record of sorted retained and pruned node lists.
  static ({List<DecisionNode> retained, List<DecisionNode> pruned})
      applyBeamWidth(
    List<DecisionNode> nodes,
    PruningConfig config,
  ) {
    // Copy the list to avoid mutating the input argument
    final sorted = List<DecisionNode>.from(nodes)..sort(compareNodes);

    final retained = <DecisionNode>[];
    final pruned = <DecisionNode>[];

    int retainedNonRoots = 0;
    for (final node in sorted) {
      final isRoot = node.parentId == null || node.depth == 0;
      if (isRoot) {
        retained.add(node);
      } else {
        if (retainedNonRoots < config.beamWidth) {
          retained.add(node);
          retainedNonRoots++;
        } else {
          pruned.add(node.copyWith(
            pruningReason: PruningReason.beamWidthExceeded.name,
          ));
        }
      }
    }

    return (retained: retained, pruned: pruned);
  }
}
