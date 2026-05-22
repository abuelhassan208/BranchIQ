import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/runtime/runtime_pipeline.dart';
import 'package:branchiq/src/runtime/runtime_state.dart';
import 'package:branchiq/src/validation/tree_validator.dart';
import 'package:test/test.dart';

class InvalidTreeMock implements DecisionTree {
  @override
  final Map<String, DecisionNode> nodes;

  InvalidTreeMock(this.nodes);

  @override
  DecisionNode get root => nodes.values.first;

  @override
  DecisionNode? getNode(String id) => nodes[id];

  @override
  bool containsNode(String id) => nodes.containsKey(id);

  @override
  List<DecisionNode> childrenOf(String id) {
    final node = nodes[id];
    if (node == null) return const [];
    return node.childIds.map((cid) {
      final child = nodes[cid];
      if (child == null) {
        throw OrphanNodeException(
            'Node "$id" references missing child "$cid".');
      }
      return child;
    }).toList();
  }

  @override
  bool isValid() => false;

  @override
  void validateOrThrow() {
    TreeValidator.validate(this);
  }

  @override
  Map<String, dynamic> toJson() => {};
}

void main() {
  group('RuntimePipeline Tests', () {
    final scoringConfig = ScoringConfig.balanced();
    final pruningConfig = PruningConfig.defaultSettings();
    const traversalConfig = TraversalConfig();

    test('should evaluate a simple valid tree successfully', () {
      const root =
          DecisionNode.constant(id: 'root', childIds: ['c1'], depth: 0);
      const c1 = DecisionNode.constant(
          id: 'c1', parentId: 'root', childIds: [], depth: 1);
      final tree = DecisionTree.fromNodes([root, c1]);

      final result = RuntimePipeline.runPipeline(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        enableDebug: true,
      );

      expect(result.runtimeState, equals(RuntimeState.completed.name));
      expect(result.errorMessage, isNull);
      expect(result.wasFallback, isFalse);
      expect(result.bestPath.nodeIds, equals(['root', 'c1']));
      expect(result.traces, isNotEmpty);
    });

    test(
        'should handle validation failure safely by returning a failed EvaluationResult',
        () {
      // Create invalid nodes forming a cycle: root -> c1 -> root
      const root =
          DecisionNode.constant(id: 'root', childIds: ['c1'], depth: 0);
      const c1 = DecisionNode.constant(
          id: 'c1', parentId: 'root', childIds: ['root'], depth: 1);

      // Bypass constructor validation by using the Mock
      final tree = InvalidTreeMock({'root': root, 'c1': c1});

      final result = RuntimePipeline.runPipeline(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        enableDebug: true,
      );

      expect(result.runtimeState, equals(RuntimeState.failed.name));
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('CycleDetectedException'));
      expect(result.bestPath.nodeIds, isEmpty);
      expect(result.wasFallback, isFalse);
    });

    test('should propagate confidence levels level-by-level using BFS', () {
      // root confidence = 1.0, depth 0
      // c1: child of root, depth 1 => confidence should decay
      // c2: child of c1, depth 2 => confidence should decay further
      const root = DecisionNode.constant(
          id: 'root', childIds: ['c1'], depth: 0, confidence: 1.0);
      const c1 = DecisionNode.constant(
          id: 'c1',
          parentId: 'root',
          childIds: ['c2'],
          depth: 1,
          confidence: 1.0);
      const c2 = DecisionNode.constant(
          id: 'c2', parentId: 'c1', childIds: [], depth: 2, confidence: 1.0);
      final tree = DecisionTree.fromNodes([root, c1, c2]);

      final result = RuntimePipeline.runPipeline(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        enableDebug: true,
      );

      expect(result.runtimeState, equals(RuntimeState.completed.name));
      final snapshot = result.debugSnapshot;
      expect(snapshot, isNotNull);

      final rootSnap = snapshot!.nodeSnapshots['root']!;
      final c1Snap = snapshot.nodeSnapshots['c1']!;
      final c2Snap = snapshot.nodeSnapshots['c2']!;

      expect(rootSnap['confidence'], equals(1.0));
      expect(c1Snap['confidence'], lessThan(1.0));
      expect(c2Snap['confidence'], lessThan(c1Snap['confidence'] as double));
    });

    test('should handle fallback gracefully when all child branches are pruned',
        () {
      // root is always kept. Let's prune c1 by giving it a probability below 0.05
      const root =
          DecisionNode.constant(id: 'root', childIds: ['c1'], depth: 0);
      const c1 = DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: [],
        depth: 1,
        probability: 0.01,
      );
      final tree = DecisionTree.fromNodes([root, c1]);

      // Provide custom PruningConfig where minProbability > 0.01 (e.g. 0.05) to force pruning
      final customPruning = PruningConfig(
        minProbability: 0.05,
        minScore: -1.0,
        beamWidth: 3,
        maxDepth: 4,
        maxNodeLimit: 100,
      );

      final result = RuntimePipeline.runPipeline(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: customPruning,
        traversalConfig: traversalConfig,
        enableDebug: true,
      );

      expect(result.runtimeState, equals(RuntimeState.fallback.name));
      expect(result.wasFallback, isTrue);
      expect(result.bestPath.nodeIds, equals(['root']));
    });

    test('should fallback to root path when traversal fails to find valid path',
        () {
      // If we have an empty tree or root-only tree, traversal returns root
      const root = DecisionNode.constant(id: 'root', childIds: []);
      final tree = DecisionTree.fromNodes([root]);

      final result = RuntimePipeline.runPipeline(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
        enableDebug: true,
      );

      expect(result.runtimeState, equals(RuntimeState.completed.name));
      expect(result.bestPath.nodeIds, equals(['root']));
      expect(result.wasFallback, isFalse);
    });
  });
}
