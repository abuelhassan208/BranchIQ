import 'package:branchiq/src/internal/runtime_guards.dart';
import 'package:branchiq/src/internal/runtime_limits.dart';
import 'package:test/test.dart';

void main() {
  group('RuntimeGuards Tests', () {
    group('validateNodeCount', () {
      test('does not throw when count is within default limit', () {
        expect(
          () => RuntimeGuards.validateNodeCount(RuntimeLimits.defaultMaxNodes),
          returnsNormally,
        );
      });

      test('does not throw when count is within custom limit', () {
        expect(
          () => RuntimeGuards.validateNodeCount(50, maxNodes: 100),
          returnsNormally,
        );
      });

      test(
          'throws RuntimeLimitExceededException when count exceeds default limit',
          () {
        final expectedLimit = RuntimeLimits.defaultMaxNodes;
        final count = expectedLimit + 1;
        expect(
          () => RuntimeGuards.validateNodeCount(count),
          throwsA(
            isA<RuntimeLimitExceededException>().having(
              (e) => e.message,
              'message',
              contains(
                  'Node count limit exceeded: tree has $count nodes, which exceeds the limit of $expectedLimit.'),
            ),
          ),
        );
      });

      test(
          'throws RuntimeLimitExceededException when count exceeds custom limit',
          () {
        expect(
          () => RuntimeGuards.validateNodeCount(101, maxNodes: 100),
          throwsA(
            isA<RuntimeLimitExceededException>().having(
              (e) => e.message,
              'message',
              contains(
                  'Node count limit exceeded: tree has 101 nodes, which exceeds the limit of 100.'),
            ),
          ),
        );
      });
    });

    group('validateDepth', () {
      test('does not throw when depth is within default limit', () {
        expect(
          () => RuntimeGuards.validateDepth(RuntimeLimits.defaultMaxDepth),
          returnsNormally,
        );
      });

      test('does not throw when depth is within custom limit', () {
        expect(
          () => RuntimeGuards.validateDepth(5, maxDepth: 10),
          returnsNormally,
        );
      });

      test(
          'throws RuntimeLimitExceededException when depth exceeds default limit',
          () {
        final expectedLimit = RuntimeLimits.defaultMaxDepth;
        final depth = expectedLimit + 1;
        expect(
          () => RuntimeGuards.validateDepth(depth),
          throwsA(
            isA<RuntimeLimitExceededException>().having(
              (e) => e.message,
              'message',
              contains(
                  'Depth limit exceeded: tree depth is $depth, which exceeds the limit of $expectedLimit.'),
            ),
          ),
        );
      });

      test(
          'throws RuntimeLimitExceededException when depth exceeds custom limit',
          () {
        expect(
          () => RuntimeGuards.validateDepth(11, maxDepth: 10),
          throwsA(
            isA<RuntimeLimitExceededException>().having(
              (e) => e.message,
              'message',
              contains(
                  'Depth limit exceeded: tree depth is 11, which exceeds the limit of 10.'),
            ),
          ),
        );
      });
    });

    group('validateTraversalIterations', () {
      test('does not throw when iterations is within default limit', () {
        expect(
          () => RuntimeGuards.validateTraversalIterations(
              RuntimeLimits.defaultMaxTraversalIterations),
          returnsNormally,
        );
      });

      test('does not throw when iterations is within custom limit', () {
        expect(
          () => RuntimeGuards.validateTraversalIterations(500,
              maxIterations: 600),
          returnsNormally,
        );
      });

      test(
          'throws TraversalBudgetExceededException when iterations exceeds default limit',
          () {
        final expectedLimit = RuntimeLimits.defaultMaxTraversalIterations;
        final iterations = expectedLimit + 1;
        expect(
          () => RuntimeGuards.validateTraversalIterations(iterations),
          throwsA(
            isA<TraversalBudgetExceededException>().having(
              (e) => e.message,
              'message',
              contains(
                  'Traversal iterations budget exceeded: performed $iterations iterations, which exceeds the limit of $expectedLimit.'),
            ),
          ),
        );
      });

      test(
          'throws TraversalBudgetExceededException when iterations exceeds custom limit',
          () {
        expect(
          () => RuntimeGuards.validateTraversalIterations(601,
              maxIterations: 600),
          throwsA(
            isA<TraversalBudgetExceededException>().having(
              (e) => e.message,
              'message',
              contains(
                  'Traversal iterations budget exceeded: performed 601 iterations, which exceeds the limit of 600.'),
            ),
          ),
        );
      });
    });

    group('validateChildCount', () {
      test('does not throw when child count is within default limit', () {
        expect(
          () => RuntimeGuards.validateChildCount(
              RuntimeLimits.defaultMaxChildrenPerNode),
          returnsNormally,
        );
      });

      test('does not throw when child count is within custom limit', () {
        expect(
          () => RuntimeGuards.validateChildCount(5, maxChildren: 8),
          returnsNormally,
        );
      });

      test(
          'throws RuntimeLimitExceededException when child count exceeds default limit',
          () {
        final expectedLimit = RuntimeLimits.defaultMaxChildrenPerNode;
        final count = expectedLimit + 1;
        expect(
          () => RuntimeGuards.validateChildCount(count),
          throwsA(
            isA<RuntimeLimitExceededException>().having(
              (e) => e.message,
              'message',
              contains(
                  'Child count limit exceeded: node has $count children, which exceeds the limit of $expectedLimit.'),
            ),
          ),
        );
      });

      test(
          'throws RuntimeLimitExceededException when child count exceeds custom limit',
          () {
        expect(
          () => RuntimeGuards.validateChildCount(9, maxChildren: 8),
          throwsA(
            isA<RuntimeLimitExceededException>().having(
              (e) => e.message,
              'message',
              contains(
                  'Child count limit exceeded: node has 9 children, which exceeds the limit of 8.'),
            ),
          ),
        );
      });
    });

    group('Exception toString formatting', () {
      test('RuntimeLimitExceededException toString', () {
        const exc = RuntimeLimitExceededException('Test error');
        expect(exc.toString(),
            equals('RuntimeLimitExceededException: Test error'));
      });

      test('TraversalBudgetExceededException toString', () {
        const exc = TraversalBudgetExceededException('Test budget error');
        expect(exc.toString(),
            equals('TraversalBudgetExceededException: Test budget error'));
      });
    });
  });
}
