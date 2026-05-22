import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/pruning/score_pruner.dart';
import 'package:branchiq/src/pruning/pruning_reason.dart';
import 'package:test/test.dart';

void main() {
  group('ScorePruner Tests', () {
    final config = PruningConfig(
      minProbability: 0.0,
      minScore: 0.5,
      beamWidth: 5,
      maxDepth: 10,
      maxNodeLimit: 100,
    );

    test('Prunes nodes below score threshold and keeps others', () {
      final root = const DecisionNode.constant(
          id: 'root', childIds: ['c1', 'c2'], score: 0.0, depth: 0);
      final child1 = const DecisionNode.constant(
          id: 'c1', parentId: 'root', childIds: [], score: 0.45, depth: 1);
      final child2 = const DecisionNode.constant(
          id: 'c2', parentId: 'root', childIds: [], score: 0.7, depth: 1);

      final result = ScorePruner.pruneByScore([root, child1, child2], config);

      expect(result.retained, containsAllInOrder([root, child2]));
      expect(result.pruned, hasLength(1));
      expect(result.pruned.first.id, equals('c1'));
      expect(result.pruned.first.pruningReason,
          equals(PruningReason.scoreBelowThreshold.name));
    });

    test('Root node is never pruned even if score is below threshold', () {
      final root = const DecisionNode.constant(
          id: 'root', childIds: [], score: -0.5, depth: 0);
      final result = ScorePruner.pruneByScore([root], config);

      expect(result.retained, contains(root));
      expect(result.pruned, isEmpty);
    });

    test('Empty input list returns empty result lists', () {
      final result = ScorePruner.pruneByScore([], config);
      expect(result.retained, isEmpty);
      expect(result.pruned, isEmpty);
    });

    test('Original input nodes and list are not mutated', () {
      final root = const DecisionNode.constant(
          id: 'root', childIds: ['c1'], score: 0.0, depth: 0);
      final child = const DecisionNode.constant(
          id: 'c1', parentId: 'root', childIds: [], score: 0.2, depth: 1);
      final inputList = [root, child];

      final result = ScorePruner.pruneByScore(inputList, config);

      // Verify input list length unchanged
      expect(inputList, hasLength(2));
      expect(inputList[1].pruningReason, isNull);

      // Verify returned pruned node is a copy, not the original instance mutated
      expect(result.pruned.first.id, equals('c1'));
      expect(result.pruned.first.pruningReason,
          equals(PruningReason.scoreBelowThreshold.name));
      expect(child.pruningReason, isNull);
    });
  });
}
