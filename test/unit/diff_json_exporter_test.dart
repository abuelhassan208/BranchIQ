import 'package:test/test.dart';
import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/diff/diff_json_exporter.dart';

void main() {
  group('DiffJsonExporter Tests', () {
    test('serializes snapshot diff to stable single line canonical JSON', () {
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
        summary: 'Test summary',
      );

      final compactJson = DiffJsonExporter.exportCompact(diff);
      expect(compactJson, isNot(contains('\n')));
      expect(compactJson, contains('"utilityDelta":"0.0500"'));

      final prettyJson = DiffJsonExporter.exportPretty(diff);
      expect(prettyJson, contains('\n'));
      expect(prettyJson, contains('  "utilityDelta": "0.0500"'));
    });
  });
}
