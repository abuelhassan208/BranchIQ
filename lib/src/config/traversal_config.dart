/// Strategies for traversing and finding paths in the decision tree.
enum TraversalStrategy {
  /// Modified A* path search utilizing priority-first nodes.
  priorityFirst,
}

/// Defines traversal configuration parameters for path searches.
class TraversalConfig {
  /// The search strategy used to navigate scored and pruned trees.
  final TraversalStrategy strategy;

  /// Creates a [TraversalConfig] instance.
  const TraversalConfig({
    this.strategy = TraversalStrategy.priorityFirst,
  });

  /// Deserializes a [TraversalConfig] from a JSON map.
  factory TraversalConfig.fromJson(Map<String, dynamic> json) {
    final strategyStr = json['strategy'] as String?;
    if (strategyStr == null) {
      return const TraversalConfig(strategy: TraversalStrategy.priorityFirst);
    }
    final match =
        TraversalStrategy.values.cast<TraversalStrategy?>().firstWhere(
              (e) => e?.name == strategyStr,
              orElse: () => null,
            );
    if (match == null) {
      throw ArgumentError('Invalid TraversalStrategy: "$strategyStr".');
    }
    return TraversalConfig(strategy: match);
  }

  /// Serializes this [TraversalConfig] into a JSON map with stable key order.
  Map<String, dynamic> toJson() {
    return {
      'strategy': strategy.name,
    };
  }
}
