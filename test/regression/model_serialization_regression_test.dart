import 'dart:convert';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('Model Serialization Regression and Determinism Tests', () {
    late DecisionTree complexTree;
    late ScoringConfig scoring;
    late PruningConfig pruning;
    late TraversalConfig traversal;
    late EvaluationContext context;
    late EvaluationResult result;

    setUp(() {
      final root = DecisionNode(
        id: 'node_root',
        childIds: const ['node_child_b', 'node_child_a'],
        probability: 1.0,
        impact: 0.0,
        cost: 0.0,
        confidence: 1.0,
        score: 0.0,
        depth: 0,
        tags: const ['start'],
        metadata: const {'env': 'prod'},
      );

      final childA = DecisionNode(
        id: 'node_child_a',
        parentId: 'node_root',
        childIds: const [],
        probability: 0.4,
        impact: 0.8,
        cost: 150.0,
        confidence: 0.9,
        score: 0.65,
        depth: 1,
        tags: const ['leaf', 'option_a'],
        metadata: const {'weight': 'heavy'},
      );

      final childB = DecisionNode(
        id: 'node_child_b',
        parentId: 'node_root',
        childIds: const [],
        probability: 0.6,
        impact: 0.3,
        cost: 80.0,
        confidence: 0.95,
        score: 0.48,
        depth: 1,
        tags: const ['leaf', 'option_b'],
        metadata: const {'weight': 'light'},
      );

      // Create tree from list of nodes
      complexTree = DecisionTree.fromNodes([childB, childA, root]);

      scoring = ScoringConfig(wp: 0.4, wi: 0.4, wc: 0.2, costCeiling: 1000.0);
      pruning = PruningConfig(
          minProbability: 0.1,
          minScore: -0.5,
          beamWidth: 4,
          maxDepth: 8,
          maxNodeLimit: 200);
      traversal =
          const TraversalConfig(strategy: TraversalStrategy.priorityFirst);

      context = EvaluationContext({
        'user_id': 'user_123',
        'is_mobile': true,
        'features': ['f1', 'f2'],
        'params': {'k1': 'v1'},
      });

      final bestPath = BestPathResult(
        nodes: [root, childA],
        nodeIds: const ['node_root', 'node_child_a'],
      );

      const debugSnapshot = DebugSnapshot(
        engineVersion: '0.1.0',
        rootId: 'node_root',
        selectedPath: ['node_root', 'node_child_a'],
        nodeSnapshots: {
          'node_root': {'score': 0.0, 'depth': 0},
          'node_child_a': {'score': 0.65, 'depth': 1},
          'node_child_b': {'score': 0.48, 'depth': 1},
        },
        pruningTraces: ['pruned node_child_b'],
        metadata: {'run': 1},
      );

      result = EvaluationResult(
        bestPath: bestPath,
        traces: const ['started', 'evaluated child_a', 'selected child_a'],
        durationMs: 5,
        wasFallback: false,
        debugSnapshot: debugSnapshot,
      );
    });

    test('Serializing DecisionTree 100 times produces identical JSON output',
        () {
      final initialJsonString = jsonEncode(complexTree.toJson());

      for (int i = 0; i < 100; i++) {
        final loopJsonString = jsonEncode(complexTree.toJson());
        expect(loopJsonString, equals(initialJsonString),
            reason: 'Iteration $i failed: JSON differed.');
      }
    });

    test('Deserializing and reserializing DecisionTree produces identical JSON',
        () {
      final initialMap = complexTree.toJson();
      final reconstructedTree = DecisionTree.fromJson(initialMap);
      final reconstructedMap = reconstructedTree.toJson();

      expect(reconstructedMap, equals(initialMap));
      expect(jsonEncode(reconstructedMap), equals(jsonEncode(initialMap)));
    });

    test('Serializing Config Models 100 times produces identical JSON', () {
      final initialScoringStr = jsonEncode(scoring.toJson());
      final initialPruningStr = jsonEncode(pruning.toJson());
      final initialTraversalStr = jsonEncode(traversal.toJson());

      for (int i = 0; i < 100; i++) {
        expect(jsonEncode(scoring.toJson()), equals(initialScoringStr));
        expect(jsonEncode(pruning.toJson()), equals(initialPruningStr));
        expect(jsonEncode(traversal.toJson()), equals(initialTraversalStr));
      }
    });

    test(
        'Deserializing and reserializing Config Models produces identical JSON',
        () {
      final scoringMap = scoring.toJson();
      final pruningMap = pruning.toJson();
      final traversalMap = traversal.toJson();

      expect(ScoringConfig.fromJson(scoringMap).toJson(), equals(scoringMap));
      expect(PruningConfig.fromJson(pruningMap).toJson(), equals(pruningMap));
      expect(TraversalConfig.fromJson(traversalMap).toJson(),
          equals(traversalMap));
    });

    test(
        'Serializing EvaluationContext 100 times produces identical JSON and has stable sorting',
        () {
      final initialContextStr = jsonEncode(context.toJson());

      for (int i = 0; i < 100; i++) {
        expect(jsonEncode(context.toJson()), equals(initialContextStr));
      }

      final reconstructedContext = EvaluationContext.fromJson(context.toJson());
      expect(
          jsonEncode(reconstructedContext.toJson()), equals(initialContextStr));
    });

    test(
        'Serializing EvaluationResult & DebugSnapshot 100 times produces identical JSON',
        () {
      final initialResultStr = jsonEncode(result.toJson());
      final initialSnapshotStr = jsonEncode(result.debugSnapshot!.toJson());

      for (int i = 0; i < 100; i++) {
        expect(jsonEncode(result.toJson()), equals(initialResultStr));
        expect(jsonEncode(result.debugSnapshot!.toJson()),
            equals(initialSnapshotStr));
      }

      final reconstructedResult = EvaluationResult.fromJson(result.toJson());
      expect(
          jsonEncode(reconstructedResult.toJson()), equals(initialResultStr));
    });
  });
}
