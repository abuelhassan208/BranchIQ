import '../models/decision_node.dart';

/// Represents the immutable results of a decision tree pruning operation.
class PruningResult {
  /// The list of decision nodes retained for traversal.
  final List<DecisionNode> retainedNodes;

  /// The list of decision nodes pruned during evaluation.
  final List<DecisionNode> prunedNodes;

  /// The total number of nodes passed into the pruning operation.
  final int totalInputCount;

  /// The count of nodes that were successfully retained.
  final int retainedCount;

  /// The count of nodes that were pruned.
  final int prunedCount;

  /// Indicates if all child nodes were pruned, requiring a fallback decision path.
  final bool wasFallbackRequired;

  /// Creates a [PruningResult] instance.
  ///
  /// Forces unmodifiable copies of the input lists to ensure strict immutability.
  PruningResult({
    required List<DecisionNode> retainedNodes,
    required List<DecisionNode> prunedNodes,
    required this.wasFallbackRequired,
  })  : retainedNodes = List<DecisionNode>.unmodifiable(retainedNodes),
        prunedNodes = List<DecisionNode>.unmodifiable(prunedNodes),
        totalInputCount = retainedNodes.length + prunedNodes.length,
        retainedCount = retainedNodes.length,
        prunedCount = prunedNodes.length;

  /// Deserializes a [PruningResult] from a JSON map.
  factory PruningResult.fromJson(Map<String, dynamic> json) {
    final rawRetained = json['retainedNodes'] as List<dynamic>? ?? const [];
    final rawPruned = json['prunedNodes'] as List<dynamic>? ?? const [];

    final retained = rawRetained
        .map((n) => DecisionNode.fromJson(n as Map<String, dynamic>))
        .toList();
    final pruned = rawPruned
        .map((n) => DecisionNode.fromJson(n as Map<String, dynamic>))
        .toList();

    final wasFallbackRequired = json['wasFallbackRequired'] as bool? ?? false;

    return PruningResult(
      retainedNodes: retained,
      prunedNodes: pruned,
      wasFallbackRequired: wasFallbackRequired,
    );
  }

  /// Serializes this [PruningResult] into a JSON map with stable key ordering.
  Map<String, dynamic> toJson() {
    return {
      'retainedNodes': retainedNodes.map((n) => n.toJson()).toList(),
      'prunedNodes': prunedNodes.map((n) => n.toJson()).toList(),
      'totalInputCount': totalInputCount,
      'retainedCount': retainedCount,
      'prunedCount': prunedCount,
      'wasFallbackRequired': wasFallbackRequired,
    };
  }
}
