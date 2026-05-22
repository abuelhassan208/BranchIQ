import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('BranchIQ Regression Tests', () {
    test('evaluateSync should be deterministic across 100 iterations', () {
      const root = DecisionNode.constant(id: 'root', childIds: []);
      final tree = DecisionTree.fromNodes([root]);

      final scoring = ScoringConfig.balanced();
      final pruning = PruningConfig.defaultSettings();
      final context = const EvaluationContext.empty();
      final traversal = const TraversalConfig();
      final engine = BranchIQEngine.createSync();

      final firstResult = engine.evaluateSync(
        tree: tree,
        context: context,
        scoring: scoring,
        pruning: pruning,
        traversal: traversal,
      );

      for (int i = 0; i < 100; i++) {
        final result = engine.evaluateSync(
          tree: tree,
          context: context,
          scoring: scoring,
          pruning: pruning,
          traversal: traversal,
        );

        expect(result.bestPath.nodeIds, equals(firstResult.bestPath.nodeIds));
        expect(result.traces, equals(firstResult.traces));
      }
    });
  });
}
