import 'package:branchiq/src/internal/execution_budget.dart';
import 'package:test/test.dart';

void main() {
  group('ExecutionBudget Tests', () {
    test('initializes with default values', () {
      const budget = ExecutionBudget(maxIterations: 100, maxVisitedNodes: 50);
      expect(budget.maxIterations, equals(100));
      expect(budget.currentIterations, equals(0));
      expect(budget.maxVisitedNodes, equals(50));
      expect(budget.currentVisitedNodes, equals(0));
      expect(budget.isExhausted(), isFalse);
    });

    test('increments iterations immutably', () {
      const budget1 = ExecutionBudget(maxIterations: 10, maxVisitedNodes: 5);
      final budget2 = budget1.incrementIterations();

      expect(budget1.currentIterations, equals(0));
      expect(budget2.currentIterations, equals(1));
      expect(budget2.maxIterations, equals(10));
      expect(budget2.maxVisitedNodes, equals(5));
      expect(budget2.currentVisitedNodes, equals(0));
    });

    test('increments visited nodes immutably', () {
      const budget1 = ExecutionBudget(maxIterations: 10, maxVisitedNodes: 5);
      final budget2 = budget1.incrementVisitedNodes();

      expect(budget1.currentVisitedNodes, equals(0));
      expect(budget2.currentVisitedNodes, equals(1));
      expect(budget2.maxIterations, equals(10));
      expect(budget2.maxVisitedNodes, equals(5));
      expect(budget2.currentIterations, equals(0));
    });

    test('isExhausted returns true when iterations exceed maxIterations', () {
      var budget = const ExecutionBudget(maxIterations: 2, maxVisitedNodes: 5);
      expect(budget.isExhausted(), isFalse);

      budget = budget.incrementIterations(); // 1
      expect(budget.isExhausted(), isFalse);

      budget = budget.incrementIterations(); // 2
      expect(budget.isExhausted(), isFalse);

      budget = budget.incrementIterations(); // 3
      expect(budget.isExhausted(), isTrue);
    });

    test('isExhausted returns true when visited nodes exceed maxVisitedNodes',
        () {
      var budget = const ExecutionBudget(maxIterations: 5, maxVisitedNodes: 2);
      expect(budget.isExhausted(), isFalse);

      budget = budget.incrementVisitedNodes(); // 1
      expect(budget.isExhausted(), isFalse);

      budget = budget.incrementVisitedNodes(); // 2
      expect(budget.isExhausted(), isFalse);

      budget = budget.incrementVisitedNodes(); // 3
      expect(budget.isExhausted(), isTrue);
    });
  });
}
