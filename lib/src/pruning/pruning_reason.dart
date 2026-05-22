/// Represents a deterministic reason why a decision node was pruned from the tree.
enum PruningReason {
  /// The node was not pruned.
  none,

  /// The node's transition probability fell below the minimum probability threshold.
  probabilityBelowThreshold,

  /// The node's aggregate utility score fell below the minimum score threshold.
  scoreBelowThreshold,

  /// The node was pruned because it exceeded the search frontier beam width limit.
  beamWidthExceeded,

  /// The node exceeded the maximum depth allowed by the system configuration.
  maxDepthExceeded,

  /// The evaluation frontier exceeded the maximum node limit.
  maxNodeLimitExceeded;

  /// Returns the JSON-safe string name of the pruning reason.
  String toJson() => name;

  /// Parses a JSON string to retrieve the corresponding [PruningReason].
  ///
  /// Defaults to [PruningReason.none] if unrecognized or null.
  static PruningReason fromJson(String? value) {
    if (value == null) return PruningReason.none;
    return PruningReason.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PruningReason.none,
    );
  }
}
