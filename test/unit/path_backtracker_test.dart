import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/traversal/path_backtracker.dart';
import 'package:test/test.dart';

void main() {
  group('PathBacktracker Tests', () {
    test('Handles empty or invalid terminal node ID gracefully', () {
      final result = PathBacktracker.backtrack('', {});
      expect(result.path, isEmpty);
      expect(result.failureReason,
          contains('Terminal node ID must not be empty.'));
    });

    test('Reconstructs path from terminal node to root', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: ['c1'],
        score: 1.0,
        depth: 0,
      );
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'root',
        childIds: ['c2'],
        score: 0.5,
        depth: 1,
      );
      final c2 = const DecisionNode.constant(
        id: 'c2',
        parentId: 'c1',
        childIds: [],
        score: 0.8,
        depth: 2,
      );

      final registry = {
        'root': root,
        'c1': c1,
        'c2': c2,
      };

      final result = PathBacktracker.backtrack('c2', registry);
      expect(result.failureReason, isNull);
      expect(
          result.path.map((n) => n.id).toList(), equals(['root', 'c1', 'c2']));
    });

    test('Handles root-only tree', () {
      final root = const DecisionNode.constant(
        id: 'root',
        parentId: null,
        childIds: [],
        score: 1.0,
        depth: 0,
      );

      final registry = {
        'root': root,
      };

      final result = PathBacktracker.backtrack('root', registry);
      expect(result.failureReason, isNull);
      expect(result.path.map((n) => n.id).toList(), equals(['root']));
    });

    test('Detects backtracking cycle loop safely without infinite recursion',
        () {
      // Loop: c1 -> c2 -> c1
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'c2',
        childIds: ['c2'],
        score: 0.5,
        depth: 1,
      );
      final c2 = const DecisionNode.constant(
        id: 'c2',
        parentId: 'c1',
        childIds: ['c1'],
        score: 0.8,
        depth: 2,
      );

      final registry = {
        'c1': c1,
        'c2': c2,
      };

      final result = PathBacktracker.backtrack('c2', registry);
      expect(result.path, isEmpty);
      expect(result.failureReason,
          contains('Backtracking cycle detected at node'));
    });

    test('Detects broken parent chain when a parent is missing from registry',
        () {
      final c1 = const DecisionNode.constant(
        id: 'c1',
        parentId: 'missing_parent',
        childIds: [],
        score: 0.5,
        depth: 1,
      );

      final registry = {
        'c1': c1,
      };

      final result = PathBacktracker.backtrack('c1', registry);
      expect(result.path, isEmpty);
      expect(result.failureReason,
          contains('Broken parent chain: node "missing_parent" not found'));
    });
  });
}
