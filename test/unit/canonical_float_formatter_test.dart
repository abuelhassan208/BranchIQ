import 'package:branchiq/src/canonicalization/canonical_float_formatter.dart';
import 'package:branchiq/src/canonicalization/canonicalization_exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('CanonicalFloatFormatter Unit Tests', () {
    test('Formats finite doubles to exactly 4 decimal places with rounding',
        () {
      expect(CanonicalFloatFormatter.format(0.5), equals('0.5000'));
      expect(CanonicalFloatFormatter.format(1.0), equals('1.0000'));
      expect(CanonicalFloatFormatter.format(0.0), equals('0.0000'));
      expect(CanonicalFloatFormatter.format(123.45678), equals('123.4568'));
      expect(CanonicalFloatFormatter.format(-123.45678), equals('-123.4568'));
      expect(CanonicalFloatFormatter.format(0.00001), equals('0.0000'));
      expect(CanonicalFloatFormatter.format(0.00005), equals('0.0001'));
    });

    test('Normalizes negative zero to positive 0.0000', () {
      expect(CanonicalFloatFormatter.format(-0.0), equals('0.0000'));
    });

    test('Formats infinity representations correctly', () {
      expect(
          CanonicalFloatFormatter.format(double.infinity), equals('INFINITY'));
      expect(CanonicalFloatFormatter.format(double.negativeInfinity),
          equals('-INFINITY'));
    });

    test('Rejects NaN with CanonicalFloatFormatException', () {
      expect(
        () => CanonicalFloatFormatter.format(double.nan),
        throwsA(isA<CanonicalFloatFormatException>()),
      );
    });

    test('Validates canonical float strings correctly', () {
      expect(CanonicalFloatFormatter.isCanonical('0.5000'), isTrue);
      expect(CanonicalFloatFormatter.isCanonical('1.0000'), isTrue);
      expect(CanonicalFloatFormatter.isCanonical('0.0000'), isTrue);
      expect(CanonicalFloatFormatter.isCanonical('-123.4568'), isTrue);
      expect(CanonicalFloatFormatter.isCanonical('INFINITY'), isTrue);
      expect(CanonicalFloatFormatter.isCanonical('-INFINITY'), isTrue);

      // Non-canonical formats
      expect(CanonicalFloatFormatter.isCanonical('0.5'), isFalse);
      expect(CanonicalFloatFormatter.isCanonical('1'), isFalse);
      expect(CanonicalFloatFormatter.isCanonical('-0.0000'),
          isFalse); // Negative zero normalized
      expect(CanonicalFloatFormatter.isCanonical('01.0000'),
          isFalse); // Leading zero on whole part
      expect(CanonicalFloatFormatter.isCanonical('1.00000'),
          isFalse); // Extra trailing zero
      expect(CanonicalFloatFormatter.isCanonical('NaN'), isFalse);
      expect(CanonicalFloatFormatter.isCanonical('abc'), isFalse);
    });
  });
}
