import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('BranchIQEngine Tests', () {
    final tree = DecisionTree.fromNodes([
      const DecisionNode.constant(id: 'root', childIds: ['c1'], depth: 0),
      const DecisionNode.constant(
          id: 'c1', parentId: 'root', childIds: [], depth: 1),
    ]);

    test(
        'should evaluate tree synchronously using new configuration parameters',
        () {
      final engine = BranchIQEngine.createSync();
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: ScoringConfig.balanced(),
        pruningConfig: PruningConfig.defaultSettings(),
        traversalConfig: const TraversalConfig(),
        enableDebug: true,
      );

      expect(result.bestPath.nodeIds, equals(['root', 'c1']));
      expect(result.runtimeState, equals('completed'));
      expect(result.errorMessage, isNull);
      expect(result.debugSnapshot, isNotNull);
    });

    test(
        'should evaluate tree synchronously using legacy configuration parameters',
        () {
      final engine = BranchIQEngine.createSync();
      @pragma('vm:prefer-inline')
      final result = engine.evaluateSync(
        tree: tree,
        scoring: ScoringConfig.balanced(),
        pruning: PruningConfig.defaultSettings(),
        traversal: const TraversalConfig(),
        enableDebug: true,
      );

      expect(result.bestPath.nodeIds, equals(['root', 'c1']));
      expect(result.runtimeState, equals('completed'));
      expect(result.debugSnapshot, isNotNull);
    });

    test('should throw ArgumentError if any configurations are missing', () {
      final engine = BranchIQEngine.createSync();

      expect(
        () => engine.evaluateSync(
            tree: tree,
            pruningConfig: PruningConfig.defaultSettings(),
            traversalConfig: const TraversalConfig()),
        throwsArgumentError,
      );

      expect(
        () => engine.evaluateSync(
            tree: tree,
            scoringConfig: ScoringConfig.balanced(),
            traversalConfig: const TraversalConfig()),
        throwsArgumentError,
      );

      expect(
        () => engine.evaluateSync(
            tree: tree,
            scoringConfig: ScoringConfig.balanced(),
            pruningConfig: PruningConfig.defaultSettings()),
        throwsArgumentError,
      );
    });

    test('explain should return a human-readable tracing explanation log', () {
      final engine = BranchIQEngine.createSync();
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: ScoringConfig.balanced(),
        pruningConfig: PruningConfig.defaultSettings(),
        traversalConfig: const TraversalConfig(),
        enableDebug: true,
      );

      final explanation = engine.explain(result);
      expect(explanation, contains('Path chosen: root -> c1'));
      expect(explanation, contains('Total Utility:'));
      expect(explanation, contains('State: completed'));
      expect(explanation, contains('Traces:'));
      expect(explanation, contains('[VALIDATION] Validation started'));
      expect(explanation, contains('[COMPLETION] Pipeline completed'));
    });

    test(
        'exportDebugSnapshot should return a detailed snapshot when debugging is enabled',
        () {
      final engine = BranchIQEngine.createSync();
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: ScoringConfig.balanced(),
        pruningConfig: PruningConfig.defaultSettings(),
        traversalConfig: const TraversalConfig(),
        enableDebug: true,
      );

      final snapshot = engine.exportDebugSnapshot(result);
      expect(snapshot.rootId, equals('root'));
      expect(snapshot.selectedPath, equals(['root', 'c1']));
      expect(snapshot.nodeSnapshots.keys, containsAll(['root', 'c1']));
      expect(snapshot.runtimeTraces, isNotEmpty);
    });

    test(
        'exportDebugSnapshot should return a lightweight snapshot when debugging is disabled',
        () {
      final engine = BranchIQEngine.createSync();
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: ScoringConfig.balanced(),
        pruningConfig: PruningConfig.defaultSettings(),
        traversalConfig: const TraversalConfig(),
        enableDebug: false,
      );

      final snapshot = engine.exportDebugSnapshot(result);
      expect(snapshot.rootId, equals('root'));
      expect(snapshot.selectedPath, equals(['root', 'c1']));
      expect(snapshot.nodeSnapshots, isEmpty);
      expect(snapshot.runtimeTraces, isEmpty);
    });
  });
}
