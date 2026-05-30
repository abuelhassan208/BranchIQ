import 'package:test/test.dart';
import 'package:branchiq/branchiq.dart';

void main() {
  group('Snapshot Diffing Regression and Determinism Tests', () {
    late DebugSnapshot source;
    late DebugSnapshot target;

    setUpAll(() {
      source = const DebugSnapshot(
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
            'pruningReason': null,
          },
          'reject': {
            'id': 'reject',
            'score': 0.1,
            'probability': 0.2,
            'cost': 5.0,
            'depth': 1,
            'pruningReason': 'probabilityBelowThreshold',
          },
        },
        prunedNodeIds: ['reject'],
        pruningTraces: ['Pruned reject due to low probability.'],
        metadata: {'test': 'regression'},
        runtimeTraces: ['Start root', 'Traversing approve'],
      );

      target = const DebugSnapshot(
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
            'score': 0.75,
            'probability': 0.85,
            'cost': 3.0,
            'depth': 1,
            'pruningReason': null,
          },
          'approve': {
            'id': 'approve',
            'score': 0.70, // score dropped, causing path shift
            'probability': 0.9,
            'cost': 10.0,
            'depth': 1,
            'pruningReason': null,
          },
          'reject': {
            'id': 'reject',
            'score': 0.1,
            'probability': 0.2,
            'cost': 5.0,
            'depth': 1,
            'pruningReason': 'probabilityBelowThreshold',
          },
        },
        prunedNodeIds: ['reject'],
        pruningTraces: ['Pruned reject due to low probability.'],
        metadata: {'test': 'regression'},
        runtimeTraces: ['Start root', 'Traversing defer'],
      );
    });

    test('generate identical snapshot diff 350+ times and assert byte-identity',
        () {
      String? firstCanonicalJson;
      String? firstMarkdown;

      for (int i = 0; i < 350; i++) {
        final diff =
            SnapshotDiffer.compareSnapshots(source: source, target: target);

        final canonicalJson = diff.toCanonicalJson();
        final markdown = diff.toMarkdown();

        if (i == 0) {
          firstCanonicalJson = canonicalJson;
          firstMarkdown = markdown;

          // Asserts on structure
          expect(diff.pathChanged, isTrue);
          expect(
              diff.utilityDelta, closeTo(-0.05, 0.0001)); // 0.75 - 0.80 = -0.05
          expect(diff.addedNodeIds, equals(['defer']));
          expect(diff.removedNodeIds,
              isEmpty); // approve is not removed, it's modified and not selected
          expect(diff.modifiedNodeIds, equals(['approve']));
          expect(diff.newlyPrunedNodeIds, isEmpty);
          expect(diff.newlyUnprunedNodeIds, isEmpty);
        } else {
          // Assert byte-identical outputs on all subsequent iterations
          expect(canonicalJson, equals(firstCanonicalJson));
          expect(markdown, equals(firstMarkdown));
        }
      }
    });

    test(
        'asserts stable trace ordering and lexicographical node ordering remains deterministic',
        () {
      final diff =
          SnapshotDiffer.compareSnapshots(source: source, target: target);

      // Verify lexicographical key order on nodeMetricDiffs
      final nodeKeys = diff.nodeMetricDiffs.keys.toList();
      final sortedNodeKeys = List<String>.from(nodeKeys)..sort();
      expect(nodeKeys, equals(sortedNodeKeys));

      // Verify trace diff lists relative chronology
      expect(diff.traceDiff.sourceOnlyTraces, equals(['Traversing approve']));
      expect(diff.traceDiff.targetOnlyTraces, equals(['Traversing defer']));
      expect(diff.traceDiff.sharedTraces, equals(['Start root']));
    });
  });
}
