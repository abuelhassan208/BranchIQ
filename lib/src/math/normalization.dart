import 'numeric_safety.dart';

/// Normalizes raw cost metrics into the range [0.0, 1.0] using linear scaling.
///
/// Formula:
/// C_norm(n) = min(1.0, max(0.0, C(n) / (C_max + epsilon)))
///
/// If raw cost is negative, it is clamped to 0.0.
///
/// Safety: Integrates epsilon stabilizers and clamps output bounds, protecting the scoring engine
/// from division-by-zero or cost values exceeding 1.0.
double normalizeCost(double cost, double costCeiling,
    {double epsilon = defaultEpsilon}) {
  final cleanCost = cost < 0.0 ? 0.0 : cost;
  if (costCeiling <= 0.0) {
    return 1.0; // Fail-safe default: treat as maximum cost.
  }
  return safeClamp(cleanCost / (costCeiling + epsilon), 0.0, 1.0);
}

/// Sanitizes and clamps raw probability values to the valid probability space [0.0, 1.0].
///
/// Deterministic Guarantee: Given any raw input, returns a valid probability boundary.
double clampProbability(double probability) {
  return safeClamp(probability, 0.0, 1.0);
}

/// Sanitizes and clamps raw confidence values to the valid confidence space [0.0, 1.0].
///
/// Deterministic Guarantee: Ensures confidence metrics do not exceed mathematical ranges.
double clampConfidence(double confidence) {
  return safeClamp(confidence, 0.0, 1.0);
}

/// Sanitizes and clamps raw impact parameters to the symmetric utility space [-1.0, 1.0].
///
/// Deterministic Guarantee: Prevents values outside the symmetric interval from skewing scoring.
double clampImpact(double impact) {
  return safeClamp(impact, -1.0, 1.0);
}
