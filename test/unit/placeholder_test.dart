import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('DecisionNode Tests', () {
    test('should construct node with correct values', () {
      const node = DecisionNode.constant(
        id: 'node_1',
        childIds: ['node_2'],
        probability: 0.85,
        impact: 0.90,
        cost: 200.0,
      );

      expect(node.id, equals('node_1'));
      expect(node.childIds, contains('node_2'));
      expect(node.probability, equals(0.85));
      expect(node.impact, equals(0.90));
      expect(node.cost, equals(200.0));
    });

    test('copyWith should return a new instance with updated fields', () {
      const node = DecisionNode.constant(
        id: 'node_1',
        childIds: [],
      );

      final updated = node.copyWith(score: 0.75, depth: 2);
      expect(updated.id, equals(node.id));
      expect(updated.score, equals(0.75));
      expect(updated.depth, equals(2));
    });
  });

  group('DecisionTree Tests', () {
    test('should construct tree and resolve root', () {
      const root =
          DecisionNode.constant(id: 'root', childIds: ['node_1'], depth: 0);
      const node1 = DecisionNode.constant(
          id: 'node_1', parentId: 'root', childIds: [], depth: 1);

      final tree = DecisionTree.fromNodes([root, node1]);
      expect(tree.root.id, equals('root'));
      expect(tree.nodes, hasLength(2));
      expect(tree.isValid(), isTrue);
    });
  });

  group('BranchIQEngine Placeholder Evaluation Tests', () {
    test('should evaluate tree synchronously and return root path', () {
      const root = DecisionNode.constant(id: 'root', childIds: []);
      final tree = DecisionTree.fromNodes([root]);

      final scoring = ScoringConfig.balanced();
      final pruning = PruningConfig.defaultSettings();
      final engine = BranchIQEngine.createSync();

      final result = engine.evaluateSync(
        tree: tree,
        context: const EvaluationContext.empty(),
        scoringConfig: scoring,
        pruningConfig: pruning,
        traversalConfig: const TraversalConfig(),
        enableDebug: true,
      );

      expect(result.bestPath.nodeIds, equals(['root']));
      expect(result.traces, isNotEmpty);
      expect(result.traces.first, contains('Validation started'));
    });

    test('should support legacy parameters for backward compatibility', () {
      const root = DecisionNode.constant(id: 'root', childIds: []);
      final tree = DecisionTree.fromNodes([root]);

      final scoring = ScoringConfig.balanced();
      final pruning = PruningConfig.defaultSettings();
      final engine = BranchIQEngine.createSync();

      @pragma('vm:prefer-inline')
      final result = engine.evaluateSync(
        tree: tree,
        context: const EvaluationContext.empty(),
        scoring: scoring,
        pruning: pruning,
        traversal: const TraversalConfig(),
        enableDebug: true,
      );

      expect(result.bestPath.nodeIds, equals(['root']));
      expect(result.traces, isNotEmpty);
    });
  });
}
