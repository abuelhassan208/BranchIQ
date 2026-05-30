import 'package:branchiq/src/canonicalization/canonical_float_formatter.dart';
import 'package:branchiq/src/canonicalization/canonical_json_encoder.dart';
import 'package:branchiq/src/canonicalization/canonical_markdown_writer.dart';
import 'package:branchiq/src/canonicalization/canonicalization_exceptions.dart';
import 'package:branchiq/src/canonicalization/canonicalization_validator.dart';
import 'package:test/test.dart';

void main() {
  group('Canonical Serialization Regression Tests', () {
    test(
        'Ensures 250+ serializations of identical nested maps produce byte-identical compact outputs',
        () {
      final source = {
        'root': {
          'id': 'root',
          'score': 1.0,
          'metadata': {
            'timestamp': '2026-05-23T01:00:00Z',
            'session': 'xyz-987654',
          },
          'childIds': ['accept', 'decline', 'escalate'],
          'parameters': {
            'costCeiling': 150.0,
            'confidenceDecay': 0.95,
          }
        },
        'accept': {
          'id': 'accept',
          'score': 0.84729,
          'probability': 0.9,
          'impact': 0.8,
          'cost': 50.0,
        },
        'decline': {
          'id': 'decline',
          'score': -0.15,
          'probability': 0.1,
          'impact': -0.2,
          'cost': 10.0,
        }
      };

      final List<String> outputs = [];
      for (int i = 0; i < 300; i++) {
        final compact = CanonicalJsonEncoder.encode(source);
        outputs.add(compact);
      }

      // Assert all elements in outputs are identical to the first element
      final firstOutput = outputs.first;
      for (final output in outputs) {
        expect(output, equals(firstOutput));
      }

      // Assert validator confirms canonical structure
      expect(
          CanonicalizationValidator.isCanonicalJsonString(firstOutput), isTrue);
    });

    test(
        'Ensures 250+ markdown reports produce byte-identical markdown outputs',
        () {
      final headers = ['ID', 'Score', 'Cost', 'Status'];
      final rows = [
        ['root', '1.0000', '0.0000', 'Active'],
        ['accept', '0.8473', '50.0000', 'Approved'],
        ['decline', '-0.1500', '10.0000', 'Rejected'],
      ];

      final List<String> markdownOutputs = [];
      for (int i = 0; i < 300; i++) {
        final buffer = StringBuffer();
        buffer.write(
            CanonicalMarkdownWriter.heading(1, 'Regression Test Report'));
        buffer.write(CanonicalMarkdownWriter.bullet(
            'Generated deterministically for golden validation.'));
        buffer.write(CanonicalMarkdownWriter.table(headers, rows));
        markdownOutputs.add(buffer.toString());
      }

      final firstMarkdown = markdownOutputs.first;
      for (final md in markdownOutputs) {
        expect(md, equals(firstMarkdown));
      }

      // Check standard formatting
      expect(firstMarkdown,
          contains('| ID      | Score   | Cost    | Status   |'));
      expect(firstMarkdown,
          contains('| root    | 1.0000  | 0.0000  | Active   |'));
      expect(firstMarkdown, endsWith('\n'));
    });

    test(
        'Ensures negative zero normalization in CanonicalFloatFormatter and JSON encoding',
        () {
      expect(CanonicalFloatFormatter.format(-0.0), equals('0.0000'));
      expect(CanonicalFloatFormatter.format(0.0), equals('0.0000'));
      expect(CanonicalFloatFormatter.isCanonical('-0.0000'), isFalse);
      expect(CanonicalFloatFormatter.isCanonical('0.0000'), isTrue);

      final mapWithNegZero = {'value': -0.0};
      final compactJson = CanonicalJsonEncoder.encode(mapWithNegZero);
      expect(compactJson, equals('{"value":"0.0000"}'));
    });

    test(
        'Ensures positive/negative infinity and NaN handling in CanonicalFloatFormatter',
        () {
      expect(
          CanonicalFloatFormatter.format(double.infinity), equals('INFINITY'));
      expect(CanonicalFloatFormatter.format(double.negativeInfinity),
          equals('-INFINITY'));
      expect(CanonicalFloatFormatter.isCanonical('INFINITY'), isTrue);
      expect(CanonicalFloatFormatter.isCanonical('-INFINITY'), isTrue);

      expect(() => CanonicalFloatFormatter.format(double.nan),
          throwsA(isA<CanonicalFloatFormatException>()));
    });
  });
}
