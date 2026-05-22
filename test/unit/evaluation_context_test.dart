import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('EvaluationContext Hardening Tests', () {
    test('Constructing valid primitive context variables', () {
      final context = EvaluationContext({
        'user_age': 25,
        'has_premium': true,
        'country': 'US',
        'scores': [1.0, 2.5],
        'details': {'tier': 'gold'},
      });

      expect(context.get<int>('user_age'), equals(25));
      expect(context.get<bool>('has_premium'), isTrue);
      expect(context.get<String>('country'), equals('US'));
      expect(context.get<List<dynamic>>('scores'), equals([1.0, 2.5]));
      expect(context.get<Map<dynamic, dynamic>>('details'),
          equals({'tier': 'gold'}));

      // Verify wrong types return null instead of casting exception
      expect(context.get<String>('user_age'), isNull);
      expect(context.get<double>('country'), isNull);

      expect(context.contains('user_age'), isTrue);
      expect(context.contains('non_existent'), isFalse);
    });

    test('Immutability of context map', () {
      final inputMap = {'score': 100};
      final context = EvaluationContext(inputMap);

      // Mutating original map doesn't affect context
      inputMap['score'] = 200;
      expect(context.get<int>('score'), equals(100));

      // Attempting to cast to a mutable map and mutate it or verify context is read-only
      final json = context.toJson();
      expect(
          () => json['score'] = 300, returnsNormally); // json copy is mutable
    });

    test('Rejects non-JSON-serializable objects (runtime safety)', () {
      // Rejects classes/functions/streams
      expect(() => EvaluationContext({'func': () => print('hello')}),
          throwsArgumentError);
      expect(() => EvaluationContext({'stream': const Stream<dynamic>.empty()}),
          throwsArgumentError);
      expect(
          () => EvaluationContext({
                'nested': {'func': () => 5}
              }),
          throwsArgumentError);
      expect(
          () => EvaluationContext({
                'list': [() => 3]
              }),
          throwsArgumentError);
    });

    test('Stable deterministic key ordering on toJson()', () {
      final context1 = EvaluationContext({'z': 1, 'a': 2, 'm': 3});
      final context2 = EvaluationContext({'a': 2, 'm': 3, 'z': 1});

      final json1 = context1.toJson();
      final json2 = context2.toJson();

      expect(json1, equals(json2));
      expect(json1.keys.toList(), equals(['a', 'm', 'z']));
    });

    test('JSON serialization roundtrip', () {
      final original = EvaluationContext({
        'debug': true,
        'factor': 1.25,
        'label': 'ok',
      });

      final json = original.toJson();
      final reconstructed = EvaluationContext.fromJson(json);

      expect(reconstructed.get<bool>('debug'), isTrue);
      expect(reconstructed.get<double>('factor'), equals(1.25));
      expect(reconstructed.get<String>('label'), equals('ok'));
    });
  });
}
