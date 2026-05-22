import 'dart:convert';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('DebugSnapshot Tests', () {
    test('should construct and hold all required diagnostic attributes', () {
      const snapshot = DebugSnapshot(
        engineVersion: '0.1.0',
        rootId: 'root',
        selectedPath: ['root', 'child_1'],
        nodeSnapshots: {
          'root': {'score': 0.8, 'depth': 0},
          'child_1': {'score': 0.95, 'depth': 1},
        },
        pruningTraces: ['pruned child_2'],
        metadata: {'user_id': '1234'},
        runtimeTraces: ['Validation started', 'Traversal completed'],
        prunedNodeIds: ['child_2'],
        scoringSummaries: {'weight': 0.5},
        traversalSummaries: {'depth': 1},
      );

      expect(snapshot.engineVersion, equals('0.1.0'));
      expect(snapshot.rootId, equals('root'));
      expect(snapshot.selectedPath, equals(['root', 'child_1']));
      expect(snapshot.nodeSnapshots['root']?['score'], equals(0.8));
      expect(snapshot.pruningTraces, equals(['pruned child_2']));
      expect(snapshot.metadata, equals({'user_id': '1234'}));
      expect(snapshot.runtimeTraces,
          equals(['Validation started', 'Traversal completed']));
      expect(snapshot.prunedNodeIds, equals(['child_2']));
      expect(snapshot.scoringSummaries, equals({'weight': 0.5}));
      expect(snapshot.traversalSummaries, equals({'depth': 1}));
    });

    test(
        'should produce stable lexicographically sorted keys in JSON serialization',
        () {
      const snapshot = DebugSnapshot(
        engineVersion: '0.1.0',
        rootId: 'root',
        selectedPath: ['root'],
        nodeSnapshots: {
          'z_node': {'score': 0.1},
          'a_node': {'score': 0.9},
        },
        pruningTraces: [],
        metadata: {
          'meta_c': 3,
          'meta_a': 1,
          'meta_b': 2,
        },
        runtimeTraces: [],
        prunedNodeIds: [],
        scoringSummaries: {
          'wc': 0.2,
          'wp': 0.5,
          'wi': 0.3,
        },
        traversalSummaries: {
          'strategy': 'priority',
          'maxDepth': 12,
        },
      );

      final jsonMap = snapshot.toJson();

      // Check nodeSnapshots key order
      final nodeKeys = (jsonMap['nodeSnapshots'] as Map).keys.toList();
      expect(nodeKeys, equals(['a_node', 'z_node']));

      // Check metadata key order
      final metadataKeys = (jsonMap['metadata'] as Map).keys.toList();
      expect(metadataKeys, equals(['meta_a', 'meta_b', 'meta_c']));

      // Check scoringSummaries key order
      final scoringKeys = (jsonMap['scoringSummaries'] as Map).keys.toList();
      expect(scoringKeys, equals(['wc', 'wi', 'wp']));

      // Check traversalSummaries key order
      final traversalKeys =
          (jsonMap['traversalSummaries'] as Map).keys.toList();
      expect(traversalKeys, equals(['maxDepth', 'strategy']));
    });

    test('should perform stable roundtrip serialization', () {
      const snapshot = DebugSnapshot(
        engineVersion: '0.1.0',
        rootId: 'root',
        selectedPath: ['root', 'n1'],
        nodeSnapshots: {
          'root': {'score': 1.0},
          'n1': {'score': 0.9},
        },
        pruningTraces: ['pruned n2'],
        metadata: {'foo': 'bar'},
        runtimeTraces: ['trace1'],
        prunedNodeIds: ['n2'],
        scoringSummaries: {'ceiling': 100.0},
        traversalSummaries: {'utility': 0.9},
      );

      final jsonStr1 = json.encode(snapshot.toJson());
      final reconstructed =
          DebugSnapshot.fromJson(json.decode(jsonStr1) as Map<String, dynamic>);
      final jsonStr2 = json.encode(reconstructed.toJson());

      expect(jsonStr1, equals(jsonStr2));
      expect(reconstructed.rootId, equals('root'));
      expect(reconstructed.selectedPath, equals(['root', 'n1']));
      expect(reconstructed.nodeSnapshots['n1']?['score'], equals(0.9));
      expect(reconstructed.prunedNodeIds, equals(['n2']));
    });
  });
}
