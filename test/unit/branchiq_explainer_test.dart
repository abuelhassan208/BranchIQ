import 'dart:io';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('BranchIQExplainer Tests', () {
    late final String validJsonStr;

    setUpAll(() {
      validJsonStr = File('test/fixtures/replay/valid_debug_snapshot.json')
          .readAsStringSync()
          .trim();
    });

    test('explain session path, pruning, and utility', () {
      final session = ReplayLoader.loadCanonicalJson(validJsonStr);
      final report = BranchIQExplainer.explain(session);

      expect(report.rootId, equals('root'));
      expect(report.selectedPath, equals(['root', 'child1']));
      expect(report.rejectedNodeIds, equals(['child2']));

      // NodeExplanation details verification
      final rootExp = report.nodeExplanations['root']!;
      expect(rootExp.nodeId, equals('root'));
      expect(rootExp.score, equals(1.0000));
      expect(rootExp.selected, isTrue);
      expect(rootExp.terminal, isFalse); // Root has child1, child2

      final child1Exp = report.nodeExplanations['child1']!;
      expect(child1Exp.nodeId, equals('child1'));
      expect(child1Exp.score, equals(0.9250));
      expect(child1Exp.selected, isTrue);
      expect(child1Exp.terminal, isTrue);

      final child2Exp = report.nodeExplanations['child2']!;
      expect(child2Exp.nodeId, equals('child2'));
      expect(child2Exp.score, equals(0.7000));
      expect(child2Exp.selected, isFalse);
      expect(child2Exp.pruningStatus, equals('pruned'));
      expect(child2Exp.terminal, isTrue);
    });

    test('compare path decisions and utility deltas', () {
      final session = ReplayLoader.loadCanonicalJson(validJsonStr);
      final comparison = BranchIQExplainer.comparePaths(
        session: session,
        selectedPath: ['root', 'child1'],
        rejectedPath: ['root', 'child2'],
      );

      expect(comparison.selectedUtility, equals(0.9250));
      expect(comparison.rejectedUtility, equals(0.7000));
      expect(comparison.utilityDelta, closeTo(0.2250, 0.0001));
      expect(comparison.selectedLength, equals(2));
      expect(comparison.rejectedLength, equals(2));
      expect(comparison.lengthDelta, equals(0));
      expect(comparison.prunedInRejectedOnly, equals(['child2']));
    });

    test('reject invalid path arguments during comparison', () {
      final session = ReplayLoader.loadCanonicalJson(validJsonStr);

      expect(
        () => BranchIQExplainer.comparePaths(
          session: session,
          selectedPath: [],
          rejectedPath: ['root'],
        ),
        throwsA(isA<ExplanationException>()),
      );

      expect(
        () => BranchIQExplainer.comparePaths(
          session: session,
          selectedPath: ['root'],
          rejectedPath: ['non_existent_node'],
        ),
        throwsA(isA<ExplanationException>()),
      );
    });
  });
}
