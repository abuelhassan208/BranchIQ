import '../config/pruning_config.dart';
import '../models/decision_node.dart';
import 'probability_pruner.dart';
import 'score_pruner.dart';
import 'beam_pruner.dart';
import 'pruning_result.dart';

/// Orchestrates the execution of the decision tree pruning steps.
class PruningPipeline {
  /// Runs the pruning steps in sequence:
  /// 1. Probability threshold pruning
  /// 2. Score threshold pruning
  /// 3. Search beam width pruning
  ///
  /// Returns a [PruningResult] with lists of retained and pruned nodes.
  /// Does not mutate the input nodes list. Does not throw on empty inputs.
  static PruningResult runPruningPipeline(
    List<DecisionNode> nodes,
    PruningConfig config,
  ) {
    if (nodes.isEmpty) {
      return PruningResult(
        retainedNodes: const [],
        prunedNodes: const [],
        wasFallbackRequired: false,
      );
    }

    // Step 1: Probability Pruning
    final probResult = ProbabilityPruner.pruneByProbability(nodes, config);

    // Step 2: Score Pruning
    final scoreResult = ScorePruner.pruneByScore(probResult.retained, config);

    // Step 3: Beam Width Pruning
    final beamResult = BeamPruner.applyBeamWidth(scoreResult.retained, config);

    // Combine all pruned nodes
    final pruned = [
      ...probResult.pruned,
      ...scoreResult.pruned,
      ...beamResult.pruned,
    ];

    // Determine if fallback is required:
    // Required when there were child nodes (non-root nodes) in the input,
    // but all of them were pruned (leaving zero child nodes retained).
    final hasChildrenInInput =
        nodes.any((n) => n.parentId != null || n.depth > 0);
    final hasChildrenInRetained =
        beamResult.retained.any((n) => n.parentId != null || n.depth > 0);
    final wasFallbackRequired = hasChildrenInInput && !hasChildrenInRetained;

    return PruningResult(
      retainedNodes: beamResult.retained,
      prunedNodes: pruned,
      wasFallbackRequired: wasFallbackRequired,
    );
  }
}
