import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/pruning/beam_pruner.dart';
import 'package:branchiq/src/pruning/pruning_reason.dart';
import 'package:test/test.dart';

void main() {
  group('BeamPruner Tests', () {
    final config = PruningConfig(
      minProbability: 0.0,
      minScore: -1.0,
      beamWidth: 2,
      maxDepth: 10,
      maxNodeLimit: 100,
    );

    test(
        'Limits candidates to beamWidth and prunes the rest sorted by score descending',
        () {
      final child1 = const DecisionNode.constant(
          id: 'c1', parentId: 'root', childIds: [], score: 0.8, depth: 1);
      final child2 = const DecisionNode.constant(
          id: 'c2', parentId: 'root', childIds: [], score: 0.9, depth: 1);
      final child3 = const DecisionNode.constant(
          id: 'c3', parentId: 'root', childIds: [], score: 0.7, depth: 1);

      final result =
          BeamPruner.applyBeamWidth([child1, child2, child3], config);

      // beamWidth is 2, so top 2 nodes (c2 with 0.9, c1 with 0.8) are retained.
      // Output lists should be sorted by score descending.
      expect(result.retained.map((n) => n.id).toList(), equals(['c2', 'c1']));
      expect(result.pruned.map((n) => n.id).toList(), equals(['c3']));
      expect(result.pruned.first.pruningReason,
          equals(PruningReason.beamWidthExceeded.name));
    });

    test(
        'Tie-breaks lexicographically by node ID (ascending) when scores are equal',
        () {
      final childB = const DecisionNode.constant(
          id: 'c_b', parentId: 'root', childIds: [], score: 0.8, depth: 1);
      final childA = const DecisionNode.constant(
          id: 'c_a', parentId: 'root', childIds: [], score: 0.8, depth: 1);
      final childC = const DecisionNode.constant(
          id: 'c_c', parentId: 'root', childIds: [], score: 0.8, depth: 1);

      final result =
          BeamPruner.applyBeamWidth([childC, childB, childA], config);

      // beamWidth is 2. Since scores are all 0.8, tie break lexicographically:
      // Sorted order of keys: c_a, c_b, c_c.
      // Top 2: c_a, c_b.
      expect(result.retained.map((n) => n.id).toList(), equals(['c_a', 'c_b']));
      expect(result.pruned.map((n) => n.id).toList(), equals(['c_c']));
    });

    test(
        'Root node is always retained and does not count towards the beam count',
        () {
      final root = const DecisionNode.constant(
          id: 'root', childIds: ['c1', 'c2', 'c3'], score: 0.0, depth: 0);
      final child1 = const DecisionNode.constant(
          id: 'c1', parentId: 'root', childIds: [], score: 0.8, depth: 1);
      final child2 = const DecisionNode.constant(
          id: 'c2', parentId: 'root', childIds: [], score: 0.9, depth: 1);
      final child3 = const DecisionNode.constant(
          id: 'c3', parentId: 'root', childIds: [], score: 0.7, depth: 1);

      final result =
          BeamPruner.applyBeamWidth([root, child1, child2, child3], config);

      // root has depth = 0, so it is retained automatically.
      // Non-roots are c1, c2, c3. The top 2 are c2, c1. c3 is pruned.
      // The final retained list should contain the root and the top 2 children, all sorted deterministically.
      // Let's check the IDs of the retained nodes. Since root has score 0.0, and children have 0.9 and 0.8,
      // sorted order by compareNodes is: c2 (0.9), c1 (0.8), root (0.0).
      expect(result.retained.map((n) => n.id).toList(),
          equals(['c2', 'c1', 'root']));
      expect(result.pruned.map((n) => n.id).toList(), equals(['c3']));
    });

    test('Empty input list returns empty result lists', () {
      final result = BeamPruner.applyBeamWidth([], config);
      expect(result.retained, isEmpty);
      expect(result.pruned, isEmpty);
    });

    test('Original input nodes and list are not mutated', () {
      final child1 = const DecisionNode.constant(
          id: 'c1', parentId: 'root', childIds: [], score: 0.9, depth: 1);
      final child2 = const DecisionNode.constant(
          id: 'c2', parentId: 'root', childIds: [], score: 0.8, depth: 1);
      final child3 = const DecisionNode.constant(
          id: 'c3', parentId: 'root', childIds: [], score: 0.7, depth: 1);
      final inputList = [child1, child2, child3];

      final result = BeamPruner.applyBeamWidth(inputList, config);

      expect(inputList, hasLength(3));
      expect(inputList[2].pruningReason, isNull);

      expect(result.pruned.first.id, equals('c3'));
      expect(result.pruned.first.pruningReason,
          equals(PruningReason.beamWidthExceeded.name));
      expect(child3.pruningReason, isNull);
    });
  });
}
