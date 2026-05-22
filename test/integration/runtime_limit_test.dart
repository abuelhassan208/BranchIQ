import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/internal/execution_budget.dart';
import 'package:branchiq/src/internal/runtime_guards.dart';
import 'package:branchiq/src/runtime/runtime_pipeline.dart';
import 'package:branchiq/src/runtime/runtime_state.dart';
import 'package:branchiq/src/traversal/priority_traverser.dart';
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
  group('Runtime Limit Integration Tests', () {
    final scoringConfig = ScoringConfig.balanced();
    final pruningConfig = PruningConfig.defaultSettings();
    const traversalConfig = TraversalConfig();

    test(
        'Node count exceeds defaultMaxNodes throws limit exceeded during pipeline run',
        () {
      // Build a tree with 1001 nodes (root + 1000 children)
      final nodes = <DecisionNode>[];
      final childIds = <String>[];
      for (int i = 1; i <= 1001; i++) {
        childIds.add('c$i');
        nodes.add(
          DecisionNode.constant(
            id: 'c$i',
            parentId: 'root',
            childIds: const [],
            depth: 1,
          ),
        );
      }
      final root = DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: childIds,
        depth: 0,
      );
      nodes.add(root);

      final tree = DecisionTree.fromNodes(nodes);

      final result = RuntimePipeline.runPipeline(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
      );

      expect(result.runtimeState, equals(RuntimeState.failed.name));
      expect(result.errorMessage, contains('Node count limit exceeded'));
      expect(result.errorMessage, contains('1002')); // 1001 children + 1 root
    });

    test(
        'Node child count exceeds defaultMaxChildrenPerNode throws limit exceeded during pipeline run',
        () {
      // defaultMaxChildrenPerNode is 10. Let's create a node with 11 children.
      final childIds = List.generate(11, (i) => 'c$i');
      final nodes = <DecisionNode>[];
      for (final cid in childIds) {
        nodes.add(
          DecisionNode.constant(
            id: cid,
            parentId: 'root',
            childIds: const [],
            depth: 1,
          ),
        );
      }
      final root = DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: childIds,
        depth: 0,
      );
      nodes.add(root);

      final tree = DecisionTree.fromNodes(nodes);

      final result = RuntimePipeline.runPipeline(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
      );

      expect(result.runtimeState, equals(RuntimeState.failed.name));
      expect(result.errorMessage, contains('Child count limit exceeded'));
      expect(result.errorMessage, contains('node has 11 children'));
    });

    test(
        'Node depth exceeds defaultMaxDepth throws limit exceeded during pipeline run',
        () {
      // defaultMaxDepth is 12. Let's create a chain of depth 13.
      final nodes = <DecisionNode>[];
      for (int d = 1; d <= 13; d++) {
        nodes.add(
          DecisionNode.constant(
            id: 'n$d',
            parentId: d == 1 ? 'root' : 'n${d - 1}',
            childIds: d == 13 ? const [] : ['n${d + 1}'],
            depth: d,
          ),
        );
      }
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['n1'],
        depth: 0,
      );
      nodes.add(root);

      final tree = InvalidTreeMock({for (final node in nodes) node.id: node});

      final result = RuntimePipeline.runPipeline(
        tree: tree,
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
      );

      expect(result.runtimeState, equals(RuntimeState.failed.name));
      // Can be either from TreeValidator (max 12 levels) or RuntimeGuards
      expect(
        result.errorMessage,
        anyOf(
          contains('Max depth limit of 12 levels exceeded'),
          contains('Depth limit exceeded'),
        ),
      );
    });

    test(
        'Traversal iterations budget exceeded throws TraversalBudgetExceededException during traversal',
        () {
      // Setup a small tree of depth 3 to traverse
      const root = DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1'],
        depth: 0,
        score: 1.0,
      );
      const c1 = DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: ['c2'],
        depth: 1,
        score: 1.0,
      );
      const c2 = DecisionNode.constant(
        id: 'c2',
        parentId: 'c1',
        childIds: [],
        depth: 2,
        score: 1.0,
      );

      final tree = DecisionTree.fromNodes([root, c1, c2]);

      // Execution budget with maxIterations = 1, while tree needs at least 3 iterations to traverse completely
      final budget = const ExecutionBudget(
        maxIterations: 1,
        maxVisitedNodes: 100,
      );

      expect(
        () => PriorityTraverser.traverse(
          tree,
          traversalConfig,
          pruningConfig,
          budget: budget,
        ),
        throwsA(
          isA<TraversalBudgetExceededException>().having(
            (e) => e.message,
            'message',
            contains('Traversal iterations budget exceeded'),
          ),
        ),
      );
    });
  });
}
