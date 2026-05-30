import 'dart:convert';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('DecisionComparison Tests', () {
    test('computes path difference metrics correctly', () {
      const comparison = DecisionComparison(
        selectedPath: ['root', 'approve', 'auto'],
        rejectedPath: ['root', 'reject'],
        selectedUtility: 0.9500,
        rejectedUtility: 0.4500,
        utilityDelta: 0.5000,
        selectedLength: 3,
        rejectedLength: 2,
        lengthDelta: 1,
        scoreDifferences: {'root': 0.0},
        confidenceDifferences: {'root': 0.0},
        prunedInRejectedOnly: ['reject'],
        pruningDifferences: ['Node "reject" was pruned due to low confidence.'],
      );

      expect(comparison.selectedPath, equals(['root', 'approve', 'auto']));
      expect(comparison.rejectedPath, equals(['root', 'reject']));
      expect(comparison.selectedUtility, equals(0.9500));
      expect(comparison.rejectedUtility, equals(0.4500));
      expect(comparison.utilityDelta, equals(0.5000));
      expect(comparison.selectedLength, equals(3));
      expect(comparison.rejectedLength, equals(2));
      expect(comparison.lengthDelta, equals(1));
      expect(comparison.prunedInRejectedOnly, equals(['reject']));
      expect(comparison.pruningDifferences,
          equals(['Node "reject" was pruned due to low confidence.']));
    });

    test('serializes to stable canonical JSON', () {
      const comparison = DecisionComparison(
        selectedPath: ['root', 'a'],
        rejectedPath: ['root', 'b'],
        selectedUtility: 0.9,
        rejectedUtility: 0.8,
        utilityDelta: 0.1,
        selectedLength: 2,
        rejectedLength: 2,
        lengthDelta: 0,
        scoreDifferences: {'root': 0.0},
        confidenceDifferences: {'root': 0.0},
        prunedInRejectedOnly: ['b'],
        pruningDifferences: ['Node "b" pruned.'],
      );

      final jsonMap = comparison.toJson();
      expect(jsonMap['selectedUtility'], equals(0.9));
      expect(jsonMap['rejectedUtility'], equals(0.8));
      expect(jsonMap['utilityDelta'], equals(0.1));

      final canonicalStr = comparison.toCanonicalJson();
      final decoded = jsonDecode(canonicalStr) as Map<String, dynamic>;
      final keys = decoded.keys.toList();
      final sortedKeys = List<String>.from(keys)..sort();
      expect(keys, equals(sortedKeys));
    });

    test('exports to stable structured markdown', () {
      const comparison = DecisionComparison(
        selectedPath: ['root', 'approve'],
        rejectedPath: ['root', 'reject'],
        selectedUtility: 0.9500,
        rejectedUtility: 0.4000,
        utilityDelta: 0.5500,
        selectedLength: 2,
        rejectedLength: 2,
        lengthDelta: 0,
        scoreDifferences: {'root': 0.0},
        confidenceDifferences: {'root': 0.0},
        prunedInRejectedOnly: ['reject'],
        pruningDifferences: ['Node "reject" was pruned due to cost threshold.'],
      );

      final markdown = comparison.toMarkdown();
      expect(markdown, contains('# Decision Path Comparison'));
      expect(markdown, contains('## Path Summary'));
      expect(markdown, contains('## Utility & Length Deltas'));
      expect(
          markdown,
          contains(
              'Selected path utility exceeded rejected path utility by 0.5500.'));
      expect(
          markdown,
          contains(
              'Selected path has 2 nodes, rejected path has 2 nodes (delta: 0).'));
      expect(markdown, contains('## Score Differences'));
      expect(markdown, contains('## Confidence Differences'));
      expect(markdown, contains('## Pruning Analysis'));
      expect(markdown,
          contains('- Node "reject" was pruned due to cost threshold.'));
    });
  });
}
