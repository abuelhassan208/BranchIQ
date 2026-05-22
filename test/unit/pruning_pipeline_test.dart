import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/pruning/pruning_pipeline.dart';
import 'package:branchiq/src/pruning/pruning_reason.dart';
import 'package:branchiq/src/pruning/pruning_result.dart';
import 'package:test/test.dart';

void main() {
  group('PruningPipeline Tests', () {
    final config = PruningConfig(
      minProbability: 0.3,
      minScore: 0.4,
      beamWidth: 2,
      maxDepth: 10,
      maxNodeLimit: 100,
    );

    test('Pipeline runs sequential stages and tags nodes correctly', () {
      final root = const DecisionNode.constant(
          id: 'root', childIds: ['c1', 'c2', 'c3', 'c4'], score: 0.0, depth: 0);

      // c1: probability 0.2 (< 0.3) -> pruned by probability
      final c1 = const DecisionNode.constant(
          id: 'c1',
          parentId: 'root',
          childIds: [],
          probability: 0.2,
          score: 0.8,
          depth: 1);

      // c2: score 0.3 (< 0.4) -> pruned by score
      final c2 = const DecisionNode.constant(
          id: 'c2',
          parentId: 'root',
          childIds: [],
          probability: 0.5,
          score: 0.3,
          depth: 1);

      // c3 & c4: pass thresholds. Let's make beam limit = 2. If we add c5:
      // c3: probability 0.6, score 0.7
      final c3 = const DecisionNode.constant(
          id: 'c3',
          parentId: 'root',
          childIds: [],
          probability: 0.6,
          score: 0.7,
          depth: 1);
      // c4: probability 0.7, score 0.6
      final c4 = const DecisionNode.constant(
          id: 'c4',
          parentId: 'root',
          childIds: [],
          probability: 0.7,
          score: 0.6,
          depth: 1);
      // c5: probability 0.8, score 0.5 -> pruned by beam width (since beamWidth = 2, and c3 and c4 have higher score)
      final c5 = const DecisionNode.constant(
          id: 'c5',
          parentId: 'root',
          childIds: [],
          probability: 0.8,
          score: 0.5,
          depth: 1);

      final result = PruningPipeline.runPruningPipeline(
          [root, c1, c2, c3, c4, c5], config);

      // Retained should contain root, c3, c4
      expect(result.retainedCount, equals(3));
      expect(result.retainedNodes.map((n) => n.id).toList(),
          containsAllInOrder(['c3', 'c4', 'root']));

      // Pruned should contain c1, c2, c5
      expect(result.prunedCount, equals(3));
      final prunedMap = {
        for (final n in result.prunedNodes) n.id: n.pruningReason
      };
      expect(prunedMap['c1'],
          equals(PruningReason.probabilityBelowThreshold.name));
      expect(prunedMap['c2'], equals(PruningReason.scoreBelowThreshold.name));
      expect(prunedMap['c5'], equals(PruningReason.beamWidthExceeded.name));

      expect(result.wasFallbackRequired, isFalse);
    });

    test('Triggers wasFallbackRequired when all child nodes are pruned', () {
      final root = const DecisionNode.constant(
          id: 'root', childIds: ['c1', 'c2'], score: 0.0, depth: 0);
      final c1 = const DecisionNode.constant(
          id: 'c1',
          parentId: 'root',
          childIds: [],
          probability: 0.1,
          score: 0.8,
          depth: 1);
      final c2 = const DecisionNode.constant(
          id: 'c2',
          parentId: 'root',
          childIds: [],
          probability: 0.5,
          score: 0.1,
          depth: 1);

      final result = PruningPipeline.runPruningPipeline([root, c1, c2], config);

      // Both c1 and c2 are pruned. Only root remains.
      expect(result.retainedNodes.map((n) => n.id).toList(), equals(['root']));
      expect(result.wasFallbackRequired, isTrue);
    });

    test('Does not trigger wasFallbackRequired when input contains only root',
        () {
      final root = const DecisionNode.constant(
          id: 'root', childIds: [], score: 0.0, depth: 0);

      final result = PruningPipeline.runPruningPipeline([root], config);

      expect(result.retainedNodes.map((n) => n.id).toList(), equals(['root']));
      expect(result.wasFallbackRequired, isFalse);
    });

    test('Empty input returns empty lists and wasFallbackRequired false', () {
      final result = PruningPipeline.runPruningPipeline([], config);

      expect(result.retainedNodes, isEmpty);
      expect(result.prunedNodes, isEmpty);
      expect(result.wasFallbackRequired, isFalse);
    });

    test('PruningResult JSON serialization and deserialization roundtrip', () {
      final root = const DecisionNode.constant(id: 'root', childIds: []);
      final prunedChild = const DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: [],
        pruningReason: 'probabilityBelowThreshold',
      );

      final result = PruningResult(
        retainedNodes: [root],
        prunedNodes: [prunedChild],
        wasFallbackRequired: true,
      );

      final json = result.toJson();
      final reconstructed = PruningResult.fromJson(json);

      expect(reconstructed.totalInputCount, equals(result.totalInputCount));
      expect(reconstructed.retainedCount, equals(result.retainedCount));
      expect(reconstructed.prunedCount, equals(result.prunedCount));
      expect(reconstructed.wasFallbackRequired, isTrue);
      expect(reconstructed.retainedNodes.first.id, equals('root'));
      expect(reconstructed.prunedNodes.first.id, equals('c1'));
      expect(reconstructed.prunedNodes.first.pruningReason,
          equals('probabilityBelowThreshold'));
    });
  });
}
