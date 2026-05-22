import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('DecisionTree Hardening Tests', () {
    test('Constructing a valid tree', () {
      const root = DecisionNode.constant(
          id: 'root', childIds: ['child_1', 'child_2'], depth: 0);
      const child1 = DecisionNode.constant(
          id: 'child_1', parentId: 'root', childIds: [], depth: 1);
      const child2 = DecisionNode.constant(
          id: 'child_2', parentId: 'root', childIds: [], depth: 1);

      final tree = DecisionTree.fromNodes([child1, root, child2]);

      expect(tree.root.id, equals('root'));
      expect(tree.containsNode('child_1'), isTrue);
      expect(tree.containsNode('non_existent'), isFalse);
      expect(tree.getNode('child_2')?.id, equals('child_2'));
      expect(tree.childrenOf('root').map((n) => n.id),
          containsAllInOrder(['child_1', 'child_2']));
      expect(tree.isValid(), isTrue);
    });

    test('Constructing tree with structural errors throws exceptions', () {
      // No root
      const orphan = DecisionNode.constant(
          id: 'orphan', parentId: 'parent', childIds: [], depth: 1);
      expect(() => DecisionTree.fromNodes([orphan]),
          throwsA(isA<InvalidTreeException>()));

      // Missing child reference
      const root =
          DecisionNode.constant(id: 'root', childIds: ['child_1'], depth: 0);
      expect(() => DecisionTree.fromNodes([root]),
          throwsA(isA<OrphanNodeException>()));

      // Inconsistent parentId
      const rootNode =
          DecisionNode.constant(id: 'root', childIds: ['child_a'], depth: 0);
      const childA = DecisionNode.constant(
          id: 'child_a', parentId: 'wrong_parent', childIds: [], depth: 1);
      expect(() => DecisionTree.fromNodes([rootNode, childA]),
          throwsA(isA<InvalidTreeException>()));
    });

    test('Stable, deterministic JSON serialization order', () {
      const root = DecisionNode.constant(
          id: 'root', childIds: ['node_c', 'node_b'], depth: 0);
      const nodeB = DecisionNode.constant(
          id: 'node_b', parentId: 'root', childIds: [], depth: 1);
      const nodeC = DecisionNode.constant(
          id: 'node_c', parentId: 'root', childIds: [], depth: 1);

      // Construct with nodes in various unordered lists
      final tree1 = DecisionTree.fromNodes([root, nodeB, nodeC]);
      final tree2 = DecisionTree.fromNodes([nodeC, nodeB, root]);

      final json1 = tree1.toJson();
      final json2 = tree2.toJson();

      // Ensure that node order in JSON is strictly lexicographically sorted by ID (node_b, node_c, root)
      expect(json1, equals(json2));
      final nodesList = json1['nodes'] as List<dynamic>;
      expect((nodesList[0] as Map<String, dynamic>)['id'], equals('node_b'));
      expect((nodesList[1] as Map<String, dynamic>)['id'], equals('node_c'));
      expect((nodesList[2] as Map<String, dynamic>)['id'], equals('root'));
    });

    test('JSON Roundtrip parsing', () {
      const root =
          DecisionNode.constant(id: 'root', childIds: ['child_1'], depth: 0);
      const child1 = DecisionNode.constant(
          id: 'child_1', parentId: 'root', childIds: [], depth: 1);
      final originalTree = DecisionTree.fromNodes([root, child1]);

      final json = originalTree.toJson();
      final reconstructed = DecisionTree.fromJson(json);

      expect(reconstructed.root.id, equals('root'));
      expect(reconstructed.containsNode('child_1'), isTrue);
      expect(reconstructed.isValid(), isTrue);
    });
  });
}
