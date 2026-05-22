import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('TreeValidator Hardening Tests', () {
    test('Empty tree throws InvalidTreeException', () {
      expect(() => DecisionTree.fromNodes([]),
          throwsA(isA<InvalidTreeException>()));
    });

    test('Tree with no root throws InvalidTreeException', () {
      const node = DecisionNode.constant(
          id: 'node_1', parentId: 'parent_1', childIds: [], depth: 1);
      expect(() => DecisionTree.fromNodes([node]),
          throwsA(isA<InvalidTreeException>()));
    });

    test('Tree with multiple roots throws InvalidTreeException', () {
      const root1 = DecisionNode.constant(id: 'root_1', childIds: [], depth: 0);
      const root2 = DecisionNode.constant(id: 'root_2', childIds: [], depth: 0);
      expect(() => DecisionTree.fromNodes([root1, root2]),
          throwsA(isA<InvalidTreeException>()));
    });

    test('Tree with missing child reference throws OrphanNodeException', () {
      const root =
          DecisionNode.constant(id: 'root', childIds: ['child_1'], depth: 0);
      expect(() => DecisionTree.fromNodes([root]),
          throwsA(isA<OrphanNodeException>()));
    });

    test(
        'Tree with inconsistent parent-child references throws InvalidTreeException',
        () {
      const root =
          DecisionNode.constant(id: 'root', childIds: ['child_1'], depth: 0);
      const child = DecisionNode.constant(
          id: 'child_1', parentId: 'root_wrong', childIds: [], depth: 1);
      expect(() => DecisionTree.fromNodes([root, child]),
          throwsA(isA<InvalidTreeException>()));
    });

    test(
        'Tree with parent not listing child in childIds throws InvalidTreeException',
        () {
      const root = DecisionNode.constant(id: 'root', childIds: [], depth: 0);
      const child = DecisionNode.constant(
          id: 'child_1', parentId: 'root', childIds: [], depth: 1);
      expect(() => DecisionTree.fromNodes([root, child]),
          throwsA(isA<InvalidTreeException>()));
    });

    test('Tree depth limit exceeds 12 levels throws InvalidTreeException', () {
      final nodes = <DecisionNode>[];
      nodes.add(const DecisionNode.constant(
          id: 'node_0', childIds: ['node_1'], depth: 0));
      for (int i = 1; i <= 12; i++) {
        nodes.add(DecisionNode(
          id: 'node_$i',
          parentId: 'node_${i - 1}',
          childIds: [if (i < 12) 'node_${i + 1}'],
          depth: i,
        ));
      }

      // 12 depth is valid (node_12 has depth 12)
      expect(() => DecisionTree.fromNodes(nodes), returnsNormally);

      // Now add 13th depth node
      nodes.removeLast(); // remove node_12
      nodes.add(const DecisionNode.constant(
          id: 'node_12',
          parentId: 'node_11',
          childIds: ['node_13'],
          depth: 12));
      nodes.add(const DecisionNode.constant(
          id: 'node_13', parentId: 'node_12', childIds: [], depth: 13));

      expect(() => DecisionTree.fromNodes(nodes),
          throwsA(isA<InvalidTreeException>()));
    });

    test('Tree node depth field mismatch throws InvalidTreeException', () {
      const root =
          DecisionNode.constant(id: 'root', childIds: ['child_1'], depth: 0);
      const child = DecisionNode.constant(
          id: 'child_1',
          parentId: 'root',
          childIds: [],
          depth: 5); // Expected depth 1
      expect(() => DecisionTree.fromNodes([root, child]),
          throwsA(isA<InvalidTreeException>()));
    });

    test('Tree with self-referential cycle loop throws CycleDetectedException',
        () {
      const root =
          DecisionNode.constant(id: 'root', childIds: ['child_1'], depth: 0);
      const child = DecisionNode.constant(
          id: 'child_1', parentId: 'root', childIds: ['child_1'], depth: 1);
      expect(() => DecisionTree.fromNodes([root, child]),
          throwsA(isA<CycleDetectedException>()));
    });

    test('Tree with circular cycle loop throws CycleDetectedException', () {
      const root =
          DecisionNode.constant(id: 'root', childIds: ['child_1'], depth: 0);
      const child1 = DecisionNode.constant(
          id: 'child_1', parentId: 'root', childIds: ['child_2'], depth: 1);
      const child2 = DecisionNode.constant(
          id: 'child_2', parentId: 'child_1', childIds: ['root'], depth: 2);
      expect(() => DecisionTree.fromNodes([root, child1, child2]),
          throwsA(isA<CycleDetectedException>()));
    });

    test(
        'Tree with orphan nodes (unreachable from root) throws OrphanNodeException',
        () {
      const root = DecisionNode.constant(id: 'root', childIds: [], depth: 0);
      const orphan =
          DecisionNode.constant(id: 'orphan', childIds: [], depth: 0);
      expect(() => DecisionTree.fromNodes([root, orphan]),
          throwsA(isA<InvalidTreeException>()));

      const root3 = DecisionNode.constant(id: 'root', childIds: [], depth: 0);
      const o1 = DecisionNode.constant(
          id: 'o_1', parentId: 'o_2', childIds: ['o_2'], depth: 1);
      const o2 = DecisionNode.constant(
          id: 'o_2', parentId: 'o_1', childIds: ['o_1'], depth: 2);

      expect(() => DecisionTree.fromNodes([root3, o1, o2]),
          throwsA(isA<CycleDetectedException>()));
    });
  });
}
