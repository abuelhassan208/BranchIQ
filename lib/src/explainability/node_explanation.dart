import '../canonicalization/canonical_json_encoder.dart';

/// Represents a deterministic, evidence-based explainability report for a single node.
class NodeExplanation {
  /// The unique identifier of this node.
  final String nodeId;

  /// The final score assigned to this node during evaluation.
  final double score;

  /// The raw probability weight contributed to the score, if available.
  final double? probabilityContribution;

  /// The raw impact weight contributed to the score, if available.
  final double? impactContribution;

  /// The raw cost weight contributed to the score, if available.
  final double? costContribution;

  /// The raw confidence score associated with this node, if available.
  final double? confidenceContribution;

  /// The pruning outcome of this node (e.g. "retained" or "pruned").
  final String pruningStatus;

  /// The specific reason for why this node was pruned, if any.
  final String? pruningReason;

  /// The 1-based order in which this node was traversed in the selected path, if selected.
  final int? traversalRank;

  /// Whether this node was chosen as part of the final selected pathway.
  final bool selected;

  /// Whether this node is a terminal leaf node (either selected or pruned).
  final bool terminal;

  /// Creates a [NodeExplanation] instance.
  const NodeExplanation({
    required this.nodeId,
    required this.score,
    this.probabilityContribution,
    this.impactContribution,
    this.costContribution,
    this.confidenceContribution,
    required this.pruningStatus,
    this.pruningReason,
    this.traversalRank,
    required this.selected,
    required this.terminal,
  });

  /// Converts this node explanation into a stable Map representation.
  Map<String, Object?> toJson() {
    return {
      if (confidenceContribution != null)
        'confidenceContribution': confidenceContribution,
      if (costContribution != null) 'costContribution': costContribution,
      if (impactContribution != null) 'impactContribution': impactContribution,
      'nodeId': nodeId,
      if (probabilityContribution != null)
        'probabilityContribution': probabilityContribution,
      if (pruningReason != null) 'pruningReason': pruningReason,
      'pruningStatus': pruningStatus,
      'score': score,
      'selected': selected,
      'terminal': terminal,
      if (traversalRank != null) 'traversalRank': traversalRank,
    };
  }

  /// Converts this node explanation into a compact, platform-invariant,
  /// and byte-identical canonical JSON string.
  String toCanonicalJson() {
    return CanonicalJsonEncoder.encode(toJson());
  }
}
