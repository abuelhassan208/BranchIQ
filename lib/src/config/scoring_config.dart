/// Defines the scoring weights used to evaluate node utility paths.
class ScoringConfig {
  /// Weight assigned to node transition probability.
  final double wp;

  /// Weight assigned to node utility impact.
  final double wi;

  /// Weight assigned to normalized node cost penalty.
  final double wc;

  /// The cost boundary threshold ceiling used to normalize raw costs.
  final double costCeiling;

  /// Creates a [ScoringConfig] instance with production-grade runtime validation.
  ScoringConfig({
    required this.wp,
    required this.wi,
    required this.wc,
    required this.costCeiling,
  }) {
    if (wp < 0.0 || wi < 0.0 || wc < 0.0) {
      throw ArgumentError('Weights must be non-negative.');
    }
    final total = wp + wi + wc;
    if ((total - 1.0).abs() > 1e-6) {
      throw ArgumentError('Weights must sum to 1.0 within tolerance.');
    }
    if (costCeiling <= 0.0) {
      throw ArgumentError('costCeiling must be positive.');
    }
  }

  /// Factory constructor that returns balanced scoring parameters.
  factory ScoringConfig.balanced({double costCeiling = 1000.0}) {
    return ScoringConfig(
      wp: 1.0 / 3.0,
      wi: 1.0 / 3.0,
      wc: 1.0 / 3.0,
      costCeiling: costCeiling,
    );
  }

  /// Deserializes a [ScoringConfig] from a JSON map.
  factory ScoringConfig.fromJson(Map<String, dynamic> json) {
    final wp = (json['wp'] as num?)?.toDouble();
    final wi = (json['wi'] as num?)?.toDouble();
    final wc = (json['wc'] as num?)?.toDouble();
    final costCeiling = (json['costCeiling'] as num?)?.toDouble();

    if (wp == null || wi == null || wc == null || costCeiling == null) {
      throw ArgumentError('Missing required fields in ScoringConfig JSON.');
    }

    return ScoringConfig(
      wp: wp,
      wi: wi,
      wc: wc,
      costCeiling: costCeiling,
    );
  }

  /// Serializes this [ScoringConfig] into a JSON map with stable key order.
  Map<String, dynamic> toJson() {
    return {
      'wp': wp,
      'wi': wi,
      'wc': wc,
      'costCeiling': costCeiling,
    };
  }
}
