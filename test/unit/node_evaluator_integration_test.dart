import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

// 1. Define custom NodeEvaluator test mocks
class SignalCostEvaluator extends NodeEvaluator {
  @override
  final String id = 'signal-cost-evaluator';

  @override
  DecisionNode evaluate(DecisionNode node, EvaluationContext context) {
    if (node.id == 'call_network') {
      final latency = context.get('latency') as double? ?? 100.0;
      // Adjust cost dynamically based on latency variables
      return node.copyWith(cost: latency);
    }
    return node;
  }
}

class FactorMultiplierEvaluator extends NodeEvaluator {
  @override
  final String id = 'factor-multiplier-evaluator';

  @override
  DecisionNode evaluate(DecisionNode node, EvaluationContext context) {
    if (node.id == 'call_network') {
      // Multiply impact by a factor
      return node.copyWith(impact: node.impact * 2.0);
    }
    return node;
  }
}

class AdditiveCostEvaluator extends NodeEvaluator {
  @override
  final String id = 'additive-cost-evaluator';

  @override
  DecisionNode evaluate(DecisionNode node, EvaluationContext context) {
    if (node.id == 'call_network') {
      // Add a fee to cost
      return node.copyWith(cost: node.cost + 10.0);
    }
    return node;
  }
}

class ErrorThrowingEvaluator extends NodeEvaluator {
  @override
  final String id = 'error-throwing-evaluator';

  @override
  DecisionNode evaluate(DecisionNode node, EvaluationContext context) {
    throw StateError('Simulated evaluator error.');
  }
}

class MaliciousEvaluator extends NodeEvaluator {
  @override
  final String id = 'malicious-evaluator';

  @override
  DecisionNode evaluate(DecisionNode node, EvaluationContext context) {
    return DecisionNode(
      id: 'hacked_id',
      parentId: 'hacked_parent',
      childIds: const ['hacked_child'],
      depth: 99,
      confidence: 0.1234,
      probability: 0.88,
      impact: 0.88,
      cost: 88.0,
      metadata: const {'modified': true},
      tags: const ['modified'],
    );
  }
}

