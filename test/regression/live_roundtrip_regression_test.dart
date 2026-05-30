import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('Live Engine DebugSnapshot Replay Roundtrip Regression Tests', () {
    test(
        'should export full node metadata and successfully reconstruct via Replay & Explainability',
        () {
      // 1. Build a representative decision tree with diverse attributes
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['accept', 'pruned_risky'],
        depth: 0,
      );

      final accept = const DecisionNode.constant(
        id: 'accept',
        parentId: 'root',
        childIds: [],
        probability: 0.95,
        impact: 0.8,
        cost: 30.0,
        metadata: {'custom_meta': 'accept_path'},
        tags: ['stable', 'high_probability'],
        depth: 1,
      );

      final prunedRisky = const DecisionNode.constant(
        id: 'pruned_risky',
        parentId: 'root',
        childIds: [],
        probability: 0.02, // Will be pruned by probability threshold
        impact: 0.9,
        cost: 100.0,
        metadata: {'custom_meta': 'risky_path'},
        tags: ['volatile', 'unstable'],
        depth: 1,
      );

      final tree = DecisionTree.fromNodes([root, accept, prunedRisky]);

      // 2. Evaluate using the live engine with debug mode enabled
      final engine = BranchIQEngine.createSync();
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: ScoringConfig.balanced(costCeiling: 100.0),
        pruningConfig: PruningConfig(
          minProbability: 0.05,
          minScore: -1.0,
          beamWidth: 5,
          maxDepth: 5,
          maxNodeLimit: 100,
        ),
        traversalConfig: const TraversalConfig(),
        enableDebug: true,
      );

      // Verify engine output
      expect(result.runtimeState, equals('completed'));
      expect(result.bestPath.nodeIds, equals(['root', 'accept']));
      expect(result.debugSnapshot, isNotNull);

      final snapshot = result.debugSnapshot!;

      // 3. Load snapshot into ReplaySession
      final session = ReplayLoader.load(snapshot);
      expect(session.rootId, equals('root'));
      expect(session.selectedPath, equals(['root', 'accept']));
      expect(session.prunedNodeIds, equals(['pruned_risky']));

      // 4. Verify ReplayInspector retrieves full decision evidence
      final inspector = ReplayInspector(session);

      // Verify selected path inspection
      final pathNodes = inspector.inspectSelectedPath();
      expect(pathNodes.length, equals(2));

      // Verify root node snapshot attributes
      final rootSnap = pathNodes[0];
      expect(rootSnap['id'], equals('root'));
      expect(rootSnap['depth'], equals(0));
      expect(rootSnap['score'], isNotNull);
      expect(rootSnap['confidence'], equals(1.0));

      // Verify accept node snapshot attributes
      final acceptSnap = pathNodes[1];
      expect(acceptSnap['id'], equals('accept'));
      expect(acceptSnap['parentId'], equals('root'));
      expect(acceptSnap['childIds'], equals([]));
      expect(acceptSnap['probability'], equals(0.95));
      expect(acceptSnap['impact'], equals(0.8));
      expect(acceptSnap['cost'], equals(30.0));
      expect(acceptSnap['confidence'], lessThan(1.0)); // decayed
      expect(acceptSnap['metadata'], equals({'custom_meta': 'accept_path'}));
      expect(acceptSnap['tags'], equals(['stable', 'high_probability']));

      // Verify pruned node inspection and correct sorting
      final prunedNodes = inspector.inspectPrunedNodes();
      expect(prunedNodes.length, equals(1));

      final prunedSnap = prunedNodes[0];
      expect(prunedSnap['id'], equals('pruned_risky'));
      expect(prunedSnap['parentId'], equals('root'));
      expect(prunedSnap['probability'], equals(0.02));
      expect(prunedSnap['impact'], equals(0.9));
      expect(prunedSnap['cost'], equals(100.0));
      expect(prunedSnap['pruningReason'], equals('probabilityBelowThreshold'));
      expect(prunedSnap['metadata'], equals({'custom_meta': 'risky_path'}));
      expect(prunedSnap['tags'], equals(['volatile', 'unstable']));

      // 5. Verify explainability executes on the reconstructed session
      final report = BranchIQExplainer.explain(session);
      expect(report.rootId, equals('root'));
      expect(report.selectedPath, equals(['root', 'accept']));
      expect(report.rejectedNodeIds, equals(['pruned_risky']));
      expect(report.toMarkdown(), contains('BranchIQ Explanation Report'));

      // 6. Verify path comparison executes successfully
      final comparison = BranchIQExplainer.comparePaths(
        session: session,
        selectedPath: ['root', 'accept'],
        rejectedPath: ['root', 'pruned_risky'],
      );
      expect(
          comparison.selectedUtility, greaterThan(comparison.rejectedUtility));
      expect(comparison.toMarkdown(), contains('Decision Path Comparison'));
    });
  });
}
