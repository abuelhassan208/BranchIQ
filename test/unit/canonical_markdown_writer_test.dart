import 'package:branchiq/src/canonicalization/canonical_markdown_writer.dart';
import 'package:branchiq/src/canonicalization/canonicalization_exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('CanonicalMarkdownWriter Unit Tests', () {
    test('Generates deterministic headings with standard spacing', () {
      expect(CanonicalMarkdownWriter.heading(1, 'Title'), equals('# Title\n'));
      expect(CanonicalMarkdownWriter.heading(3, '  Subtitle  '),
          equals('### Subtitle\n'));
    });

    test('Rejects invalid heading levels with CanonicalMarkdownException', () {
      expect(
        () => CanonicalMarkdownWriter.heading(0, 'Invalid'),
        throwsA(isA<CanonicalMarkdownException>()),
      );
      expect(
        () => CanonicalMarkdownWriter.heading(7, 'Invalid'),
        throwsA(isA<CanonicalMarkdownException>()),
      );
    });

    test('Generates bullet points cleanly', () {
      expect(CanonicalMarkdownWriter.bullet('Item A'), equals('- Item A\n'));
      expect(
          CanonicalMarkdownWriter.bullet('  Item B  '), equals('- Item B\n'));
    });

    test('Generates beautifully aligned tables with correct column sizing', () {
      final headers = ['Node ID', 'Score', 'Pruning Status'];
      final rows = [
        ['root', '1.0000', 'Evaluated'],
        ['child_node_a', '0.8500', 'Pruned'],
      ];

      final table = CanonicalMarkdownWriter.table(headers, rows);

      // Verify alignment spaces:
      // Max widths:
      // Node ID column: 'child_node_a' length = 12
      // Score column: 'Pruning Status' length = 14 (so 'Pruning Status' header is 14, wait, 'Score' is 5, but '1.0000' is 6. Wait, column 2 is 'Score' header, max length is 'Score' (5) or '1.0000' (6), so max width is 6.
      // Column 3 is 'Pruning Status' header (14) or 'Evaluated' (9) or 'Pruned' (6), so max width is 14.
      // So width array: [12, 6, 14]
      final expected = '| Node ID      | Score  | Pruning Status |\n'
          '| :----------- | :----- | :------------- |\n'
          '| root         | 1.0000 | Evaluated      |\n'
          '| child_node_a | 0.8500 | Pruned         |\n';

      expect(table, equals(expected));
    });

    test('Rejects tables with mismatched column counts', () {
      final headers = ['Header A', 'Header B'];
      final rows = [
        ['Cell A1', 'Cell B1'],
        ['Cell A2'], // Mismatched cell count!
      ];

      expect(
        () => CanonicalMarkdownWriter.table(headers, rows),
        throwsA(isA<CanonicalMarkdownException>()),
      );
    });

    test(
        'Normalizes newlines, removes trailing spaces, and finishes with a single newline',
        () {
      final dirtyMarkdown =
          'Line 1  \r\nLine 2\r\n\r\nLine 3      \r\n\r\n\r\n';
      final clean = CanonicalMarkdownWriter.normalize(dirtyMarkdown);
      expect(clean, equals('Line 1\nLine 2\n\nLine 3\n'));
    });
  });
}
