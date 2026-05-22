import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('PruningConfig Hardening Tests', () {
    test('Constructor accepts valid ranges', () {
      final config = PruningConfig(
        minProbability: 0.1,
        minScore: -0.5,
        beamWidth: 5,
        maxDepth: 10,
        maxNodeLimit: 500,
      );
      expect(config.minProbability, equals(0.1));
      expect(config.minScore, equals(-0.5));
      expect(config.beamWidth, equals(5));
      expect(config.maxDepth, equals(10));
      expect(config.maxNodeLimit, equals(500));
    });

    test('Throws on invalid ranges', () {
      // minProbability bounds
      expect(
          () => PruningConfig(
              minProbability: -0.1,
              minScore: 0.0,
              beamWidth: 1,
              maxDepth: 4,
              maxNodeLimit: 100),
          throwsArgumentError);
      expect(
          () => PruningConfig(
              minProbability: 1.1,
              minScore: 0.0,
              beamWidth: 1,
              maxDepth: 4,
              maxNodeLimit: 100),
          throwsArgumentError);

      // minScore bounds
      expect(
          () => PruningConfig(
              minProbability: 0.0,
              minScore: -1.1,
              beamWidth: 1,
              maxDepth: 4,
              maxNodeLimit: 100),
          throwsArgumentError);
      expect(
          () => PruningConfig(
              minProbability: 0.0,
              minScore: 1.1,
              beamWidth: 1,
              maxDepth: 4,
              maxNodeLimit: 100),
          throwsArgumentError);

      // beamWidth bounds
      expect(
          () => PruningConfig(
              minProbability: 0.0,
              minScore: 0.0,
              beamWidth: 0,
              maxDepth: 4,
              maxNodeLimit: 100),
          throwsArgumentError);

      // maxDepth bounds
      expect(
          () => PruningConfig(
              minProbability: 0.0,
              minScore: 0.0,
              beamWidth: 1,
              maxDepth: 0,
              maxNodeLimit: 100),
          throwsArgumentError);
      expect(
          () => PruningConfig(
              minProbability: 0.0,
              minScore: 0.0,
              beamWidth: 1,
              maxDepth: 13,
              maxNodeLimit: 100),
          throwsArgumentError);

      // maxNodeLimit bounds
      expect(
          () => PruningConfig(
              minProbability: 0.0,
              minScore: 0.0,
              beamWidth: 1,
              maxDepth: 4,
              maxNodeLimit: 0),
          throwsArgumentError);
      expect(
          () => PruningConfig(
              minProbability: 0.0,
              minScore: 0.0,
              beamWidth: 1,
              maxDepth: 4,
              maxNodeLimit: 1001),
          throwsArgumentError);
    });

    test('defaultSettings factory constructor', () {
      final config = PruningConfig.defaultSettings();
      expect(config.minProbability, equals(0.0));
      expect(config.minScore, equals(-1.0));
      expect(config.beamWidth, equals(3));
      expect(config.maxDepth, equals(4));
      expect(config.maxNodeLimit, equals(100));
    });

    test('JSON roundtrip serialization', () {
      final original = PruningConfig(
        minProbability: 0.5,
        minScore: -0.2,
        beamWidth: 8,
        maxDepth: 11,
        maxNodeLimit: 950,
      );
      final json = original.toJson();
      final reconstructed = PruningConfig.fromJson(json);

      expect(reconstructed.minProbability, equals(original.minProbability));
      expect(reconstructed.minScore, equals(original.minScore));
      expect(reconstructed.beamWidth, equals(original.beamWidth));
      expect(reconstructed.maxDepth, equals(original.maxDepth));
      expect(reconstructed.maxNodeLimit, equals(original.maxNodeLimit));
    });
  });
}
