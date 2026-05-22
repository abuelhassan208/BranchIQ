import 'dart:convert';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('Runtime Engine Regression and Determinism Replay Tests', () {
    // Define a multi-branch layout:
    // root -> n1 -> n1_1
    //      -> n2 -> n2_1
    final treeNodes = [
      const DecisionNode.constant(
        id: 'root',
        childIds: ['n1', 'n2'],
        depth: 0,
      ),
      const DecisionNode.constant(
        id: 'n1',
        parentId: 'root',
        childIds: ['n1_1'],
        depth: 1,
        probability: 0.9,
        impact: 0.75,
        cost: 60.0,
      ),
      const DecisionNode.constant(
        id: 'n1_1',
        parentId: 'n1',
        childIds: [],
        depth: 2,
        probability: 0.95,
        impact: 0.9,
        cost: 20.0,
      ),
      const DecisionNode.constant(
        id: 'n2',
        parentId: 'root',
        childIds: ['n2_1'],
        depth: 1,
        probability: 0.85,
        impact: 0.8,
        cost: 40.0,
      ),
      const DecisionNode.constant(
        id: 'n2_1',
        parentId: 'n2',
        childIds: [],
        depth: 2,
        probability: 0.88,
        impact: 0.78,
        cost: 30.0,
      ),
    ];

    test(
        'should execute identical evaluation 150+ times and produce identical results',
        () {
      final tree = DecisionTree.fromNodes(treeNodes);
      final scoringConfig = ScoringConfig.balanced();
      final pruningConfig = PruningConfig.defaultSettings();
      final traversalConfig = const TraversalConfig();
      final engine = BranchIQEngine.createSync();

      // Run evaluation first time
      final firstResult = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        enableDebug: true,
      );

      final firstResultJson = json.encode(firstResult.toJson());
      final firstSnapshotJson =
          json.encode(engine.exportDebugSnapshot(firstResult).toJson());

      expect(firstResult.bestPath.nodeIds, isNotEmpty);
      expect(firstResult.traces, isNotEmpty);

      // Execute 175 more times
      for (int i = 0; i < 175; i++) {
        final result = engine.evaluateSync(
          tree: tree,
          scoringConfig: scoringConfig,
          pruningConfig: pruningConfig,
          traversalConfig: traversalConfig,
          enableDebug: true,
        );

        // Assert selected path identity
        expect(result.bestPath.nodeIds, equals(firstResult.bestPath.nodeIds));

        // Assert runtime trace identity
        expect(result.traces, equals(firstResult.traces));

        // Assert total utility identity
        expect(result.totalUtility, equals(firstResult.totalUtility));

        // Assert complete JSON response structure identity
        final currentJson = json.encode(result.toJson());
        expect(currentJson, equals(firstResultJson));

        // Assert debug snapshot structure identity
        final currentSnapshotJson =
            json.encode(engine.exportDebugSnapshot(result).toJson());
        expect(currentSnapshotJson, equals(firstSnapshotJson));
      }
    });
  });
}