void main() {
  group('NodeEvaluator Scoring Integration Tests', () {
    final root = const DecisionNode.constant(
      id: 'root',
      parentId: null,
      childIds: ['call_network', 'fallback_local'],
      depth: 0,
    );

    final callNetwork = const DecisionNode.constant(
      id: 'call_network',
      parentId: 'root',
      childIds: [],
      probability: 0.9,
      impact:
          0.3, // Higher impact so that call_network scores higher in baseline
      cost: 5.0,
      depth: 1,
    );

    final fallbackLocal = const DecisionNode.constant(
      id: 'fallback_local',
      parentId: 'root',
      childIds: [],
      probability: 0.9,
      impact: 0.25,
      cost: 2.0,
      depth: 1,
    );

    final tree = DecisionTree.fromNodes([root, callNetwork, fallbackLocal]);
    final engine = BranchIQEngine.createSync();
    final scoringConfig = ScoringConfig.balanced(costCeiling: 200.0);
    final pruningConfig = PruningConfig.defaultSettings();
    const traversalConfig = TraversalConfig();

    test('Evaluator modifies node metrics before scoring, altering paths', () {
      final context = EvaluationContext({'latency': 150.0});

      // Without plugins, call_network should score higher
      final baseline = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: context,
        enableDebug: true,
      );
      expect(baseline.bestPath.nodeIds, equals(['root', 'call_network']));

      // With signal-cost plugin setting cost to 150.0, fallback_local should be selected
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: context,
        plugins: PluginRegistry(evaluators: [SignalCostEvaluator()]),
        enableDebug: true,
      );

      expect(result.bestPath.nodeIds, equals(['root', 'fallback_local']));
    });

    test(
        'Multiple evaluators execute sequentially in deterministic registry order',
        () {
      // Registry Order 1: Set cost to 100, then add 10 -> final cost 110
      final registry1 = PluginRegistry(evaluators: [
        SignalCostEvaluator(), // sets cost to 100
        AdditiveCostEvaluator(), // adds 10 to cost
      ]);

      final result1 = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: EvaluationContext({'latency': 100.0}),
        plugins: registry1,
        enableDebug: true,
      );

      final callNetworkNode1 =
          result1.debugSnapshot!.nodeSnapshots['call_network']!;
      expect(callNetworkNode1['cost'], equals(110.0));

      // Registry Order 2: Add 10, then set cost to 100 -> final cost 100
      final registry2 = PluginRegistry(evaluators: [
        AdditiveCostEvaluator(),
        SignalCostEvaluator(),
      ]);

      final result2 = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: EvaluationContext({'latency': 100.0}),
        plugins: registry2,
        enableDebug: true,
      );

      final callNetworkNode2 =
          result2.debugSnapshot!.nodeSnapshots['call_network']!;
      expect(callNetworkNode2['cost'], equals(100.0));
    });

    test('Plugin-modified node metrics propagate to DebugSnapshot', () {
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: EvaluationContext({'latency': 80.0}),
        plugins: PluginRegistry(evaluators: [
          SignalCostEvaluator(),
          FactorMultiplierEvaluator(),
        ]),
        enableDebug: true,
      );

      final snapshot = result.debugSnapshot!;
      final networkSnap = snapshot.nodeSnapshots['call_network']!;

      expect(networkSnap['cost'], equals(80.0));
      expect(networkSnap['impact'], equals(0.6)); // 0.3 * 2.0
    });

    test(
        'ReplayLoader loads plugin-modified snapshots offline without plugin classes',
        () {
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: EvaluationContext({'latency': 80.0}),
        plugins: PluginRegistry(evaluators: [
          SignalCostEvaluator(),
          FactorMultiplierEvaluator(),
        ]),
        enableDebug: true,
      );

      final snapshot = result.debugSnapshot!;

      // Load session from raw JSON string offline (loader is blind to SignalCostEvaluator/MultiplierEvaluator)
      final session = ReplayLoader.loadCanonicalJson(
        ReplayLoader.load(snapshot).toCanonicalJson(),
      );

      expect(session.selectedPath, equals(['root', 'fallback_local']));
      expect(session.nodeSnapshots['call_network']!['cost'], equals('80.0000'));
      expect(
          session.nodeSnapshots['call_network']!['impact'], equals('0.6000'));
    });

    test(
        'BranchIQExplainer reports only evidence from plugin-modified snapshots',
        () {
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: EvaluationContext({'latency': 80.0}),
        plugins: PluginRegistry(evaluators: [
          SignalCostEvaluator(),
          FactorMultiplierEvaluator(),
        ]),
        enableDebug: true,
      );

      final session = ReplayLoader.load(result.debugSnapshot!);
      final report = BranchIQExplainer.explain(session);

      // Verify the report renders only standard formatted table fields and records modified values
      expect(report.nodeExplanations['call_network']!.impactContribution,
          equals(0.6));

      final markdown = report.toMarkdown();
      expect(markdown, contains('fallback_local'));
      expect(markdown, contains('call_network'));
    });

    test('Null or empty plugin registry produces baseline results', () {
      final resNull = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        plugins: null,
        enableDebug: true,
      );

      final resEmpty = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        plugins: PluginRegistry(evaluators: []),
        enableDebug: true,
      );

      expect(resEmpty.debugSnapshot!.toJsonString(),
          equals(resNull.debugSnapshot!.toJsonString()));
    });

    test(
        'Throwing evaluator fails evaluation deterministically and exposes message',
        () {
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        plugins: PluginRegistry(evaluators: [ErrorThrowingEvaluator()]),
        enableDebug: true,
      );

      expect(result.runtimeState, equals('failed'));
      expect(result.wasFallback, isFalse);
      expect(result.errorMessage, contains('Simulated evaluator error.'));
    });

    test(
        'Repeated evaluations with plugins yield byte-identical canonical outputs',
        () {
      final registry = PluginRegistry(evaluators: [
        SignalCostEvaluator(),
        FactorMultiplierEvaluator(),
      ]);
      final context = EvaluationContext({'latency': 90.0});

      String? firstCanonical;
      String? firstMarkdown;

      for (int i = 0; i < 150; i++) {
        final result = engine.evaluateSync(
          tree: tree,
          scoringConfig: scoringConfig,
          pruningConfig: pruningConfig,
          traversalConfig: traversalConfig,
          context: context,
          plugins: registry,
          enableDebug: true,
        );

        final session = ReplayLoader.load(result.debugSnapshot!);
        final canonical = session.toCanonicalJson();
        final markdown = BranchIQExplainer.explain(session).toMarkdown();

        if (i == 0) {
          firstCanonical = canonical;
          firstMarkdown = markdown;
        } else {
          expect(canonical, equals(firstCanonical));
          expect(markdown, equals(firstMarkdown));
        }
      }
    });

    test(
        'Evaluator cannot override confidence or structural node identity properties',
        () {
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        plugins: PluginRegistry(evaluators: [MaliciousEvaluator()]),
        enableDebug: true,
      );

      final snapshot = result.debugSnapshot!;

      // Verify root node properties are preserved/restored
      final rootSnap = snapshot.nodeSnapshots['root']!;
      expect(rootSnap['id'], equals('root'));
      expect(rootSnap['parentId'], isNull);
      expect(rootSnap['childIds'], equals(['call_network', 'fallback_local']));
      expect(rootSnap['depth'], equals(0));
      expect(rootSnap['confidence'], equals(1.0));

      // Verify call_network node properties are preserved/restored
      final networkSnap = snapshot.nodeSnapshots['call_network']!;
      expect(networkSnap['id'], equals('call_network'));
      expect(networkSnap['parentId'], equals('root'));
      expect(networkSnap['childIds'], equals(<String>[]));
      expect(networkSnap['depth'], equals(1));

      // Restored engine-owned confidence (propagated confidence at depth 1 is ~0.8144)
      expect(networkSnap['confidence'], closeTo(0.8143536762323635, 1e-9));

      // Evaluator-allowed modifications allowed
      expect(networkSnap['probability'], equals(0.88));
      expect(networkSnap['impact'], equals(0.88));
      expect(networkSnap['cost'], equals(88.0));
      expect(networkSnap['metadata'], equals({'modified': true}));
      expect(networkSnap['tags'], equals(['modified']));
    });

    test('Plugin provenance is recorded when a NodeEvaluator modifies metrics',
        () {
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: EvaluationContext({'latency': 80.0}),
        plugins: PluginRegistry(evaluators: [SignalCostEvaluator()]),
        enableDebug: true,
      );

      final provenance = result.debugSnapshot!.pluginProvenance;
      expect(provenance, hasLength(1));
      expect(provenance.first['pluginId'], equals('signal-cost-evaluator'));
      expect(provenance.first['nodeId'], equals('call_network'));
      final modified =
          provenance.first['modifiedFields'] as Map<String, dynamic>;
      expect(modified['cost'], equals(80.0));
      expect(modified.containsKey('impact'), isFalse);
    });

    test(
        'Multiple evaluators generate provenance in deterministic registry order',
        () {
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: EvaluationContext({'latency': 80.0}),
        plugins: PluginRegistry(evaluators: [
          SignalCostEvaluator(),
          FactorMultiplierEvaluator(),
        ]),
        enableDebug: true,
      );

      final provenance = result.debugSnapshot!.pluginProvenance;
      expect(provenance, hasLength(2));
      expect(provenance[0]['pluginId'], equals('signal-cost-evaluator'));
      expect(provenance[1]['pluginId'], equals('factor-multiplier-evaluator'));
    });

    test(
        'Provenance survives export, canonical serialization, and replay loading without plugin classes',
        () {
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: EvaluationContext({'latency': 80.0}),
        plugins: PluginRegistry(evaluators: [
          SignalCostEvaluator(),
          FactorMultiplierEvaluator(),
        ]),
        enableDebug: true,
      );

      final originalProvenance = result.debugSnapshot!.pluginProvenance;
      final canonicalStr =
          ReplayLoader.load(result.debugSnapshot!).toCanonicalJson();

      // Load session back offline
      final session = ReplayLoader.loadCanonicalJson(canonicalStr);
      expect(session.pluginProvenance, hasLength(originalProvenance.length));
      expect(session.pluginProvenance[0]['pluginId'],
          equals('signal-cost-evaluator'));
      expect(session.pluginProvenance[1]['pluginId'],
          equals('factor-multiplier-evaluator'));
      final modified0 =
          session.pluginProvenance[0]['modifiedFields'] as Map<String, dynamic>;
      final modified1 =
          session.pluginProvenance[1]['modifiedFields'] as Map<String, dynamic>;
      expect(modified0['cost'], equals('80.0000'));
      expect(modified1['impact'], equals('0.6000'));
    });

    test('Explainability can access provenance evidence from snapshots', () {
      final result = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: EvaluationContext({'latency': 80.0}),
        plugins: PluginRegistry(evaluators: [
          SignalCostEvaluator(),
          FactorMultiplierEvaluator(),
        ]),
        enableDebug: true,
      );

      final session = ReplayLoader.load(result.debugSnapshot!);
      final report = BranchIQExplainer.explain(session);
      expect(report.pluginProvenance, hasLength(2));

      final markdown = report.toMarkdown();
      expect(markdown, contains('## Plugin Provenance'));
      expect(
          markdown,
          contains(
              'Plugin "signal-cost-evaluator" modified node "call_network"'));
      expect(markdown, contains('cost: 80.0000'));
      expect(markdown, contains('impact: 0.6000'));
    });

    test('Snapshot diffing remains deterministic', () {
      final result1 = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: EvaluationContext({'latency': 80.0}),
        plugins: PluginRegistry(evaluators: [
          SignalCostEvaluator(),
        ]),
        enableDebug: true,
      );

      final result2 = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        context: EvaluationContext({'latency': 80.0}),
        plugins: PluginRegistry(evaluators: [
          SignalCostEvaluator(),
          FactorMultiplierEvaluator(),
        ]),
        enableDebug: true,
      );

      final diff1 = SnapshotDiffer.compareSnapshots(
        source: result1.debugSnapshot!,
        target: result2.debugSnapshot!,
      );

      final diff2 = SnapshotDiffer.compareSnapshots(
        source: result1.debugSnapshot!,
        target: result2.debugSnapshot!,
      );

      expect(diff1.toCanonicalJson(), equals(diff2.toCanonicalJson()));
      expect(diff1.toMarkdown(), equals(diff2.toMarkdown()));
    });

    test('Repeated plugin-driven evaluations produce byte-identical snapshots',
        () {
      final registry = PluginRegistry(evaluators: [
        SignalCostEvaluator(),
        FactorMultiplierEvaluator(),
      ]);
      final context = EvaluationContext({'latency': 80.0});

      String? firstCanonical;

      for (int i = 0; i < 50; i++) {
        final result = engine.evaluateSync(
          tree: tree,
          scoringConfig: scoringConfig,
          pruningConfig: pruningConfig,
          traversalConfig: traversalConfig,
          context: context,
          plugins: registry,
          enableDebug: true,
        );

        final canonical =
            ReplayLoader.load(result.debugSnapshot!).toCanonicalJson();
        if (i == 0) {
          firstCanonical = canonical;
        } else {
          expect(canonical, equals(firstCanonical));
        }
      }
    });

    test(
        'Null/empty registries preserve baseline behavior and have empty/no provenance',
        () {
      final resultNull = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        plugins: null,
        enableDebug: true,
      );

      final resultEmpty = engine.evaluateSync(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        plugins: PluginRegistry(evaluators: []),
        enableDebug: true,
      );

      expect(resultNull.debugSnapshot!.pluginProvenance, isEmpty);
      expect(resultEmpty.debugSnapshot!.pluginProvenance, isEmpty);
    });
  });
}
