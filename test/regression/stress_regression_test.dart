import 'dart:convert';
import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/runtime/runtime_pipeline.dart';
import 'package:test/test.dart';

void main() {
  group('Stress and Determinism Regression Tests', () {
    test('run stressed runtime pipeline 200+ times and assert identity', () {
      // 1. Build a complex, deterministic decision tree
      // root (depth 0)
      //  - c1 (depth 1, score calculations)
      //     - c1_1 (depth 2)
      //     - c1_2 (depth 2)
      //  - c2 (depth 1)
      //     - c2_1 (depth 2)
      //     - c2_2 (depth 2)
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1', 'c2'],
        depth: 0,
        score: 0.5,
        confidence: 1.0,
      );
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: ['c1_1', 'c1_2'],
        depth: 1,
        score: 0.7,
        confidence: 0.9,
      );
      final c1_1 = const DecisionNode.constant(
        id: 'c1_1',
        parentId: 'c1',
        childIds: [],
        depth: 2,
        score: 0.8,
        confidence: 0.8,
      );
      final c1_2 = const DecisionNode.constant(
        id: 'c1_2',
        parentId: 'c1',
        childIds: [],
        depth: 2,
        score: 0.95,
        confidence: 0.85,
      );
      final c2 = const DecisionNode.constant(
        id: 'c2',
        parentId: 'root',
        childIds: ['c2_1', 'c2_2'],
        depth: 1,
        score: 0.6,
        confidence: 0.9,
      );
      final c2_1 = const DecisionNode.constant(
        id: 'c2_1',
        parentId: 'c2',
        childIds: [],
        depth: 2,
        score: 0.85,
        confidence: 0.8,
      );
      final c2_2 = const DecisionNode.constant(
        id: 'c2_2',
        parentId: 'c2',
        childIds: [],
        depth: 2,
        score: 0.4,
        confidence: 0.7,
      );

      final tree =
          DecisionTree.fromNodes([root, c1, c1_1, c1_2, c2, c2_1, c2_2]);

      final scoringConfig = ScoringConfig.balanced();
      final pruningConfig = PruningConfig(
        minProbability: 0.05,
        minScore: 0.1,
        beamWidth: 3,
        maxDepth: 5,
        maxNodeLimit: 50,
      );
      const traversalConfig = TraversalConfig();

      // 2. Perform reference run
      final firstResult = RuntimePipeline.runPipeline(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        enableDebug: true,
        enableBenchmark: true,
      );

      expect(firstResult.errorMessage, isNull);
      expect(firstResult.bestPath.nodeIds, isNotEmpty);

      final firstBenchmarkJson =
          jsonEncode(firstResult.benchmarkSnapshot?.toJson());
      final firstDebugJson = jsonEncode(firstResult.debugSnapshot?.toJson());
      final firstPath = firstResult.bestPath.nodeIds;
      final firstUtility = firstResult.totalUtility;
      final firstFallback = firstResult.wasFallback;
      final firstState = firstResult.runtimeState;

      // 3. Stress execution 250 times
      for (int i = 0; i < 250; i++) {
        final result = RuntimePipeline.runPipeline(
          tree: tree,
          scoringConfig: scoringConfig,
          pruningConfig: pruningConfig,
          traversalConfig: traversalConfig,
          enableDebug: true,
          enableBenchmark: true,
        );

        final benchmarkJson = jsonEncode(result.benchmarkSnapshot?.toJson());
        final debugJson = jsonEncode(result.debugSnapshot?.toJson());

        expect(result.bestPath.nodeIds, equals(firstPath),
            reason: 'Path mismatch at iteration $i');
        expect(result.totalUtility, equals(firstUtility),
            reason: 'Utility mismatch at iteration $i');
        expect(result.wasFallback, equals(firstFallback),
            reason: 'Fallback status mismatch at iteration $i');
        expect(result.runtimeState, equals(firstState),
            reason: 'Runtime state mismatch at iteration $i');
        expect(benchmarkJson, equals(firstBenchmarkJson),
            reason: 'Benchmark snapshot JSON mismatch at iteration $i');
        expect(debugJson, equals(firstDebugJson),
            reason: 'Debug snapshot JSON mismatch at iteration $i');
      }
    });
  });
}
