import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('TraversalConfig Hardening Tests', () {
    test('Constructor and default strategy', () {
      const config = TraversalConfig();
      expect(config.strategy, equals(TraversalStrategy.priorityFirst));
    });

    test('JSON roundtrip serialization', () {
      const original =
          TraversalConfig(strategy: TraversalStrategy.priorityFirst);
      final json = original.toJson();
      final reconstructed = TraversalConfig.fromJson(json);

      expect(reconstructed.strategy, equals(original.strategy));
    });

    test('fromJson handles unrecognized strategies by throwing ArgumentError',
        () {
      expect(
          () => TraversalConfig.fromJson({'strategy': 'non_existent_strategy'}),
          throwsArgumentError);

      // Null strategy should fall back to default priorityFirst
      final fallback = TraversalConfig.fromJson({});
      expect(fallback.strategy, equals(TraversalStrategy.priorityFirst));
    });
  });
}
