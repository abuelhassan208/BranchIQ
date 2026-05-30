import '../canonicalization/canonical_json_encoder.dart';

/// Represents a deterministic comparison of metrics for a single node
/// between two execution snapshots.
class NodeMetricDiff {
  /// The unique identifier of the node.
  final String nodeId;

  /// Whether the node existed in the source snapshot.
  final bool existsInSource;

  /// Whether the node existed in the target snapshot.
  final bool existsInTarget;

  /// A list of field names that changed, sorted lexicographically.
  final List<String> changedFields;

  /// The difference in probability (target - source), if available in both.
  final double? probabilityDelta;

  /// The difference in impact (target - source), if available in both.
  final double? impactDelta;

  /// The difference in cost (target - source), if available in both.
  final double? costDelta;

  /// The difference in confidence (target - source), if available in both.
  final double? confidenceDelta;

  /// The difference in final score (target - source), if available in both.
  final double? scoreDelta;

  /// Whether the pruning status changed between source and target.
  final bool pruningStatusChanged;

  /// The pruning reason in the source snapshot, if pruned.
  final String? sourcePruningReason;

  /// The pruning reason in the target snapshot, if pruned.
  final String? targetPruningReason;

  /// Creates a [NodeMetricDiff] instance with the provided fields.
  /// Enforces that [changedFields] is stored as an immutable list sorted lexicographically.
  NodeMetricDiff({
    required this.nodeId,
    required this.existsInSource,
    required this.existsInTarget,
    required List<String> changedFields,
    this.probabilityDelta,
    this.impactDelta,
    this.costDelta,
    this.confidenceDelta,
    this.scoreDelta,
    required this.pruningStatusChanged,
    this.sourcePruningReason,
    this.targetPruningReason,
  }) : changedFields =
            List<String>.unmodifiable(List<String>.from(changedFields)..sort());

  /// Converts this node metric diff into a stable, JSON-safe Map.
  /// Null optional fields are omitted to preserve compact serialization.
  Map<String, Object?> toJson() {
    return {
      'changedFields': changedFields,
      if (confidenceDelta != null) 'confidenceDelta': confidenceDelta,
      if (costDelta != null) 'costDelta': costDelta,
      'existsInSource': existsInSource,
      'existsInTarget': existsInTarget,
      if (impactDelta != null) 'impactDelta': impactDelta,
      'nodeId': nodeId,
      if (probabilityDelta != null) 'probabilityDelta': probabilityDelta,
      'pruningStatusChanged': pruningStatusChanged,
      if (scoreDelta != null) 'scoreDelta': scoreDelta,
      if (sourcePruningReason != null)
        'sourcePruningReason': sourcePruningReason,
      if (targetPruningReason != null)
        'targetPruningReason': targetPruningReason,
    };
  }

  /// Compiles this node metric diff into a compact, platform-invariant
  /// and byte-identical canonical JSON string.
  String toCanonicalJson() {
    return CanonicalJsonEncoder.encode(toJson());
  }
}
