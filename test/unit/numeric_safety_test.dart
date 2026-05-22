import 'package:branchiq/src/math/numeric_safety.dart';
import 'package:test/test.dart';

void main() {
  group('Numeric Safety Tests', () {
    test('defaultEpsilon constant should be 1e-9', () {
      expect(defaultEpsilon, equals(1e-9));
    });

    test('isFiniteNumber should identify valid and invalid double states', () {
      expect(isFiniteNumber(0.0), isTrue);
      expect(isFiniteNumber(1.2345), isTrue);
      expect(isFiniteNumber(-999.9), isTrue);
      expect(isFiniteNumber(double.maxFinite), isTrue);
      expect(isFiniteNumber(double.minPositive), isTrue);

      expect(isFiniteNumber(double.nan), isFalse);
      expect(isFiniteNumber(double.infinity), isFalse);
      expect(isFiniteNumber(double.negativeInfinity), isFalse);
    });

    test(
        'sanitizeDouble should normalize invalid inputs and preserve valid inputs',
        () {
      expect(sanitizeDouble(5.5), equals(5.5));
      expect(sanitizeDouble(-2.3), equals(-2.3));

      // NaN fallback
      expect(sanitizeDouble(double.nan), equals(-1.0));
      expect(sanitizeDouble(double.nan, fallback: 4.2), equals(4.2));

      // Infinity states
      expect(sanitizeDouble(double.infinity), equals(1.0));
      expect(sanitizeDouble(double.negativeInfinity), equals(-1.0));
    });

    test('safeDivide should compute division safely under all conditions', () {
      // Normal division
      expect(safeDivide(10.0, 2.0), equals(5.0));

      // Division by zero - stabilizer epsilon should be used
      expect(safeDivide(5.0, 0.0), equals(5.0 / defaultEpsilon));
      expect(safeDivide(5.0, 0.0, epsilon: 1e-4), equals(5.0 / 1e-4));

      // NaN and Infinity values
      expect(safeDivide(double.nan, 2.0), equals(0.0));
      expect(safeDivide(10.0, double.nan), equals(10.0 / defaultEpsilon));
      expect(safeDivide(double.infinity, 2.0), equals(0.5));
      expect(safeDivide(10.0, double.infinity), equals(10.0));
    });

    test('safeClamp should strictly restrict values within bounds', () {
      expect(safeClamp(5.0, 0.0, 10.0), equals(5.0));
      expect(safeClamp(-2.0, 0.0, 10.0), equals(0.0));
      expect(safeClamp(12.0, 0.0, 10.0), equals(10.0));

      // NaN fallback to lower bound
      expect(safeClamp(double.nan, 2.0, 8.0), equals(2.0));

      // Infinities sanitization and clamp
      expect(safeClamp(double.infinity, -5.0, 5.0), equals(1.0));
      expect(safeClamp(double.negativeInfinity, -5.0, 5.0), equals(-1.0));
    });
  });
}
