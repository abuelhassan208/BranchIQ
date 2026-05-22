import 'package:branchiq/src/math/normalization.dart';
import 'package:test/test.dart';

void main() {
  group('Normalization Tests', () {
    test('normalizeCost should properly scale costs', () {
      // Normal scenarios
      expect(normalizeCost(500.0, 1000.0, epsilon: 0.0), closeTo(0.5, 1e-9));
      expect(normalizeCost(0.0, 1000.0), equals(0.0));
      expect(normalizeCost(1200.0, 1000.0), equals(1.0));

      // Negative cost should clamp to 0.0
      expect(normalizeCost(-100.0, 1000.0), equals(0.0));

      // Invalid cost ceilings (<= 0.0) should return 1.0
      expect(normalizeCost(50.0, 0.0), equals(1.0));
      expect(normalizeCost(50.0, -10.0), equals(1.0));
    });

    test('clampProbability should bound values to [0.0, 1.0]', () {
      expect(clampProbability(0.5), equals(0.5));
      expect(clampProbability(-0.1), equals(0.0));
      expect(clampProbability(1.5), equals(1.0));
      expect(clampProbability(double.nan), equals(0.0));
    });

    test('clampConfidence should bound values to [0.0, 1.0]', () {
      expect(clampConfidence(0.85), equals(0.85));
      expect(clampConfidence(-5.0), equals(0.0));
      expect(clampConfidence(2.0), equals(1.0));
      expect(clampConfidence(double.nan), equals(0.0));
    });

    test('clampImpact should bound values to [-1.0, 1.0]', () {
      expect(clampImpact(0.0), equals(0.0));
      expect(clampImpact(-0.75), equals(-0.75));
      expect(clampImpact(0.75), equals(0.75));
      expect(clampImpact(-1.5), equals(-1.0));
      expect(clampImpact(1.5), equals(1.0));
      expect(clampImpact(double.nan), equals(-1.0));
    });
  });
}
