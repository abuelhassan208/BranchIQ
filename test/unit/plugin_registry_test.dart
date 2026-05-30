import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/plugins/plugin_registry_validator.dart';
import 'package:test/test.dart';

class TestEvaluator extends NodeEvaluator {
  @override
  final String id;

  TestEvaluator(this.id);

  @override
  DecisionNode evaluate(DecisionNode node, EvaluationContext context) {
    return node;
  }
}

void main() {
  group('PluginRegistry and NodeEvaluator Validation Tests', () {
    final tree = DecisionTree.fromNodes([
      const DecisionNode.constant(id: 'root', childIds: ['c1'], depth: 0),
      const DecisionNode.constant(
          id: 'c1', parentId: 'root', childIds: [], depth: 1),
    ]);

    final engine = BranchIQEngine.createSync();
    final scoringConfig = ScoringConfig.balanced();
    final pruningConfig = PruningConfig.defaultSettings();
    const traversalConfig = TraversalConfig();

    group('PluginRegistryValidator Direct Tests', () {
      test('should pass with valid registry', () {
        final registry = PluginRegistry(evaluators: [
          TestEvaluator('evaluator-a'),
          TestEvaluator('evaluator-b'),
        ]);
        expect(
            () => PluginRegistryValidator.validate(registry), returnsNormally);
      });

      test('should throw ArgumentError for duplicate IDs', () {
        final registry = PluginRegistry(evaluators: [
          TestEvaluator('evaluator-a'),
          TestEvaluator('evaluator-a'),
        ]);
        expect(() => PluginRegistryValidator.validate(registry),
            throwsArgumentError);
      });

      test('should throw ArgumentError for empty IDs', () {
        final registry = PluginRegistry(evaluators: [
          TestEvaluator(''),
        ]);
        expect(() => PluginRegistryValidator.validate(registry),
            throwsArgumentError);
      });

      test('should throw ArgumentError for non-ASCII IDs', () {
        final registry = PluginRegistry(evaluators: [
          TestEvaluator('evaluator-ü'),
        ]);
        expect(() => PluginRegistryValidator.validate(registry),
            throwsArgumentError);
      });
    });

    group('Engine evaluateSync Validation Integration', () {
      test(
          'Empty or null plugin registry produces identical results to baseline',
          () {
        final baselineResult = engine.evaluateSync(
          tree: tree,
          scoringConfig: scoringConfig,
          pruningConfig: pruningConfig,
          traversalConfig: traversalConfig,
          enableDebug: true,
        );

        final emptyRegistryResult = engine.evaluateSync(
          tree: tree,
          scoringConfig: scoringConfig,
          pruningConfig: pruningConfig,
          traversalConfig: traversalConfig,
          plugins: PluginRegistry(evaluators: const []),
          enableDebug: true,
        );

        // Verify structures and path results are byte-identical
        expect(emptyRegistryResult.runtimeState,
            equals(baselineResult.runtimeState));
        expect(emptyRegistryResult.bestPath.nodeIds,
            equals(baselineResult.bestPath.nodeIds));
        expect(emptyRegistryResult.totalUtility,
            equals(baselineResult.totalUtility));

        // Compare serialized JSON string representations
        expect(emptyRegistryResult.debugSnapshot!.toJsonString(),
            equals(baselineResult.debugSnapshot!.toJsonString()));
      });

      test(
          'Duplicate plugin IDs throw deterministic ArgumentError validation error',
          () {
        final registry = PluginRegistry(evaluators: [
          TestEvaluator('evaluator-a'),
          TestEvaluator('evaluator-b'),
          TestEvaluator('evaluator-a'), // Duplicate ID
        ]);

        expect(
          () => engine.evaluateSync(
            tree: tree,
            scoringConfig: scoringConfig,
            pruningConfig: pruningConfig,
            traversalConfig: traversalConfig,
            plugins: registry,
          ),
          throwsArgumentError,
        );
      });

      test(
          'Non-ASCII plugin IDs throw deterministic ArgumentError validation error',
          () {
        final registry = PluginRegistry(evaluators: [
          TestEvaluator('evaluator-ü'), // 'ü' is non-ASCII (code unit 252)
        ]);

        expect(
          () => engine.evaluateSync(
            tree: tree,
            scoringConfig: scoringConfig,
            pruningConfig: pruningConfig,
            traversalConfig: traversalConfig,
            plugins: registry,
          ),
          throwsArgumentError,
        );
      });

      test(
          'Empty plugin ID throws deterministic ArgumentError validation error',
          () {
        final registry = PluginRegistry(evaluators: [
          TestEvaluator(''), // Empty ID
        ]);

        expect(
          () => engine.evaluateSync(
            tree: tree,
            scoringConfig: scoringConfig,
            pruningConfig: pruningConfig,
            traversalConfig: traversalConfig,
            plugins: registry,
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
