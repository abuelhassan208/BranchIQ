import '../config/scoring_config.dart';
import '../models/decision_node.dart';
import 'normalization.dart';
import 'numeric_safety.dart';

/// Utility calculator responsible for computing decision node utility scores.
class ScoreCalculator {
  /// Calculates the aggregate utility score of a decision node using
  /// Multi-Attribute Utility Theory (MAUT) and confidence scaling.
  ///
  /// Formula:
  /// S(n) = K(n) * [ w_p * P(n) + w_i * I(n) - w_c * C_norm(n) ]
  ///
  /// Parameters:
  /// - [node]: The decision node to score.
  /// - [config]: The scoring configuration defining weights and ceiling.
  ///
  /// Safety: Sanitizes all parameters and clamps the outcome to the range [-1.0, 1.0].
  /// Deterministic Guarantee: Reproducibly returns the same score on identical inputs.
  static double calculateNodeScore(DecisionNode node, ScoringConfig config) {
    // Validate weights constraints defensively
    final totalWeights = config.wp + config.wi + config.wc;
    if ((totalWeights - 1.0).abs() > 1e-6) {
      throw ArgumentError('Scoring weights must sum to exactly 1.0.');
    }

    final p = clampProbability(node.probability);
    final i = clampImpact(node.impact);
    final k = clampConfidence(node.confidence);
    final cNorm = normalizeCost(node.cost, config.costCeiling);

    final rawUtility = (config.wp * p) + (config.wi * i) - (config.wc * cNorm);

    return safeClamp(k * rawUtility, -1.0, 1.0);
  }
}
