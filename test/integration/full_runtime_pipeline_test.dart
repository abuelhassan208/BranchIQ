import 'dart:convert';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('Full Runtime Pipeline Integration Tests', () {
    // Define a 3-level tree layout:
    // root -> branch_a -> branch_a_1
    //                  -> branch_a_2
    //      -> branch_b -> branch_b_1
    //                  -> branch_b_2
    final treeNodes = [
      const DecisionNode.constant(
        id: 'root',
        childIds: ['branch_a', 'branch_b'],
        depth: 0,
      ),
      const DecisionNode.constant(
        id: 'branch_a',
        parentId: 'root',
        childIds: ['branch_a_1', 'branch_a_2'],
        depth: 1,
        probability: 0.8,
        impact: 0.6,
        cost: 50.0,
      ),
      const DecisionNode.constant(
        id: 'branch_a_1',
        parentId: 'branch_a',
        childIds: [],
        depth: 2,
        probability: 0.95,
        impact: 0.8,
        cost: 20.0,
      ),
      const DecisionNode.constant(
        id: 'branch_a_2',
        parentId: 'branch_a',
        childIds: [],
        depth: 2,
        probability: 0.9,
        impact: 0.5,
        cost: 10.0,
      ),
      const DecisionNode.constant(
        id: 'branch_b',
        parentId: 'root',
        childIds: ['branch_b_1', 'branch_b_2'],
        depth: 1,
        probability: 0.9,
        impact: 0.7,
        cost: 100.0,
      ),
      const DecisionNode.constant(
        id: 'branch_b_1',
        parentId: 'branch_b',
        childIds: [],
        depth: 2,
        probability: 0.85,
        impact: 0.9,
        cost: 40.0,
      ),
      const DecisionNode.constant(
        id: 'branch_b_2',
        parentId: 'branch_b',
        childIds: [],
        depth: 2,
        probability: 0.4,
        impact: 0.3,
        cost: 15.0,
      ),
    ];

    test(
        'should evaluate the complex decision tree end-to-end and produce stable outputs',
        () {
      final tree = DecisionTree.fromNodes(treeNodes);
      final scoringConfig = ScoringConfig.balanced();
      final pruningConfig = PruningConfig(
        minProbability: 0.05,
        minScore: -1.0,
        beamWidth: 5,
        maxDepth: 12,
        maxNodeLimit: 150,
      );
      final traversalConfig = const TraversalConfig(
        strategy: TraversalStrategy.priorityFirst,
      );

      final engine = BranchIQEngine.createSync();

      // Store the original JSON representation of the tree to assert no mutation occurs
      final originalTreeJson = json.encode(tree.toJson());

      // Perform evaluation
      final result1 = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        enableDebug: true,
      );

      // Verify original tree has NOT been mutated
      final treeJsonAfterEval = json.encode(tree.toJson());
      expect(treeJsonAfterEval, equals(originalTreeJson));

      // Assert basic result structure
      expect(result1.runtimeState, equals('completed'));
      expect(result1.wasFallback, isFalse);
      expect(result1.errorMessage, isNull);
      expect(result1.bestPath.nodeIds, isNotEmpty);
      expect(result1.bestPath.nodeIds.first, equals('root'));

      // Perform evaluation again
      final result2 = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        enableDebug: true,
      );

      // Verify complete determinism/equality of outputs
      expect(result2.bestPath.nodeIds, equals(result1.bestPath.nodeIds));
      expect(result2.totalUtility, equals(result1.totalUtility));
      expect(result2.runtimeState, equals(result1.runtimeState));
      expect(result2.traces, equals(result1.traces));

      final json1 = json.encode(result1.toJson());
      final json2 = json.encode(result2.toJson());
      expect(json2, equals(json1));
    });
  });
}
