import 'package:test/test.dart';
import 'package:branchiq/branchiq.dart';

void main() {
  group('SnapshotDiffer Tests', () {
    late DebugSnapshot snapA;
    late DebugSnapshot snapB;

    setUp(() {
      snapA = const DebugSnapshot(
        engineVersion: '0.2.0',
        rootId: 'root',
        selectedPath: ['root', 'approve'],
        nodeSnapshots: {
          'root': {
            'id': 'root',
            'score': 1.0,
            'probability': 1.0,
            'cost': 0.0,
            'depth': 0,
          },
          'approve': {
            'id': 'approve',
            'score': 0.8,
            'probability': 0.9,
            'cost': 10.0,
            'depth': 1,
          },
        },
        prunedNodeIds: [],
        pruningTraces: [],
        metadata: {},
        runtimeTraces: ['Evaluating root', 'Traversing approve'],
      );

      snapB = const DebugSnapshot(
        engineVersion: '0.2.0',
        rootId: 'root',
        selectedPath: ['root', 'defer'],
        nodeSnapshots: {
          'root': {
            'id': 'root',
            'score': 1.0,
            'probability': 1.0,
            'cost': 0.0,
            'depth': 0,
          },
          'defer': {
            'id': 'defer',
            'score': 0.7,
            'probability': 0.85,
            'cost': 5.0,
            'depth': 1,
          },
        },
        prunedNodeIds: [],
        pruningTraces: [],
        metadata: {},
        runtimeTraces: ['Evaluating root', 'Traversing defer'],
      );
    });

    test('compares identical snapshots with zero changes', () {
      final diff =
          SnapshotDiffer.compareSnapshots(source: snapA, target: snapA);

      expect(diff.pathChanged, isFalse);
      expect(diff.utilityDelta, equals(0.0));
      expect(diff.addedNodeIds, isEmpty);
      expect(diff.removedNodeIds, isEmpty);
      expect(diff.modifiedNodeIds, isEmpty);
      expect(diff.newlyPrunedNodeIds, isEmpty);
      expect(diff.newlyUnprunedNodeIds, isEmpty);
      expect(diff.traceDiff.sourceOnlyTraces, isEmpty);
      expect(diff.traceDiff.targetOnlyTraces, isEmpty);
    });

    test('compares snapshots with changed paths and utility deltas', () {
      final diff =
          SnapshotDiffer.compareSnapshots(source: snapA, target: snapB);

      expect(diff.pathChanged, isTrue);
      // approve (0.8) -> defer (0.7), utilityDelta = target (0.7) - source (0.8) = -0.1
      expect(diff.utilityDelta, closeTo(-0.1, 0.0001));
      expect(diff.addedNodeIds, equals(['defer']));
      expect(diff.removedNodeIds, equals(['approve']));
      expect(diff.modifiedNodeIds, isEmpty);
    });

    test('compares modified node scores and trace changes', () {
      final snapC = const DebugSnapshot(
        engineVersion: '0.2.0',
        rootId: 'root',
        selectedPath: ['root', 'approve'],
        nodeSnapshots: {
          'root': {
            'id': 'root',
            'score': 1.0,
            'probability': 1.0,
            'cost': 0.0,
            'depth': 0,
          },
          'approve': {
            'id': 'approve',
            'score': 0.95, // modified from 0.8
            'probability': 0.9,
            'cost': 10.0,
            'depth': 1,
          },
        },
        prunedNodeIds: [],
        pruningTraces: [],
        metadata: {},
        runtimeTraces: ['Evaluating root', 'Traversing approve', 'Trace extra'],
      );

      final diff =
          SnapshotDiffer.compareSnapshots(source: snapA, target: snapC);

      expect(diff.pathChanged, isFalse);
      expect(diff.utilityDelta, closeTo(0.15, 0.0001));
      expect(diff.modifiedNodeIds, equals(['approve']));
      expect(
          diff.nodeMetricDiffs['approve']?.scoreDelta, closeTo(0.15, 0.0001));
      expect(diff.traceDiff.targetOnlyTraces, equals(['Trace extra']));
    });

    test('compares canonical JSON strings correctly', () {
      // Convert to canonical first
      final sessionA = ReplayLoader.loadJson(snapA.toJson());
      final sessionB = ReplayLoader.loadJson(snapB.toJson());
      final canonicalA = sessionA.toCanonicalJson();
      final canonicalB = sessionB.toCanonicalJson();

      final diff = SnapshotDiffer.compareCanonicalJson(
        sourceJson: canonicalA,
        targetJson: canonicalB,
      );

      expect(diff.pathChanged, isTrue);
      expect(diff.addedNodeIds, equals(['defer']));
      expect(diff.removedNodeIds, equals(['approve']));
    });
  });
}
