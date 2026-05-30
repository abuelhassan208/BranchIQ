import '../canonicalization/canonical_json_encoder.dart';
import 'diff_markdown_exporter.dart';
import 'node_metric_diff.dart';
import 'trace_diff.dart';

/// Represents a comprehensive deterministic snapshot diff report.
/// Compares two historical runtime decision executions.
class SnapshotDiff {
  /// The schema version of the source snapshot.
  final String sourceSchemaVersion;

  /// The schema version of the target snapshot.
  final String targetSchemaVersion;

  /// The engine version of the source snapshot.
  final String sourceEngineVersion;

  /// The engine version of the target snapshot.
  final String targetEngineVersion;

  /// Whether the selected pathway changed.
  final bool pathChanged;

  /// The ordered sequence of node IDs in the source selected path.
  final List<String> sourceSelectedPath;

  /// The ordered sequence of node IDs in the target selected path.
  final List<String> targetSelectedPath;

  /// The total utility score in the source snapshot.
  final double sourceUtility;

  /// The total utility score in the target snapshot.
  final double targetUtility;

  /// The utility difference (target utility - source utility).
  final double utilityDelta;

  /// List of node IDs present only in the target snapshot, sorted lexicographically.
  final List<String> addedNodeIds;

  /// List of node IDs present only in the source snapshot, sorted lexicographically.
  final List<String> removedNodeIds;

  /// List of node IDs present in both snapshots but with different metrics, sorted lexicographically.
  final List<String> modifiedNodeIds;

  /// List of node IDs newly pruned in the target snapshot, sorted lexicographically.
  final List<String> newlyPrunedNodeIds;

  /// List of node IDs newly unpruned in the target snapshot, sorted lexicographically.
  final List<String> newlyUnprunedNodeIds;

  /// Detailed metric differences per node, stored lexicographically by node ID.
  final Map<String, NodeMetricDiff> nodeMetricDiffs;

  /// Detailed trace differences.
  final TraceDiff traceDiff;

  /// A concise, deterministic human-readable summary.
  final String summary;

  /// Creates a [SnapshotDiff] instance. All collections are stored as immutable,
  /// and sorting constraints are strictly enforced lexicographically.
  SnapshotDiff({
    required this.sourceSchemaVersion,
    required this.targetSchemaVersion,
    required this.sourceEngineVersion,
    required this.targetEngineVersion,
    required this.pathChanged,
    required List<String> sourceSelectedPath,
    required List<String> targetSelectedPath,
    required this.sourceUtility,
    required this.targetUtility,
    required this.utilityDelta,
    required List<String> addedNodeIds,
    required List<String> removedNodeIds,
    required List<String> modifiedNodeIds,
    required List<String> newlyPrunedNodeIds,
    required List<String> newlyUnprunedNodeIds,
    required Map<String, NodeMetricDiff> nodeMetricDiffs,
    required this.traceDiff,
    required this.summary,
  })  : sourceSelectedPath = List<String>.unmodifiable(sourceSelectedPath),
        targetSelectedPath = List<String>.unmodifiable(targetSelectedPath),
        addedNodeIds =
            List<String>.unmodifiable(List<String>.from(addedNodeIds)..sort()),
        removedNodeIds = List<String>.unmodifiable(
            List<String>.from(removedNodeIds)..sort()),
        modifiedNodeIds = List<String>.unmodifiable(
            List<String>.from(modifiedNodeIds)..sort()),
        newlyPrunedNodeIds = List<String>.unmodifiable(
            List<String>.from(newlyPrunedNodeIds)..sort()),
        newlyUnprunedNodeIds = List<String>.unmodifiable(
            List<String>.from(newlyUnprunedNodeIds)..sort()),
        nodeMetricDiffs = Map<String, NodeMetricDiff>.unmodifiable(
          Map.fromEntries(
            nodeMetricDiffs.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)),
          ),
        );

  /// Converts this snapshot diff report into a stable, JSON-safe Map.
  Map<String, Object?> toJson() {
    return {
      'addedNodeIds': addedNodeIds,
      'modifiedNodeIds': modifiedNodeIds,
      'newlyPrunedNodeIds': newlyPrunedNodeIds,
      'newlyUnprunedNodeIds': newlyUnprunedNodeIds,
      'nodeMetricDiffs': nodeMetricDiffs.map((k, v) => MapEntry(k, v.toJson())),
      'pathChanged': pathChanged,
      'removedNodeIds': removedNodeIds,
      'sourceEngineVersion': sourceEngineVersion,
      'sourceSchemaVersion': sourceSchemaVersion,
      'sourceSelectedPath': sourceSelectedPath,
      'sourceUtility': sourceUtility,
      'summary': summary,
      'targetEngineVersion': targetEngineVersion,
      'targetSchemaVersion': targetSchemaVersion,
      'targetSelectedPath': targetSelectedPath,
      'targetUtility': targetUtility,
      'traceDiff': traceDiff.toJson(),
      'utilityDelta': utilityDelta,
    };
  }

  /// Compiles this snapshot diff into a compact, platform-invariant
  /// and byte-identical canonical JSON string.
  String toCanonicalJson() {
    return CanonicalJsonEncoder.encode(toJson());
  }

  /// Formats this snapshot diff report into a beautiful, platform-invariant markdown document.
  String toMarkdown() {
    return DiffMarkdownExporter.export(this);
  }
}
