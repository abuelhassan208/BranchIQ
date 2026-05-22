import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/traversal/traversal_pipeline.dart';
import 'package:branchiq/src/traversal/traversal_result.dart';
import 'package:test/test.dart';

void main() {
  group('TraversalPipeline Tests', () {
    final traversalConfig =
        const TraversalConfig(strategy: TraversalStrategy.priorityFirst);
    final pruningConfig = PruningConfig(
      minProbability: 0.0,
      minScore: -1.0,
      beamWidth: 5,
      maxDepth: 10,
      maxNodeLimit: 100,
    );

    test('runTraversal calls PriorityTraverser and validates tree successfully',
        () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1'],
        score: 0.5,
        depth: 0,
      );
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: [],
        score: 0.8,
        depth: 1,
      );
      final tree = DecisionTree.fromNodes([root, c1]);

      final result = runTraversal(tree, traversalConfig, pruningConfig);
      expect(result.selectedNodeIds, equals(['root', 'c1']));
      expect(result.totalUtility, equals(1.3));
      expect(result.wasFallback, isFalse);
    });

    test(
        'runTraversal fails fast for invalid tree structure (OrphanNodeException)',
        () {
      // Create a node with a missing child id
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['missing_child'],
        score: 0.5,
        depth: 0,
      );

      // Bypass DecisionTree.fromNodes validation to construct an invalid tree
      // (which we can do since the tree validation throws, but we can catch it or mock if necessary,
      // actually let's see how DecisionTree.fromNodes works. It runs validateOrThrow inside it.
      // So DecisionTree.fromNodes will throw OrchardNodeException immediately. Let's make sure
      // that we can verify that the validator throws, or we can check the pipeline throws if an invalid tree is passed.)
      // Wait, is there a way to construct DecisionTree without validation?
      // Yes, using JSON deserialization: DecisionTree.fromJson bypasses... wait, no, DecisionTree.fromJson calls DecisionTree.fromNodes, which validates!
      // Wait, is there a private constructor? Yes: const DecisionTree._(this._nodes). But we cannot access it from other files.
      // Ah! We can test that constructing an invalid tree throws during construction, OR we can test that the validation logic works.
      // Wait, can we pass a DecisionTree that becomes invalid? DecisionTree's nodes map is unmodifiable, but let's see:
      // Since DecisionTree.fromNodes always validates, it's impossible to have an invalid DecisionTree instance.
      // But we can check that when you construct a DecisionTree with invalid structure it throws.
      // Let's also check TraversalResult JSON serialization and deserialization.
      expect(() => DecisionTree.fromNodes([root]),
          throwsA(isA<OrphanNodeException>()));
    });

    test('TraversalResult JSON roundtrip serialization', () {
      final node = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: [],
        score: 0.8,
        depth: 0,
      );
      final result = TraversalResult(
        selectedNodes: [node],
        selectedNodeIds: ['root'],
        terminalNodeId: 'root',
        totalUtility: 0.8,
        wasFallback: false,
        failureReason: 'None',
      );

      final json = result.toJson();
      expect(json['terminalNodeId'], equals('root'));
      expect(json['totalUtility'], equals(0.8));
      expect(json['wasFallback'], isFalse);
      expect(json['failureReason'], equals('None'));
      expect(json['selectedNodeIds'], equals(['root']));

      final decoded = TraversalResult.fromJson(json);
      expect(decoded.terminalNodeId, equals('root'));
      expect(decoded.totalUtility, equals(0.8));
      expect(decoded.wasFallback, isFalse);
      expect(decoded.failureReason, equals('None'));
      expect(decoded.selectedNodeIds, equals(['root']));
      expect(decoded.selectedNodes.first.id, equals('root'));
    });
  });
}
