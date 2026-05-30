import 'dart:io';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('Explainability Regression and Determinism Tests', () {
    late final String validJsonStr;
    late final ReplaySession session;

    setUpAll(() {
      validJsonStr = File('test/fixtures/replay/valid_debug_snapshot.json')
          .readAsStringSync()
          .trim();
      session = ReplayLoader.loadCanonicalJson(validJsonStr);
    });

    test('generate identical explanation 300+ times and assert byte-identity',
        () {
      final initialReport = BranchIQExplainer.explain(session);
      final initialCanonicalJson = initialReport.toCanonicalJson();
      final initialMarkdown = initialReport.toMarkdown();

      for (int i = 0; i < 350; i++) {
        final report = BranchIQExplainer.explain(session);
        final canonicalJson = report.toCanonicalJson();
        final markdown = report.toMarkdown();

        // Strict byte-identity checks
        expect(canonicalJson, equals(initialCanonicalJson));
        expect(markdown, equals(initialMarkdown));
      }
    });

    test(
        'generate identical path comparison 300+ times and assert byte-identity',
        () {
      final selectedPath = ['root', 'child1'];
      final rejectedPath = ['root', 'child2'];

      final initialComparison = BranchIQExplainer.comparePaths(
        session: session,
        selectedPath: selectedPath,
        rejectedPath: rejectedPath,
      );
      final initialCanonicalJson = initialComparison.toCanonicalJson();
      final initialMarkdown = initialComparison.toMarkdown();

      for (int i = 0; i < 350; i++) {
        final comparison = BranchIQExplainer.comparePaths(
          session: session,
          selectedPath: selectedPath,
          rejectedPath: rejectedPath,
        );
        final canonicalJson = comparison.toCanonicalJson();
        final markdown = comparison.toMarkdown();

        // Strict byte-identity checks
        expect(canonicalJson, equals(initialCanonicalJson));
        expect(markdown, equals(initialMarkdown));
      }
    });
  });
}
