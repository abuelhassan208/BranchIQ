import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

class MockEvaluator extends NodeEvaluator {
  @override
  final String id;

  MockEvaluator(this.id);

  @override
  DecisionNode evaluate(DecisionNode node, EvaluationContext context) {
    return node;
  }
}

void main() {
  group('Plugin API Exports Validation', () {
    test('public exports are accessible from package:branchiq/branchiq.dart',
        () {
      final evaluator = MockEvaluator('test-evaluator');
      final registry = PluginRegistry(evaluators: [evaluator]);

      expect(registry.evaluators, contains(evaluator));
      expect(registry.evaluators.first.id, equals('test-evaluator'));
    });
  });
}
