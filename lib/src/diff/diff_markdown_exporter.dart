import '../canonicalization/canonical_float_formatter.dart';
import '../canonicalization/canonical_markdown_writer.dart';
import 'snapshot_diff.dart';

/// Provides deterministic and platform-independent markdown generation capabilities for snapshot diffs.
class DiffMarkdownExporter {
  /// Synchronously converts a [SnapshotDiff] report into a stable and beautifully formatted markdown string.
  static String export(SnapshotDiff diff) {
    final buffer = StringBuffer();

    // 1. Title Section
    buffer.write(CanonicalMarkdownWriter.heading(1, 'BranchIQ Snapshot Diff'));

    // 2. Summary Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Summary'));
    buffer.write(CanonicalMarkdownWriter.bullet(
        'Source Engine: ${diff.sourceEngineVersion} (Schema: ${diff.sourceSchemaVersion})'));
    buffer.write(CanonicalMarkdownWriter.bullet(
        'Target Engine: ${diff.targetEngineVersion} (Schema: ${diff.targetSchemaVersion})'));
    buffer.write(CanonicalMarkdownWriter.bullet(
        'Path Changed: ${diff.pathChanged ? "Yes" : "No"}'));
    buffer.write(CanonicalMarkdownWriter.bullet(
        'Utility Delta: ${CanonicalFloatFormatter.format(diff.utilityDelta)}'));
    buffer.write(CanonicalMarkdownWriter.bullet('Brief: ${diff.summary}'));
    buffer.write('\n');

    // 3. Selected Path Changes Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Selected Path Changes'));
    buffer.write(CanonicalMarkdownWriter.table(
      ['Path Type', 'Length', 'Path'],
      [
        [
          'Source Path',
          diff.sourceSelectedPath.length.toString(),
          diff.sourceSelectedPath.isEmpty
              ? '-'
              : diff.sourceSelectedPath.join(' → '),
        ],
        [
          'Target Path',
          diff.targetSelectedPath.length.toString(),
          diff.targetSelectedPath.isEmpty
              ? '-'
              : diff.targetSelectedPath.join(' → '),
        ],
      ],
    ));
    buffer.write('\n');

    // 4. Utility Changes Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Utility Changes'));
    buffer.write(CanonicalMarkdownWriter.table(
      ['Metric', 'Value'],
      [
        ['Source Utility', CanonicalFloatFormatter.format(diff.sourceUtility)],
        ['Target Utility', CanonicalFloatFormatter.format(diff.targetUtility)],
        ['Utility Delta', CanonicalFloatFormatter.format(diff.utilityDelta)],
      ],
    ));
    buffer.write('\n');

    // 5. Node Metric Changes Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Node Metric Changes'));
    if (diff.nodeMetricDiffs.isEmpty) {
      buffer.write('No node metric changes recorded.\n\n');
    } else {
      final headers = [
        'Node ID',
        'In Source',
        'In Target',
        'Score Delta',
        'Probability Delta',
        'Cost Delta',
        'Status Changed'
      ];
      final nodeRows = <List<String>>[];
      for (final nodeId in diff.nodeMetricDiffs.keys) {
        final metricDiff = diff.nodeMetricDiffs[nodeId]!;
        nodeRows.add([
          metricDiff.nodeId,
          metricDiff.existsInSource ? 'true' : 'false',
          metricDiff.existsInTarget ? 'true' : 'false',
          metricDiff.scoreDelta != null
              ? CanonicalFloatFormatter.format(metricDiff.scoreDelta!)
              : '-',
          metricDiff.probabilityDelta != null
              ? CanonicalFloatFormatter.format(metricDiff.probabilityDelta!)
              : '-',
          metricDiff.costDelta != null
              ? CanonicalFloatFormatter.format(metricDiff.costDelta!)
              : '-',
          metricDiff.pruningStatusChanged ? 'true' : 'false',
        ]);
      }
      buffer.write(CanonicalMarkdownWriter.table(headers, nodeRows));
      buffer.write('\n');
    }

    // 6. Pruning Changes Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Pruning Changes'));
    if (diff.newlyPrunedNodeIds.isEmpty && diff.newlyUnprunedNodeIds.isEmpty) {
      buffer.write('No pruning status changes identified.\n\n');
    } else {
      if (diff.newlyPrunedNodeIds.isNotEmpty) {
        buffer.write('Newly Pruned Nodes:\n');
        for (final id in diff.newlyPrunedNodeIds) {
          final nodeDiff = diff.nodeMetricDiffs[id];
          final reason = nodeDiff?.targetPruningReason ?? 'No reason provided';
          buffer.write(CanonicalMarkdownWriter.bullet('$id (Reason: $reason)'));
        }
        buffer.write('\n');
      }
      if (diff.newlyUnprunedNodeIds.isNotEmpty) {
        buffer.write('Newly Unpruned Nodes:\n');
        for (final id in diff.newlyUnprunedNodeIds) {
          buffer.write(CanonicalMarkdownWriter.bullet(id));
        }
        buffer.write('\n');
      }
    }

    // 7. Trace Changes Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Trace Changes'));
    buffer.write(CanonicalMarkdownWriter.bullet(
        'Trace Count Delta: ${diff.traceDiff.traceCountDelta}'));
    buffer.write('\n');

    if (diff.traceDiff.sourceOnlyTraces.isNotEmpty) {
      buffer.write('Source-Only Traces:\n');
      for (final trace in diff.traceDiff.sourceOnlyTraces) {
        buffer.write(CanonicalMarkdownWriter.bullet(trace));
      }
      buffer.write('\n');
    }

    if (diff.traceDiff.targetOnlyTraces.isNotEmpty) {
      buffer.write('Target-Only Traces:\n');
      for (final trace in diff.traceDiff.targetOnlyTraces) {
        buffer.write(CanonicalMarkdownWriter.bullet(trace));
      }
      buffer.write('\n');
    }

    if (diff.traceDiff.sharedTraces.isNotEmpty) {
      buffer.write('Shared Traces:\n');
      for (final trace in diff.traceDiff.sharedTraces) {
        buffer.write(CanonicalMarkdownWriter.bullet(trace));
      }
      buffer.write('\n');
    }

    return CanonicalMarkdownWriter.normalize(buffer.toString());
  }
}
