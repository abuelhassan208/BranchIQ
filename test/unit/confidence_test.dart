import 'dart:math' as math;
import 'package:branchiq/src/math/confidence.dart';
import 'package:test/test.dart';

void main() {
  group('Confidence Propagation Tests', () {
    test('calculateDecayCoefficient should compute exponential decay', () {
      // depth = 0 -> gamma0 * exp(0) = gamma0
      expect(calculateDecayCoefficient(0), closeTo(0.90, 1e-9));

      // depth = 2 -> 0.90 * exp(-0.1 * 2) = 0.90 * exp(-0.2)
      final expectedDecay = 0.90 * math.exp(-0.2);
      expect(calculateDecayCoefficient(2), closeTo(expectedDecay, 1e-9));

      // negative depth should be clamped to 0
      expect(calculateDecayCoefficient(-5), closeTo(0.90, 1e-9));

      // Custom lambda and gamma0
      expect(calculateDecayCoefficient(1, gamma0: 0.8, lambda: 0.5),
          closeTo(0.8 * math.exp(-0.5), 1e-9));
    });

    test(
        'propagateConfidence should multiply parent confidence by decay coefficient',
        () {
      // parentConfidence = 1.0, depth = 0 -> 1.0 * 0.90 = 0.90
      expect(propagateConfidence(1.0, 0), closeTo(0.90, 1e-9));

      // parentConfidence = 0.5, depth = 1 -> 0.5 * 0.90 * math.exp(-0.1)
      final expected = 0.5 * 0.90 * math.exp(-0.1);
      expect(propagateConfidence(0.5, 1), closeTo(expected, 1e-9));

      // Out of bounds / invalid parent confidence should clamp first
      expect(propagateConfidence(1.5, 0), closeTo(0.90, 1e-9));
      expect(propagateConfidence(-0.5, 0), equals(0.0));
    });

    test('dampenConfidence should scale confidence by a factor', () {
      expect(dampenConfidence(0.8, 0.5), closeTo(0.4, 1e-9));

      // damping factor clamp checks
      expect(dampenConfidence(0.8, 1.2), closeTo(0.8, 1e-9));
      expect(dampenConfidence(0.8, -0.1), equals(0.0));

      // confidence clamp checks
      expect(dampenConfidence(1.5, 0.5), closeTo(0.5, 1e-9));
    });

    test('applyConfidence should scale utility score', () {
      expect(applyConfidence(0.8, 0.5), closeTo(0.4, 1e-9));
      expect(applyConfidence(-0.6, 0.5), closeTo(-0.3, 1e-9));

      // edge cases and clamping
      expect(applyConfidence(1.2, 0.5),
          closeTo(0.5, 1e-9)); // score clamps to 1.0, 1.0 * 0.5 = 0.5
      expect(applyConfidence(-1.5, 0.5),
          closeTo(-0.5, 1e-9)); // score clamps to -1.0, -1.0 * 0.5 = -0.5
      expect(applyConfidence(0.8, 1.5),
          closeTo(0.8, 1e-9)); // confidence clamps to 1.0, 0.8 * 1.0 = 0.8
    });
  });
}
