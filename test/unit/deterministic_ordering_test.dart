import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/math/deterministic_ordering.dart';
import 'package:test/test.dart';

void main() {
  group('Deterministic Ordering Tests', () {
    test('compareScoresDescending should sort scores descending', () {
      const nodeHigh = DecisionNode.constant(id: 'a', childIds: [], score: 0.8);
      const nodeLow = DecisionNode.constant(id: 'b', childIds: [], score: 0.3);
      const nodeEqual =
          DecisionNode.constant(id: 'c', childIds: [], score: 0.8);

      expect(compareScoresDescending(nodeHigh, nodeLow), lessThan(0));
      expect(compareScoresDescending(nodeLow, nodeHigh), greaterThan(0));
      expect(compareScoresDescending(nodeHigh, nodeEqual), equals(0));
    });

    test('compareNodeIds should perform lexicographical string comparison', () {
      const nodeA = DecisionNode.constant(id: 'abc', childIds: []);
      const nodeB = DecisionNode.constant(id: 'def', childIds: []);
      const nodeA2 = DecisionNode.constant(id: 'abc', childIds: []);

      expect(compareNodeIds(nodeA, nodeB), lessThan(0));
      expect(compareNodeIds(nodeB, nodeA), greaterThan(0));
      expect(compareNodeIds(nodeA, nodeA2), equals(0));
    });

    test('compareNodes should prioritize scores and tie-break by ID', () {
      // Score priority
      const nodeHighIdZ =
          DecisionNode.constant(id: 'z', childIds: [], score: 0.9);
      const nodeLowIdA =
          DecisionNode.constant(id: 'a', childIds: [], score: 0.1);
      expect(compareNodes(nodeHighIdZ, nodeLowIdA), lessThan(0));
      expect(compareNodes(nodeLowIdA, nodeHighIdZ), greaterThan(0));

      // Tie breaker by ID (ascending alphabetical)
      const nodeEqual1 =
          DecisionNode.constant(id: 'a', childIds: [], score: 0.5);
      const nodeEqual2 =
          DecisionNode.constant(id: 'b', childIds: [], score: 0.5);
      expect(compareNodes(nodeEqual1, nodeEqual2), lessThan(0));
      expect(compareNodes(nodeEqual2, nodeEqual1), greaterThan(0));
      expect(compareNodes(nodeEqual1, nodeEqual1), equals(0));
    });

    test('stableNodeSort should order a list deterministically', () {
      const n1 = DecisionNode.constant(id: 'node_b', childIds: [], score: 0.5);
      const n2 = DecisionNode.constant(id: 'node_c', childIds: [], score: 0.8);
      const n3 = DecisionNode.constant(id: 'node_a', childIds: [], score: 0.5);
      const n4 = DecisionNode.constant(id: 'node_d', childIds: [], score: -0.1);

      final list = <DecisionNode>[n1, n2, n3, n4];
      stableNodeSort(list);

      // Expected order:
      // 1. n2 (score: 0.8)
      // 2. n3 (score: 0.5, id: node_a)
      // 3. n1 (score: 0.5, id: node_b)
      // 4. n4 (score: -0.1)
      expect(list[0].id, equals('node_c'));
      expect(list[1].id, equals('node_a'));
      expect(list[2].id, equals('node_b'));
      expect(list[3].id, equals('node_d'));
    });
  });
}
