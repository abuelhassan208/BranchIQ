/// Defines search frontier boundaries and pruning thresholds.
class PruningConfig {
  /// The minimum transition probability required for a branch to be evaluated.
  final double minProbability;

  /// The minimum aggregate utility score required for a branch to be evaluated.
  final double minScore;

  /// The maximum number of child nodes evaluated at each level depth.
  final int beamWidth;

  /// The maximum depth level limit allowed during traversal.
  final int maxDepth;

  /// The absolute limit of maximum node evaluation allowed per traversal.
  final int maxNodeLimit;

  /// Creates a [PruningConfig] instance and throws [ArgumentError] on invalid ranges.
  PruningConfig({
    required this.minProbability,
    required this.minScore,
    required this.beamWidth,
    required this.maxDepth,
    required this.maxNodeLimit,
  }) {
    if (minProbability < 0.0 || minProbability > 1.0) {
      throw ArgumentError('minProbability must be in range [0.0, 1.0].');
    }
    if (minScore < -1.0 || minScore > 1.0) {
      throw ArgumentError('minScore must be in range [-1.0, 1.0].');
    }
    if (beamWidth < 1) {
      throw ArgumentError('beamWidth must be >= 1.');
    }
    if (maxDepth < 1 || maxDepth > 12) {
      throw ArgumentError('maxDepth must be in range [1, 12].');
    }
    if (maxNodeLimit < 1 || maxNodeLimit > 1000) {
      throw ArgumentError('maxNodeLimit must be in range [1, 1000].');
    }
  }

  /// Factory constructor that returns pre-configured default parameters.
  factory PruningConfig.defaultSettings() {
    return PruningConfig(
      minProbability: 0.0,
      minScore: -1.0,
      beamWidth: 3,
      maxDepth: 4,
      maxNodeLimit: 100,
    );
  }

  /// Deserializes a [PruningConfig] from a JSON map.
  factory PruningConfig.fromJson(Map<String, dynamic> json) {
    final minProbability = (json['minProbability'] as num?)?.toDouble();
    final minScore = (json['minScore'] as num?)?.toDouble();
    final beamWidth = json['beamWidth'] as int?;
    final maxDepth = json['maxDepth'] as int?;
    final maxNodeLimit = json['maxNodeLimit'] as int?;

    if (minProbability == null ||
        minScore == null ||
        beamWidth == null ||
        maxDepth == null ||
        maxNodeLimit == null) {
      throw ArgumentError('Missing required fields in PruningConfig JSON.');
    }

    return PruningConfig(
      minProbability: minProbability,
      minScore: minScore,
      beamWidth: beamWidth,
      maxDepth: maxDepth,
      maxNodeLimit: maxNodeLimit,
    );
  }

  /// Serializes this [PruningConfig] into a JSON map with stable key order.
  Map<String, dynamic> toJson() {
    return {
      'minProbability': minProbability,
      'minScore': minScore,
      'beamWidth': beamWidth,
      'maxDepth': maxDepth,
      'maxNodeLimit': maxNodeLimit,
    };
  }
}
