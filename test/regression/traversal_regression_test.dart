import 'dart:convert';
import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/traversal/traversal_pipeline.dart';
import 'package:test/test.dart';

void main() {
  group('Traversal Core Regression and Determinism Replay Tests', () {
    test(
        '150+ repeated runs should produce identical path selection, utility, and JSON output',
        () {
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
        childIds: ['C', 'D'],
        score: 0.7,
        depth: 1,
      );
      final nodeB = const DecisionNode.constant(
        id: 'B',
        parentId: 'root',
        childIds: [],
        score: 0.8,
        depth: 1,
      );
      final nodeC = const DecisionNode.constant(
        id: 'C',
        parentId: 'A',
        childIds: [],
        score: 0.4,
        depth: 2,
      );
      final nodeD = const DecisionNode.constant(
        id: 'D',
        parentId: 'A',
        childIds: [],
        score: 0.9,
        depth: 2,
      );

      final tree = DecisionTree.fromNodes([root, nodeA, nodeB, nodeC, nodeD]);
      final traversalConfig =
          const TraversalConfig(strategy: TraversalStrategy.priorityFirst);
      final pruningConfig = PruningConfig(
        minProbability: 0.0,
        minScore: -1.0,
        beamWidth: 5,
        maxDepth: 10,
        maxNodeLimit: 100,
      );

      // Perform the first traversal
      final firstResult = runTraversal(tree, traversalConfig, pruningConfig);
      final firstJson = jsonEncode(firstResult.toJson());

      // Loop 150 times and assert complete identity
      for (int i = 0; i < 150; i++) {
        final result = runTraversal(tree, traversalConfig, pruningConfig);
        final resultJson = jsonEncode(result.toJson());

        expect(result.selectedNodeIds, equals(firstResult.selectedNodeIds));
        expect(result.totalUtility, equals(firstResult.totalUtility));
        expect(result.terminalNodeId, equals(firstResult.terminalNodeId));
        expect(result.wasFallback, equals(firstResult.wasFallback));
        expect(resultJson, equals(firstJson));
      }
    });
  });
}
