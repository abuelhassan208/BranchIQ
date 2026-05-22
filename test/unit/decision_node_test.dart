import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('DecisionNode Hardening Tests', () {
    test('Default constructor values and assertions', () {
      const node = DecisionNode.constant(id: 'node_1', childIds: []);
      expect(node.id, equals('node_1'));
      expect(node.parentId, isNull);
      expect(node.childIds, isEmpty);
      expect(node.probability, equals(1.0));
      expect(node.impact, equals(0.0));
      expect(node.cost, equals(0.0));
      expect(node.confidence, equals(1.0));
      expect(node.score, equals(0.0));
      expect(node.metadata, isEmpty);
      expect(node.tags, isEmpty);
      expect(node.depth, equals(0));
      expect(node.pruningReason, isNull);

      // Verify range validation via asserts
      expect(() => DecisionNode(id: '', childIds: const []),
          throwsA(isA<AssertionError>()));
      expect(() => DecisionNode(id: 'n', childIds: const [], probability: -0.1),
          throwsA(isA<AssertionError>()));
      expect(() => DecisionNode(id: 'n', childIds: const [], probability: 1.1),
          throwsA(isA<AssertionError>()));
      expect(() => DecisionNode(id: 'n', childIds: const [], impact: -1.1),
          throwsA(isA<AssertionError>()));
      expect(() => DecisionNode(id: 'n', childIds: const [], impact: 1.1),
          throwsA(isA<AssertionError>()));
      expect(() => DecisionNode(id: 'n', childIds: const [], cost: -0.1),
          throwsA(isA<AssertionError>()));
      expect(() => DecisionNode(id: 'n', childIds: const [], confidence: -0.1),
          throwsA(isA<AssertionError>()));
      expect(() => DecisionNode(id: 'n', childIds: const [], confidence: 1.1),
          throwsA(isA<AssertionError>()));
      expect(() => DecisionNode(id: 'n', childIds: const [], score: -1.1),
          throwsA(isA<AssertionError>()));
      expect(() => DecisionNode(id: 'n', childIds: const [], score: 1.1),
          throwsA(isA<AssertionError>()));
      expect(() => DecisionNode(id: 'n', childIds: const [], depth: -1),
          throwsA(isA<AssertionError>()));
    });

    test('Collection immutability', () {
      final childList = ['c1', 'c2'];
      final tagList = ['t1'];
      final Map<String, dynamic> metaMap = {'key': 'value'};

      final node = DecisionNode(
        id: 'node_1',
        childIds: childList,
        tags: tagList,
        metadata: metaMap,
      );

      // Mutating lists passed to constructor shouldn't affect the node if copied or unmodifiable
      childList.add('c3');
      tagList.add('t2');
      metaMap['another'] = 123;

      // Note: Generative const constructor doesn't copy collections itself,
      // but fromJson and copyWith wrap/copy them in unmodifiable collections.
      final copiedNode = node.copyWith();

      expect(copiedNode.childIds, containsAll(['c1', 'c2']));
      expect(copiedNode.childIds, isNot(contains('c3')));
      expect(() => copiedNode.childIds.add('c4'), throwsUnsupportedError);
      expect(() => copiedNode.tags.add('t3'), throwsUnsupportedError);
      expect(() => copiedNode.metadata['new'] = 1, throwsUnsupportedError);
    });

    test('copyWith handles fields correctly', () {
      const node = DecisionNode.constant(
        id: 'node_1',
        childIds: ['child_1'],
        probability: 0.5,
        impact: 0.5,
        cost: 10.0,
        confidence: 0.5,
        score: 0.5,
        depth: 1,
        tags: ['t1'],
        metadata: {'m1': 'v1'},
      );

      final updated = node.copyWith(
        probability: 0.8,
        impact: -0.8,
        cost: 20.0,
        confidence: 0.9,
        score: 0.9,
        depth: 2,
        childIds: ['child_2'],
        tags: ['t2'],
        metadata: {'m2': 'v2'},
        pruningReason: 'pruned_test',
      );

      expect(updated.id, equals('node_1'));
      expect(updated.probability, equals(0.8));
      expect(updated.impact, equals(-0.8));
      expect(updated.cost, equals(20.0));
      expect(updated.confidence, equals(0.9));
      expect(updated.score, equals(0.9));
      expect(updated.depth, equals(2));
      expect(updated.childIds, equals(['child_2']));
      expect(updated.tags, equals(['t2']));
      expect(updated.metadata, equals({'m2': 'v2'}));
      expect(updated.pruningReason, equals('pruned_test'));
    });

    test('JSON serialization / deserialization roundtrip', () {
      const original = DecisionNode.constant(
        id: 'node_1',
        parentId: 'parent_1',
        childIds: ['child_1', 'child_2'],
        probability: 0.95,
        impact: 0.85,
        cost: 125.5,
        confidence: 0.99,
        score: 0.77,
        metadata: {'os': 'ios', 'enabled': true},
        tags: ['critical', 'high_priority'],
        depth: 3,
        pruningReason: 'depth_limit',
      );

      final json = original.toJson();
      final reconstructed = DecisionNode.fromJson(json);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.parentId, equals(original.parentId));
      expect(reconstructed.childIds, equals(original.childIds));
      expect(reconstructed.probability, equals(original.probability));
      expect(reconstructed.impact, equals(original.impact));
      expect(reconstructed.cost, equals(original.cost));
      expect(reconstructed.confidence, equals(original.confidence));
      expect(reconstructed.score, equals(original.score));
      expect(reconstructed.metadata, equals(original.metadata));
      expect(reconstructed.tags, equals(original.tags));
      expect(reconstructed.depth, equals(original.depth));
      expect(reconstructed.pruningReason, equals(original.pruningReason));
    });

    test('fromJson validates inputs and applies clamping for double anomalies',
        () {
      final json = {
        'id': 'node_bad',
        'probability': 1.5, // clamps to 1.0
        'impact': -2.5, // clamps to -1.0
        'cost': -10.0, // clamps to 0.0
        'confidence': -0.5, // clamps to 0.0
        'depth': 2,
      };

      final node = DecisionNode.fromJson(json);
      expect(node.probability, equals(1.0));
      expect(node.impact, equals(-1.0));
      expect(node.cost, equals(0.0));
      expect(node.confidence, equals(0.0));
      expect(node.depth, equals(2));

      // Test empty id throws
      expect(() => DecisionNode.fromJson({'id': ''}), throwsArgumentError);
      // Test negative depth throws
      expect(() => DecisionNode.fromJson({'id': 'n', 'depth': -1}),
          throwsArgumentError);
    });
  });
}
