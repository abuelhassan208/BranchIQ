import '../canonicalization/canonical_float_formatter.dart';
import '../canonicalization/canonical_markdown_writer.dart';
import 'explanation_report.dart';

/// Provides deterministic and platform-independent markdown generation capabilities for decision explanation reports.
class ExplanationMarkdownExporter {
  /// Synchronously converts an [ExplanationReport] into a stable and beautifully formatted markdown string.
  static String export(ExplanationReport report) {
    final buffer = StringBuffer();

    // 1. Title Section
    buffer.write(
        CanonicalMarkdownWriter.heading(1, 'BranchIQ Explanation Report'));

    // 2. Selected Path Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Selected Path'));
    if (report.selectedPath.isEmpty) {
      buffer.write('No path selected.\n\n');
    } else {
      buffer.write('Path: ${report.selectedPath.join(' → ')}\n\n');
      for (final nodeId in report.selectedPath) {
        buffer.write(CanonicalMarkdownWriter.bullet(nodeId));
      }
      buffer.write('\n');
    }

    // 3. Utility Summary Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Utility Summary'));
    buffer.write(CanonicalMarkdownWriter.table(
      ['Metric', 'Value'],
      [
        ['Root Node', report.rootId],
        [
          'Selected Path Utility',
          CanonicalFloatFormatter.format(report.selectedUtility)
        ],
        ['Schema Version', report.schemaVersion],
      ],
    ));
    buffer.write('\n');

    // 4. Traversal Analysis Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Traversal Analysis'));
    final travRows = <List<String>>[];
    final sortedTravKeys = report.traversalSummary.keys.toList()..sort();
    for (final key in sortedTravKeys) {
      final value = report.traversalSummary[key];
      final valStr = value is double
          ? CanonicalFloatFormatter.format(value)
          : value.toString();
      travRows.add([key, valStr]);
    }
    if (travRows.isNotEmpty) {
      buffer.write(
          CanonicalMarkdownWriter.table(['Parameter', 'Value'], travRows));
    } else {
      buffer.write('No traversal summary available.\n');
    }
    buffer.write('\n');

    // 5. Pruning Analysis Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Pruning Analysis'));
    if (report.rejectedNodeIds.isEmpty) {
      buffer.write('No nodes were pruned during evaluation.\n\n');
    } else {
      buffer.write('Pruned Node IDs:\n');
      for (final id in report.rejectedNodeIds) {
        buffer.write(CanonicalMarkdownWriter.bullet(id));
      }
      buffer.write('\n');
    }
    final pruningRows = <List<String>>[];
    final sortedPruneKeys = report.pruningSummary.keys.toList()..sort();
    for (final key in sortedPruneKeys) {
      final value = report.pruningSummary[key];
      final valStr = value is double
          ? CanonicalFloatFormatter.format(value)
          : value.toString();
      pruningRows.add([key, valStr]);
    }
    if (pruningRows.isNotEmpty) {
      buffer.write(
          CanonicalMarkdownWriter.table(['Parameter', 'Value'], pruningRows));
      buffer.write('\n');
    }

    // 6. Node Explanations Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Node Explanations'));
    final headers = [
      'Node ID',
      'Score',
      'Status',
      'Selected',
      'Terminal',
      'Rank',
      'Pruning Reason'
    ];
    final nodeRows = <List<String>>[];
    final sortedNodeIds = report.nodeExplanations.keys.toList()..sort();
    for (final id in sortedNodeIds) {
      final exp = report.nodeExplanations[id]!;
      nodeRows.add([
        exp.nodeId,
        CanonicalFloatFormatter.format(exp.score),
        exp.pruningStatus,
        exp.selected ? 'true' : 'false',
        exp.terminal ? 'true' : 'false',
        exp.traversalRank?.toString() ?? '-',
        exp.pruningReason ?? '-',
      ]);
    }
    buffer.write(CanonicalMarkdownWriter.table(headers, nodeRows));
    buffer.write('\n');

    // 7. Runtime Traces Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Runtime Traces'));
    if (report.runtimeTraceSummary.isEmpty) {
      buffer.write('No runtime traces recorded.\n');
    } else {
      for (final trace in report.runtimeTraceSummary) {
        buffer.write(CanonicalMarkdownWriter.bullet(trace));
      }
    }
    buffer.write('\n');

    // 8. Plugin Provenance Section
    buffer.write(CanonicalMarkdownWriter.heading(2, 'Plugin Provenance'));
    if (report.pluginProvenance.isEmpty) {
      buffer.write('No plugin modifications recorded.\n');
    } else {
      for (final prov in report.pluginProvenance) {
        final pluginId = prov['pluginId'];
        final nodeId = prov['nodeId'];
        buffer.write('* Plugin "$pluginId" modified node "$nodeId":\n');
        final modifiedFields = prov['modifiedFields'];
        if (modifiedFields is Map) {
          final sortedKeys =
              modifiedFields.keys.map((k) => k.toString()).toList()..sort();
          for (final key in sortedKeys) {
            final val = modifiedFields[key];
            final String valStr;
            if (val is double) {
              valStr = CanonicalFloatFormatter.format(val);
            } else {
              valStr = val.toString();
            }
            buffer.write('  - $key: $valStr\n');
          }
        }
      }
    }
    buffer.write('\n');

    return CanonicalMarkdownWriter.normalize(buffer.toString());
  }
}
