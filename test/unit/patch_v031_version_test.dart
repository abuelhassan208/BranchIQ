import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/runtime/runtime_pipeline.dart';
import 'package:branchiq/src/version/branchiq_version.dart';
import 'package:test/test.dart';

void main() {
  group('v0.3.1 Version and Schema Mapping Tests', () {
    test('internal version constant is 0.3.1', () {
      expect(branchIQVersion, equals('0.3.1'));
    });

    test('Fresh DebugSnapshot from BranchIQEngine exports engineVersion 0.3.1',
        () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: [],
        depth: 0,
        probability: 1.0,
        impact: 1.0,
        cost: 0.0,
      );
      final tree = DecisionTree.fromNodes([root]);
      final engine = BranchIQEngine.createSync();
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: ScoringConfig.balanced(costCeiling: 100.0),
        pruningConfig: PruningConfig.defaultSettings(),
        traversalConfig: const TraversalConfig(),
        enableDebug: true,
      );

      final snapshot = engine.exportDebugSnapshot(result);
      expect(snapshot.engineVersion, equals('0.3.1'));
    });

    test('Fresh runtime_pipeline snapshots export engineVersion 0.3.1', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: [],
        depth: 0,
        probability: 1.0,
        impact: 1.0,
        cost: 0.0,
      );
      final tree = DecisionTree.fromNodes([root]);
      final result = RuntimePipeline.runPipeline(
        tree: tree,
        scoringConfig: ScoringConfig.balanced(costCeiling: 100.0),
        pruningConfig: PruningConfig.defaultSettings(),
        traversalConfig: const TraversalConfig(),
        enableDebug: true,
      );

      expect(result.debugSnapshot, isNotNull);
      expect(result.debugSnapshot!.engineVersion, equals('0.3.1'));
    });

    test('ReplayLoader infers schemaVersion 2.0 for engineVersion 0.3.1', () {
      const snapshot = DebugSnapshot(
        engineVersion: '0.3.1',
        rootId: 'root',
        selectedPath: ['root'],
        nodeSnapshots: {
          'root': {'score': 1.0, 'depth': 0},
        },
        pruningTraces: [],
        metadata: {},
      );

      final session = ReplayLoader.load(snapshot);
      expect(session.schemaVersion, equals('2.0'));
      expect(session.engineVersion, equals('0.3.1'));
    });

    test('Legacy engineVersion 0.1.0 still maps to schemaVersion 1.0', () {
      const snapshot = DebugSnapshot(
        engineVersion: '0.1.0',
        rootId: 'root',
        selectedPath: ['root'],
        nodeSnapshots: {
          'root': {'score': 1.0, 'depth': 0},
        },
        pruningTraces: [],
        metadata: {},
      );

      final session = ReplayLoader.load(snapshot);
      expect(session.schemaVersion, equals('1.0'));
    });

    test('engineVersion 0.2.x still maps to schemaVersion 2.0', () {
      const snapshot = DebugSnapshot(
        engineVersion: '0.2.5',
        rootId: 'root',
        selectedPath: ['root'],
        nodeSnapshots: {
          'root': {'score': 1.0, 'depth': 0},
        },
        pruningTraces: [],
        metadata: {},
      );

      final session = ReplayLoader.load(snapshot);
      expect(session.schemaVersion, equals('2.0'));
    });
  });
}
