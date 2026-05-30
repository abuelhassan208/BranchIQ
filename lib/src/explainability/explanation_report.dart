import '../canonicalization/canonical_json_encoder.dart';
import 'explanation_markdown_exporter.dart';
import 'node_explanation.dart';

/// An immutable container holding the comprehensive decision explainability report.
class ExplanationReport {
  /// The unique identifier of the tree root node.
  final String rootId;

  /// The ordered sequence of node IDs representing the chosen path.
  final List<String> selectedPath;

  /// The resolved total utility value of the selected path.
  final double selectedUtility;

  /// Map of node IDs to their respective [NodeExplanation] details.
  final Map<String, NodeExplanation> nodeExplanations;

  /// Lexicographically sorted list of node IDs that were not selected.
  final List<String> rejectedNodeIds;

  /// Immutable summary metrics representing pruning constraints.
  final Map<String, Object?> pruningSummary;

  /// Immutable summary metrics representing search traversal settings.
  final Map<String, Object?> traversalSummary;

  /// Chronological logs capturing runtime execution steps.
  final List<String> runtimeTraceSummary;

  /// User-defined context metadata associated with this evaluation.
  final Map<String, Object?> replayMetadata;

  /// The schema version of the parsed snapshot payload.
  final String schemaVersion;

  /// The plugin provenance records of evaluated node modifications.
  final List<Map<String, dynamic>> pluginProvenance;

  /// Creates an [ExplanationReport] instance.
  ExplanationReport({
    required this.rootId,
    required List<String> selectedPath,
    required this.selectedUtility,
    required Map<String, NodeExplanation> nodeExplanations,
    required List<String> rejectedNodeIds,
    required Map<String, Object?> pruningSummary,
    required Map<String, Object?> traversalSummary,
    required List<String> runtimeTraceSummary,
    required Map<String, Object?> replayMetadata,
    required this.schemaVersion,
    required List<Map<String, dynamic>> pluginProvenance,
  })  : selectedPath = List<String>.unmodifiable(selectedPath),
        nodeExplanations =
            Map<String, NodeExplanation>.unmodifiable(nodeExplanations),
        rejectedNodeIds = List<String>.unmodifiable(
            List<String>.from(rejectedNodeIds)..sort()),
        pruningSummary = Map<String, Object?>.unmodifiable(pruningSummary),
        traversalSummary = Map<String, Object?>.unmodifiable(traversalSummary),
        runtimeTraceSummary = List<String>.unmodifiable(runtimeTraceSummary),
        replayMetadata = Map<String, Object?>.unmodifiable(replayMetadata),
        pluginProvenance = List<Map<String, dynamic>>.unmodifiable(
          pluginProvenance.map((p) => Map<String, dynamic>.unmodifiable(p)),
        );

  /// Converts this report to a stable Map representation.
  Map<String, Object?> toJson() {
    final sortedExplanations = <String, Map<String, Object?>>{};
    final sortedKeys = nodeExplanations.keys.toList()..sort();
    for (final key in sortedKeys) {
      sortedExplanations[key] = nodeExplanations[key]!.toJson();
    }

    return {
      'nodeExplanations': sortedExplanations,
      'pluginProvenance': pluginProvenance,
      'pruningSummary': pruningSummary,
      'rejectedNodeIds': rejectedNodeIds,
      'replayMetadata': replayMetadata,
      'rootId': rootId,
      'runtimeTraceSummary': runtimeTraceSummary,
      'schemaVersion': schemaVersion,
      'selectedPath': selectedPath,
      'selectedUtility': selectedUtility,
      'traversalSummary': traversalSummary,
    };
  }

  /// Encodes this report into a compact, platform-invariant,
  /// and byte-identical canonical JSON string.
  String toCanonicalJson() {
    return CanonicalJsonEncoder.encode(toJson());
  }

  /// Exports the report into a structured, highly formatted markdown document.
  String toMarkdown() {
    return ExplanationMarkdownExporter.export(this);
  }
}
