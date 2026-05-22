import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/pruning/probability_pruner.dart';
import 'package:branchiq/src/pruning/pruning_reason.dart';
import 'package:test/test.dart';

void main() {
  group('ProbabilityPruner Tests', () {
    final config = PruningConfig(
      minProbability: 0.3,
      minScore: -1.0,
      beamWidth: 5,
      maxDepth: 10,
      maxNodeLimit: 100,
    );

    test('Prunes nodes below probability threshold and keeps others', () {
      final root = const DecisionNode.constant(
          id: 'root', childIds: ['c1', 'c2'], probability: 1.0, depth: 0);
      final child1 = const DecisionNode.constant(
          id: 'c1',
          parentId: 'root',
          childIds: [],
          probability: 0.25,
          depth: 1);
      final child2 = const DecisionNode.constant(
          id: 'c2', parentId: 'root', childIds: [], probability: 0.4, depth: 1);

      final result =
          ProbabilityPruner.pruneByProbability([root, child1, child2], config);

      expect(result.retained, containsAllInOrder([root, child2]));
      expect(result.pruned, hasLength(1));
      expect(result.pruned.first.id, equals('c1'));
      expect(result.pruned.first.pruningReason,
          equals(PruningReason.probabilityBelowThreshold.name));
    });

    test('Root node is never pruned even if probability is below threshold',
        () {
      // Root has parentId = null and depth = 0
      final root = const DecisionNode.constant(
          id: 'root', childIds: [], probability: 0.1, depth: 0);
      final result = ProbabilityPruner.pruneByProbability([root], config);

      expect(result.retained, contains(root));
      expect(result.pruned, isEmpty);
    });

    test('Empty input list returns empty result lists', () {
      final result = ProbabilityPruner.pruneByProbability([], config);
      expect(result.retained, isEmpty);
      expect(result.pruned, isEmpty);
    });

    test('Original input nodes and list are not mutated', () {
      final root = const DecisionNode.constant(
          id: 'root', childIds: ['c1'], probability: 1.0, depth: 0);
      final child = const DecisionNode.constant(
          id: 'c1', parentId: 'root', childIds: [], probability: 0.1, depth: 1);
      final inputList = [root, child];

      final result = ProbabilityPruner.pruneByProbability(inputList, config);

      // Verify input list length unchanged
      expect(inputList, hasLength(2));
      expect(inputList[1].pruningReason, isNull);

      // Verify returned pruned node is a copy, not the original instance mutated
      expect(result.pruned.first.id, equals('c1'));
      expect(result.pruned.first.pruningReason,
          equals(PruningReason.probabilityBelowThreshold.name));
      expect(child.pruningReason, isNull);
    });
  });
}
