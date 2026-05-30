import 'package:test/test.dart';
import 'package:branchiq/branchiq.dart';

void main() {
  group('SnapshotDiff Model Tests', () {
    test('enforces immutable lists and maps', () {
      final diff = SnapshotDiff(
        sourceSchemaVersion: '1.0',
        targetSchemaVersion: '1.0',
        sourceEngineVersion: '0.1.0',
        targetEngineVersion: '0.1.0',
        pathChanged: false,
        sourceSelectedPath: ['root'],
        targetSelectedPath: ['root'],
        sourceUtility: 1.0,
        targetUtility: 1.0,
        utilityDelta: 0.0,
        addedNodeIds: ['c'],
        removedNodeIds: ['b'],
        modifiedNodeIds: ['a'],
        newlyPrunedNodeIds: [],
        newlyUnprunedNodeIds: [],
        nodeMetricDiffs: {},
        traceDiff: TraceDiff.compare([], []),
        summary: 'No changes.',
      );

      expect(() => diff.sourceSelectedPath.add('err'), throwsUnsupportedError);
      expect(() => diff.targetSelectedPath.add('err'), throwsUnsupportedError);
      expect(() => diff.addedNodeIds.add('err'), throwsUnsupportedError);
      expect(() => diff.removedNodeIds.add('err'), throwsUnsupportedError);
      expect(() => diff.modifiedNodeIds.add('err'), throwsUnsupportedError);
      expect(
          () => diff.nodeMetricDiffs['err'] = NodeMetricDiff(
                nodeId: 'err',
                existsInSource: true,
                existsInTarget: true,
                changedFields: [],
                pruningStatusChanged: false,
              ),
          throwsUnsupportedError);
    });

    test('performs lexicographical sorting on constructor lists and maps', () {
      final diff = SnapshotDiff(
        sourceSchemaVersion: '1.0',
        targetSchemaVersion: '1.0',
        sourceEngineVersion: '0.1.0',
        targetEngineVersion: '0.1.0',
        pathChanged: false,
        sourceSelectedPath: ['root'],
        targetSelectedPath: ['root'],
        sourceUtility: 1.0,
        targetUtility: 1.0,
        utilityDelta: 0.0,
        addedNodeIds: ['c', 'a', 'b'],
        removedNodeIds: ['z', 'x', 'y'],
        modifiedNodeIds: ['node2', 'node1'],
        newlyPrunedNodeIds: ['p2', 'p1'],
        newlyUnprunedNodeIds: ['u2', 'u1'],
        nodeMetricDiffs: {
          'c': NodeMetricDiff(
              nodeId: 'c',
              existsInSource: true,
              existsInTarget: true,
              changedFields: [],
              pruningStatusChanged: false),
          'a': NodeMetricDiff(
              nodeId: 'a',
              existsInSource: true,
              existsInTarget: true,
              changedFields: [],
              pruningStatusChanged: false),
          'b': NodeMetricDiff(
              nodeId: 'b',
              existsInSource: true,
              existsInTarget: true,
              changedFields: [],
              pruningStatusChanged: false),
        },
        traceDiff: TraceDiff.compare([], []),
        summary: 'Sorting check.',
      );

      expect(diff.addedNodeIds, equals(['a', 'b', 'c']));
      expect(diff.removedNodeIds, equals(['x', 'y', 'z']));
      expect(diff.modifiedNodeIds, equals(['node1', 'node2']));
      expect(diff.newlyPrunedNodeIds, equals(['p1', 'p2']));
      expect(diff.newlyUnprunedNodeIds, equals(['u1', 'u2']));
      expect(diff.nodeMetricDiffs.keys.toList(), equals(['a', 'b', 'c']));
    });
  });
}
