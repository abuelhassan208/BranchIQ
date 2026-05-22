import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('ScoringConfig Hardening Tests', () {
    test('Constructor accepts valid weights and ceiling', () {
      final config =
          ScoringConfig(wp: 0.3, wi: 0.3, wc: 0.4, costCeiling: 50.0);
      expect(config.wp, equals(0.3));
      expect(config.wi, equals(0.3));
      expect(config.wc, equals(0.4));
      expect(config.costCeiling, equals(50.0));
    });

    test('Throws on negative weights', () {
      expect(
          () => ScoringConfig(wp: -0.1, wi: 0.6, wc: 0.5, costCeiling: 100.0),
          throwsArgumentError);
      expect(
          () => ScoringConfig(wp: 0.5, wi: -0.1, wc: 0.6, costCeiling: 100.0),
          throwsArgumentError);
      expect(
          () => ScoringConfig(wp: 0.5, wi: 0.6, wc: -0.1, costCeiling: 100.0),
          throwsArgumentError);
    });

    test('Throws on weights not summing to 1.0 within tolerance', () {
      expect(
          () => ScoringConfig(wp: 0.33, wi: 0.33, wc: 0.33, costCeiling: 100.0),
          throwsArgumentError);
      // Boundary test for epsilon tolerance
      expect(
          () => ScoringConfig(
              wp: 0.333333, wi: 0.333333, wc: 0.333334, costCeiling: 100.0),
          returnsNormally);
    });

    test('Throws on negative or zero cost ceiling', () {
      expect(() => ScoringConfig(wp: 0.4, wi: 0.4, wc: 0.2, costCeiling: 0.0),
          throwsArgumentError);
      expect(() => ScoringConfig(wp: 0.4, wi: 0.4, wc: 0.2, costCeiling: -5.0),
          throwsArgumentError);
    });

    test('balanced factory constructor', () {
      final config = ScoringConfig.balanced();
      expect(config.wp, closeTo(1.0 / 3.0, 1e-6));
      expect(config.wi, closeTo(1.0 / 3.0, 1e-6));
      expect(config.wc, closeTo(1.0 / 3.0, 1e-6));
      expect(config.costCeiling, equals(1000.0));
    });

    test('JSON roundtrip serialization', () {
      final original =
          ScoringConfig(wp: 0.5, wi: 0.3, wc: 0.2, costCeiling: 250.0);
      final json = original.toJson();
      final reconstructed = ScoringConfig.fromJson(json);

      expect(reconstructed.wp, equals(original.wp));
      expect(reconstructed.wi, equals(original.wi));
      expect(reconstructed.wc, equals(original.wc));
      expect(reconstructed.costCeiling, equals(original.costCeiling));
    });

    test('fromJson missing fields throws ArgumentError', () {
      expect(() => ScoringConfig.fromJson({'wp': 0.3, 'wi': 0.3}),
          throwsArgumentError);
    });
  });
}
