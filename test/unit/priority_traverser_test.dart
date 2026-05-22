import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/traversal/priority_traverser.dart';
import 'package:test/test.dart';

void main() {
  group('PriorityTraverser Tests', () {
    final traversalConfig =
        const TraversalConfig(strategy: TraversalStrategy.priorityFirst);
    final pruningConfig = PruningConfig(
      minProbability: 0.0,
      minScore: -1.0,
      beamWidth: 5,
      maxDepth: 10,
      maxNodeLimit: 100,
    );

    test('Root-only tree traversal', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: [],
        score: 0.8,
        depth: 0,
      );
      final tree = DecisionTree.fromNodes([root]);

      final result =
          PriorityTraverser.traverse(tree, traversalConfig, pruningConfig);
      expect(result.wasFallback, isFalse);
      expect(result.selectedNodeIds, equals(['root']));
      expect(result.terminalNodeId, equals('root'));
      expect(result.totalUtility, equals(0.8));
    });

    test('Simple best child selection', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1', 'c2'],
        score: 0.5,
        depth: 0,
      );
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: [],
        score: 0.9,
        depth: 1,
      );
      final c2 = const DecisionNode.constant(
        id: 'c2',
        parentId: 'root',
        childIds: [],
        score: 0.3,
        depth: 1,
      );
      final tree = DecisionTree.fromNodes([root, c1, c2]);

      final result =
          PriorityTraverser.traverse(tree, traversalConfig, pruningConfig);
      expect(result.selectedNodeIds, equals(['root', 'c1']));
      expect(result.totalUtility, equals(1.4)); // 0.5 + 0.9
    });

    test('Deeper path selection with higher accumulated utility', () {
      // Path A: root -> A (score 0.7) -> terminal (accumulated 0.5 + 0.7 = 1.2)
      // Path B: root -> B (score 0.3) -> C (score 0.8) -> terminal (accumulated 0.5 + 0.3 + 0.8 = 1.6)
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['A', 'B'],
        score: 0.5,
        depth: 0,
      );
      final nodeA = const DecisionNode.constant(
        id: 'A',
        parentId: 'root',
        childIds: [],
        score: 0.7,
        depth: 1,
      );
      final nodeB = const DecisionNode.constant(
        id: 'B',
        parentId: 'root',
        childIds: ['C'],
        score: 0.3,
        depth: 1,
      );
      final nodeC = const DecisionNode.constant(
        id: 'C',
        parentId: 'B',
        childIds: [],
        score: 0.8,
        depth: 2,
      );
      final tree = DecisionTree.fromNodes([root, nodeA, nodeB, nodeC]);

      final result =
          PriorityTraverser.traverse(tree, traversalConfig, pruningConfig);
      expect(result.selectedNodeIds, equals(['root', 'B', 'C']));
      expect(result.totalUtility, equals(1.6));
    });

    test('Tie-breaking by node ID lexicographically ascending', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c_b', 'c_a', 'c_c'],
        score: 0.5,
        depth: 0,
      );
      final cb = const DecisionNode.constant(
        id: 'c_b',
        parentId: 'root',
        childIds: [],
        score: 0.7,
        depth: 1,
      );
      final ca = const DecisionNode.constant(
        id: 'c_a',
        parentId: 'root',
        childIds: [],
        score: 0.7,
        depth: 1,
      );
      final cc = const DecisionNode.constant(
        id: 'c_c',
        parentId: 'root',
        childIds: [],
        score: 0.7,
        depth: 1,
      );
      final tree = DecisionTree.fromNodes([root, cb, ca, cc]);

      final result =
          PriorityTraverser.traverse(tree, traversalConfig, pruningConfig);
      expect(result.selectedNodeIds, equals(['root', 'c_a']));
    });

    test('Ignores pruned nodes', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1', 'c2'],
        score: 0.5,
        depth: 0,
      );
      // c1 has high score but is pruned
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: [],
        score: 0.9,
        depth: 1,
        pruningReason: 'probabilityTooLow',
      );
      // c2 has lower score but is not pruned
      final c2 = const DecisionNode.constant(
        id: 'c2',
        parentId: 'root',
        childIds: [],
        score: 0.3,
        depth: 1,
      );
      final tree = DecisionTree.fromNodes([root, c1, c2]);

      final result =
          PriorityTraverser.traverse(tree, traversalConfig, pruningConfig);
      expect(result.selectedNodeIds, equals(['root', 'c2']));
    });

    test('Handles negative score nodes correctly', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1', 'c2'],
        score: 0.5,
        depth: 0,
      );
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: [],
        score: -0.2,
        depth: 1,
      );
      final c2 = const DecisionNode.constant(
        id: 'c2',
        parentId: 'root',
        childIds: [],
        score: -0.8,
        depth: 1,
      );
      final tree = DecisionTree.fromNodes([root, c1, c2]);

      final result =
          PriorityTraverser.traverse(tree, traversalConfig, pruningConfig);
      expect(result.selectedNodeIds, equals(['root', 'c1']));
      expect(result.totalUtility, equals(0.3)); // 0.5 - 0.2
    });

    test('All children of root are pruned fallback to root-only path', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1'],
        score: 0.5,
        depth: 0,
      );
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: [],
        score: 0.9,
        depth: 1,
        pruningReason: 'scoreTooLow',
      );
      final tree = DecisionTree.fromNodes([root, c1]);

      final result =
          PriorityTraverser.traverse(tree, traversalConfig, pruningConfig);
      expect(result.selectedNodeIds, equals(['root']));
      expect(result.wasFallback, isTrue);
    });

    test('Max depth limits traversal expansion', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1'],
        score: 0.5,
        depth: 0,
      );
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: ['c2'],
        score: 0.5,
        depth: 1,
      );
      final c2 = const DecisionNode.constant(
        id: 'c2',
        parentId: 'c1',
        childIds: [],
        score: 0.5,
        depth: 2,
      );
      final tree = DecisionTree.fromNodes([root, c1, c2]);

      final customPruningConfig = PruningConfig(
        minProbability: 0.0,
        minScore: -1.0,
        beamWidth: 5,
        maxDepth: 1, // Only allow depth <= 1 (root and c1)
        maxNodeLimit: 100,
      );

      final result = PriorityTraverser.traverse(
          tree, traversalConfig, customPruningConfig);
      expect(result.selectedNodeIds, equals(['root', 'c1']));
    });

    test('Max node limit limits traversal frontier inspection', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1', 'c2'],
        score: 0.5,
        depth: 0,
      );
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: [],
        score: 0.5,
        depth: 1,
      );
      final c2 = const DecisionNode.constant(
        id: 'c2',
        parentId: 'root',
        childIds: [],
        score: 0.4,
        depth: 1,
      );
      final tree = DecisionTree.fromNodes([root, c1, c2]);

      final customPruningConfig = PruningConfig(
        minProbability: 0.0,
        minScore: -1.0,
        beamWidth: 5,
        maxDepth: 10,
        maxNodeLimit: 1, // Stop after inspecting the root node
      );

      final result = PriorityTraverser.traverse(
          tree, traversalConfig, customPruningConfig);
      // Should stop and only have the root path since root is the only node inspected
      expect(result.selectedNodeIds, equals(['root']));
    });

    test('Repeated traversal produces identical results', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1', 'c2'],
        score: 0.5,
        depth: 0,
      );
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: [],
        score: 0.9,
        depth: 1,
      );
      final c2 = const DecisionNode.constant(
        id: 'c2',
        parentId: 'root',
        childIds: [],
        score: 0.8,
        depth: 1,
      );
      final tree = DecisionTree.fromNodes([root, c1, c2]);

      final result1 =
          PriorityTraverser.traverse(tree, traversalConfig, pruningConfig);
      for (int i = 0; i < 20; i++) {
        final resultN =
            PriorityTraverser.traverse(tree, traversalConfig, pruningConfig);
        expect(resultN.selectedNodeIds, equals(result1.selectedNodeIds));
        expect(resultN.totalUtility, equals(result1.totalUtility));
      }
    });
  });
}
