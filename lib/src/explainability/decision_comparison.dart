import '../canonicalization/canonical_float_formatter.dart';
import '../canonicalization/canonical_json_encoder.dart';
import '../canonicalization/canonical_markdown_writer.dart';

/// Represents a deterministic comparison report comparing the chosen selected path
/// against an alternative (rejected) path.
class DecisionComparison {
  /// The ordered sequence of node IDs representing the chosen selected path.
  final List<String> selectedPath;

  /// The ordered sequence of node IDs representing the alternative rejected path.
  final List<String> rejectedPath;

  /// The resolved path utility value of the selected path.
  final double selectedUtility;

  /// The resolved path utility value of the rejected path.
  final double rejectedUtility;

  /// The exact utility difference: selected path utility minus rejected path utility.
  final double utilityDelta;

  /// The number of nodes in the selected path.
  final int selectedLength;

  /// The number of nodes in the rejected path.
  final int rejectedLength;

  /// The difference in length: selected path length minus rejected path length.
  final int lengthDelta;

  /// Map from node ID to its score difference (selected score minus rejected score) for overlapping nodes.
  final Map<String, double> scoreDifferences;

  /// Map from node ID to its confidence difference for overlapping nodes.
  final Map<String, double> confidenceDifferences;

  /// List of node IDs on the rejected path that were excluded due to pruning.
  final List<String> prunedInRejectedOnly;

  /// Lexicographically sorted descriptive comparison logs.
  final List<String> pruningDifferences;

  /// Creates a [DecisionComparison] instance.
  const DecisionComparison({
    required this.selectedPath,
    required this.rejectedPath,
    required this.selectedUtility,
    required this.rejectedUtility,
    required this.utilityDelta,
    required this.selectedLength,
    required this.rejectedLength,
    required this.lengthDelta,
    required this.scoreDifferences,
    required this.confidenceDifferences,
    required this.prunedInRejectedOnly,
    required this.pruningDifferences,
  });

  /// Converts this comparison report into a stable Map representation.
  Map<String, Object?> toJson() {
    final sortedScores = <String, double>{};
    final sortedScoreKeys = scoreDifferences.keys.toList()..sort();
    for (final key in sortedScoreKeys) {
      sortedScores[key] = scoreDifferences[key]!;
    }

    final sortedConfidences = <String, double>{};
    final sortedConfKeys = confidenceDifferences.keys.toList()..sort();
    for (final key in sortedConfKeys) {
      sortedConfidences[key] = confidenceDifferences[key]!;
    }

    final sortedPruningDifferences = List<String>.from(pruningDifferences)
      ..sort();

    return {
      'confidenceDifferences': sortedConfidences,
      'lengthDelta': lengthDelta,
      'prunedInRejectedOnly': prunedInRejectedOnly,
      'pruningDifferences': sortedPruningDifferences,
      'rejectedLength': rejectedLength,
      'rejectedPath': rejectedPath,
      'rejectedUtility': rejectedUtility,
      'scoreDifferences': sortedScores,
      'selectedLength': selectedLength,
      'selectedPath': selectedPath,
      'selectedUtility': selectedUtility,
      'utilityDelta': utilityDelta,
    };
  }

  /// Encodes this report into a compact canonical JSON string.
  String toCanonicalJson() {
    return CanonicalJsonEncoder.encode(toJson());
  }

  /// Exports the comparative metrics into a beautifully structured, stable markdown document.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer
        .write(CanonicalMarkdownWriter.heading(1, 'Decision Path Comparison'));

    buffer.write(CanonicalMarkdownWriter.heading(2, 'Path Summary'));
    buffer.write(CanonicalMarkdownWriter.table(
      ['Path Type', 'Length', 'Utility', 'Path'],
      [
        [
          'Selected Path',
          selectedLength.toString(),
          CanonicalFloatFormatter.format(selectedUtility),
          selectedPath.join(' → '),
        ],
        [
          'Rejected Path',
          rejectedLength.toString(),
          CanonicalFloatFormatter.format(rejectedUtility),
          rejectedPath.join(' → '),
        ],
      ],
    ));
    buffer.write('\n');

    buffer.write(CanonicalMarkdownWriter.heading(2, 'Utility & Length Deltas'));
    buffer.write(CanonicalMarkdownWriter.bullet(
        'Selected path utility exceeded rejected path utility by ${CanonicalFloatFormatter.format(utilityDelta)}.'));
    buffer.write(CanonicalMarkdownWriter.bullet(
        'Selected path has $selectedLength nodes, rejected path has $rejectedLength nodes (delta: $lengthDelta).'));
    buffer.write('\n');

    buffer.write(CanonicalMarkdownWriter.heading(2, 'Score Differences'));
    if (scoreDifferences.isEmpty) {
      buffer.write('No overlapping nodes with score differences.\n\n');
    } else {
      final rows = <List<String>>[];
      final sortedKeys = scoreDifferences.keys.toList()..sort();
      for (final key in sortedKeys) {
        rows.add([key, CanonicalFloatFormatter.format(scoreDifferences[key]!)]);
      }
      buffer.write(CanonicalMarkdownWriter.table(
          ['Node ID', 'Score Delta (Selected - Rejected)'], rows));
      buffer.write('\n');
    }

    buffer.write(CanonicalMarkdownWriter.heading(2, 'Confidence Differences'));
    if (confidenceDifferences.isEmpty) {
      buffer.write('No confidence differences analyzed.\n\n');
    } else {
      final rows = <List<String>>[];
      final sortedKeys = confidenceDifferences.keys.toList()..sort();
      for (final key in sortedKeys) {
        rows.add(
            [key, CanonicalFloatFormatter.format(confidenceDifferences[key]!)]);
      }
      buffer.write(CanonicalMarkdownWriter.table(
          ['Node ID', 'Confidence Delta (Selected - Rejected)'], rows));
      buffer.write('\n');
    }

    buffer.write(CanonicalMarkdownWriter.heading(2, 'Pruning Analysis'));
    if (prunedInRejectedOnly.isEmpty && pruningDifferences.isEmpty) {
      buffer
          .write('No pruning discrepancies identified between the paths.\n\n');
    } else {
      if (prunedInRejectedOnly.isNotEmpty) {
        buffer.write('Pruned nodes on rejected path:\n');
        for (final id in prunedInRejectedOnly) {
          buffer.write(CanonicalMarkdownWriter.bullet(id));
        }
        buffer.write('\n');
      }
      if (pruningDifferences.isNotEmpty) {
        buffer.write('Pruning comparisons:\n');
        final sortedDiffs = List<String>.from(pruningDifferences)..sort();
        for (final diff in sortedDiffs) {
          buffer.write(CanonicalMarkdownWriter.bullet(diff));
        }
        buffer.write('\n');
      }
    }

    return CanonicalMarkdownWriter.normalize(buffer.toString());
  }
}
