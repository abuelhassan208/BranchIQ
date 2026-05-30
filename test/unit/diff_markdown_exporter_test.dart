import 'package:test/test.dart';
import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/diff/diff_markdown_exporter.dart';

void main() {
  group('DiffMarkdownExporter Tests', () {
    test('formats snapshot diff correctly with all required headers', () {
      final diff = SnapshotDiff(
        sourceSchemaVersion: '1.0',
        targetSchemaVersion: '2.0',
        sourceEngineVersion: '0.1.0',
        targetEngineVersion: '0.2.0',
        pathChanged: true,
        sourceSelectedPath: ['root', 'approve'],
        targetSelectedPath: ['root', 'defer'],
        sourceUtility: 0.85,
        targetUtility: 0.9,
        utilityDelta: 0.05,
        addedNodeIds: ['defer'],
        removedNodeIds: ['approve'],
        modifiedNodeIds: ['root'],
        newlyPrunedNodeIds: [],
        newlyUnprunedNodeIds: [],
        nodeMetricDiffs: {
          'root': NodeMetricDiff(
            nodeId: 'root',
            existsInSource: true,
            existsInTarget: true,
            changedFields: ['score'],
            scoreDelta: 0.05,
            pruningStatusChanged: false,
          ),
        },
        traceDiff: TraceDiff.compare(['Evaluating root'], ['Evaluating root']),
        summary: 'Selected pathway changed.',
      );

      final markdown = DiffMarkdownExporter.export(diff);

      // Verify all required markdown section headers
      expect(markdown, contains('# BranchIQ Snapshot Diff'));
      expect(markdown, contains('## Summary'));
      expect(markdown, contains('## Selected Path Changes'));
      expect(markdown, contains('## Utility Changes'));
      expect(markdown, contains('## Node Metric Changes'));
      expect(markdown, contains('## Pruning Changes'));
      expect(markdown, contains('## Trace Changes'));

      // Check values and tables
      expect(markdown, contains('Source Engine: 0.1.0'));
      expect(markdown, contains('Target Engine: 0.2.0'));
      expect(markdown, contains('root → approve'));
      expect(markdown, contains('root → defer'));
      expect(markdown, contains('0.8500'));
      expect(markdown, contains('0.9000'));
      expect(markdown, contains('0.0500'));
    });
  });
}
