import 'dart:math' as math;
import 'normalization.dart';
import 'numeric_safety.dart';

/// Calculates the transition confidence decay coefficient for a target depth.
///
/// Formula:
/// gamma(d) = gamma_0 * e^(-lambda * d)
///
/// Parameters:
/// - [depth]: The target node depth levels.
/// - [gamma0]: Baseline transition confidence constant (defaults to 0.90).
/// - [lambda]: Decay rate exponent constant (defaults to 0.1).
double calculateDecayCoefficient(
  int depth, {
  double gamma0 = 0.90,
  double lambda = 0.1,
}) {
  final cleanGamma0 = safeClamp(gamma0, 0.0, 1.0);
  final cleanLambda = safeClamp(lambda, 0.0, 1.0);
  final cleanDepth = depth < 0 ? 0 : depth;

  return cleanGamma0 * math.exp(-cleanLambda * cleanDepth);
}

/// Propagates confidence downwards from a parent to a child node at the given depth.
///
/// Formula:
/// K(n_child) = K(n_parent) * gamma(d)
///
/// Deterministic Guarantee: Given finite real parameters, returns a valid confidence in [0.0, 1.0].
double propagateConfidence(
  double parentConfidence,
  int depth, {
  double gamma0 = 0.90,
  double lambda = 0.1,
}) {
  final cleanParent = clampConfidence(parentConfidence);
  final decay =
      calculateDecayCoefficient(depth, gamma0: gamma0, lambda: lambda);
  return clampConfidence(cleanParent * decay);
}

/// Dampens the confidence value using a damping multiplier coefficient.
///
/// Safety: Returns confidence clamped to [0.0, 1.0].
double dampenConfidence(double confidence, double dampingFactor) {
  final cleanConfidence = clampConfidence(confidence);
  final cleanFactor = safeClamp(dampingFactor, 0.0, 1.0);
  return clampConfidence(cleanConfidence * cleanFactor);
}

/// Applies confidence attenuation to a raw score.
///
/// Formula:
/// S = score * confidence
///
/// Safety: Returns the final score clamped to [-1.0, 1.0].
double applyConfidence(double score, double confidence) {
  final cleanScore = safeClamp(score, -1.0, 1.0);
  final cleanConfidence = clampConfidence(confidence);
  return safeClamp(cleanScore * cleanConfidence, -1.0, 1.0);
}
