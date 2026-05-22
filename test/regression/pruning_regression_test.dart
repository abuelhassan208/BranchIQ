import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/pruning/pruning_pipeline.dart';
import 'package:test/test.dart';

void main() {
  group('Pruning Core Regression and Determinism Tests', () {
    test(
        '150+ repeated pipeline runs produce identical results, sorting, and reasons',
        () {
      final config = PruningConfig(
        minProbability: 0.25,
        minScore: 0.35,
        beamWidth: 3,
        maxDepth: 10,
        maxNodeLimit: 200,
      );

      final root = const DecisionNode.constant(
          id: 'root',
          childIds: ['c1', 'c2', 'c3', 'c4', 'c5', 'c6'],
          score: 0.0,
          depth: 0);
      final c1 = const DecisionNode.constant(
          id: 'c1',
          parentId: 'root',
          childIds: [],
          probability: 0.1,
          score: 0.9,
          depth: 1); // Prob pruned
      final c2 = const DecisionNode.constant(
          id: 'c2',
          parentId: 'root',
          childIds: [],
          probability: 0.5,
          score: 0.2,
          depth: 1); // Score pruned
      final c3 = const DecisionNode.constant(
          id: 'c3',
          parentId: 'root',
          childIds: [],
          probability: 0.8,
          score: 0.8,
          depth: 1); // Retained
      final c4 = const DecisionNode.constant(
          id: 'c4',
          parentId: 'root',
          childIds: [],
          probability: 0.7,
          score: 0.7,
          depth: 1); // Retained
      final c5 = const DecisionNode.constant(
          id: 'c5',
          parentId: 'root',
          childIds: [],
          probability: 0.6,
          score: 0.6,
          depth: 1); // Retained
      final c6 = const DecisionNode.constant(
          id: 'c6',
          parentId: 'root',
          childIds: [],
          probability: 0.9,
          score: 0.5,
          depth: 1); // Beam pruned

      final inputList = [root, c1, c2, c3, c4, c5, c6];

      // Run initial execution
      final reference = PruningPipeline.runPruningPipeline(inputList, config);
      final referenceRetainedIds =
          reference.retainedNodes.map((n) => n.id).toList();
      final referencePrunedIds =
          reference.prunedNodes.map((n) => n.id).toList();
      final referenceReasons = reference.prunedNodes
          .map((n) => '${n.id}:${n.pruningReason}')
          .toList();

      expect(referenceRetainedIds, hasLength(4)); // c3, c4, c5, root
      expect(referencePrunedIds, hasLength(3)); // c1, c2, c6
      expect(reference.wasFallbackRequired, isFalse);

      // Run 150 iterations and assert complete identity
      for (int i = 0; i < 150; i++) {
        final loopResult =
            PruningPipeline.runPruningPipeline(inputList, config);
        final loopRetainedIds =
            loopResult.retainedNodes.map((n) => n.id).toList();
        final loopPrunedIds = loopResult.prunedNodes.map((n) => n.id).toList();
        final loopReasons = loopResult.prunedNodes
            .map((n) => '${n.id}:${n.pruningReason}')
            .toList();

        expect(loopRetainedIds, equals(referenceRetainedIds),
            reason: 'Iteration $i: Retained IDs mismatch');
        expect(loopPrunedIds, equals(referencePrunedIds),
            reason: 'Iteration $i: Pruned IDs mismatch');
        expect(loopReasons, equals(referenceReasons),
            reason: 'Iteration $i: Pruning reasons mismatch');
        expect(loopResult.wasFallbackRequired,
            equals(reference.wasFallbackRequired),
            reason: 'Iteration $i: Fallback mismatch');
        expect(loopResult.totalInputCount, equals(reference.totalInputCount));
        expect(loopResult.retainedCount, equals(reference.retainedCount));
        expect(loopResult.prunedCount, equals(reference.prunedCount));
      }
    });
  });
}
