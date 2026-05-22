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
  group('Pathological Tree Defense Integration Tests', () {
    final scoringConfig = ScoringConfig.balanced();
    final pruningConfig = PruningConfig.defaultSettings();
    const traversalConfig = TraversalConfig();

    test('rejects extremely deep chains (depth > 12)', () {
      final nodes = <DecisionNode>[];
      // Create a chain of depth 15
      for (int i = 1; i <= 15; i++) {
        nodes.add(
          DecisionNode.constant(
            id: 'node_$i',
            parentId: i == 1 ? 'root' : 'node_${i - 1}',
            childIds: i == 15 ? const [] : ['node_${i + 1}'],
            depth: i,
          ),
        );
      }
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['node_1'],
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
      expect(result.errorMessage, contains('limit of 12 levels exceeded'));
    });

    test('rejects excessively wide branching (child count > 10)', () {
      final childIds = List.generate(20, (i) => 'child_$i');
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
      expect(result.errorMessage, contains('exceeds the limit of 10'));
    });

    test('detects and rejects cyclic graphs bypass attempts', () {
      // Create a cycle: root -> c1 -> c2 -> c1
      // c1 lists c2 as child. c2 lists c1 as child.
      const root = DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1'],
        depth: 0,
      );
      const c1 = DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: ['c2'],
        depth: 1,
      );
      const c2 = DecisionNode.constant(
        id: 'c2',
        parentId: 'c1',
        childIds: ['c1'], // Cycle loop back to c1
        depth: 2,
      );

      // Bypass constructor checks using mock or directly constructing with invalid structure
      // Let's test if it throws on validation check
      final nodes = {'root': root, 'c1': c1, 'c2': c2};
      expect(
        () => DecisionTree.fromNodes(nodes.values.toList()),
        throwsA(isA<CycleDetectedException>()),
      );

      final result = RuntimePipeline.runPipeline(
        tree: InvalidTreeMock(nodes),
        scoringConfig: scoringConfig,
        pruningConfig: pruningConfig,
        traversalConfig: traversalConfig,
      );

      expect(result.runtimeState, equals(RuntimeState.failed.name));
      expect(result.errorMessage, contains('CycleDetectedException'));
    });

    test('rejects empty trees', () {
      expect(
        () => DecisionTree.fromNodes(const []),
        throwsA(isA<InvalidTreeException>().having((e) => e.message, 'message',
            contains('Tree must contain at least one node.'))),
      );
    });
  });
}
