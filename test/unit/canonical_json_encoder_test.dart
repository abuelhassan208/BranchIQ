import 'package:branchiq/src/canonicalization/canonical_json_encoder.dart';
import 'package:branchiq/src/canonicalization/canonicalization_exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('CanonicalJsonEncoder Unit Tests', () {
    test('Sorts map keys lexicographically', () {
      final source = {
        'zeta': 1,
        'alpha': 2,
        'gamma': 3,
        'beta': 4,
      };
      final compact = CanonicalJsonEncoder.encode(source);
      expect(compact, equals('{"alpha":2,"beta":4,"gamma":3,"zeta":1}'));
    });

    test('Recursively sorts nested maps', () {
      final source = {
        'z': {
          'y': 2,
          'x': 1,
        },
        'a': {
          'c': 4,
          'b': 3,
        }
      };
      final compact = CanonicalJsonEncoder.encode(source);
      expect(compact, equals('{"a":{"b":3,"c":4},"z":{"x":1,"y":2}}'));
    });

    test('Preserves original list ordering', () {
      final source = {
        'list': [3, 1, 4, 2, 5],
      };
      final compact = CanonicalJsonEncoder.encode(source);
      expect(compact, equals('{"list":[3,1,4,2,5]}'));
    });

    test('Omits fields with null values', () {
      final source = {
        'a': 1,
        'b': null,
        'c': 3,
      };
      final compact = CanonicalJsonEncoder.encode(source);
      expect(compact, equals('{"a":1,"c":3}'));
    });

    test(
        'Normalizes strings by stripping carriage returns but preserving newlines',
        () {
      final source = {
        'message': 'Line 1\r\nLine 2\rLine 3\n',
      };
      final compact = CanonicalJsonEncoder.encode(source);
      expect(compact, equals('{"message":"Line 1\\nLine 2Line 3\\n"}'));
    });

    test('Serializes doubles utilizing CanonicalFloatFormatter', () {
      final source = {
        'utility': 0.85,
        'cost': 123.0,
        'infinity': double.infinity,
      };
      final compact = CanonicalJsonEncoder.encode(source);
      expect(
          compact,
          equals(
              '{"cost":"123.0000","infinity":"INFINITY","utility":"0.8500"}'));
    });

    test('Rejects unsupported runtime objects with CanonicalJsonException', () {
      final source = {
        'date': DateTime.now(),
      };
      expect(
        () => CanonicalJsonEncoder.encode(source),
        throwsA(isA<CanonicalJsonException>()),
      );
    });

    test('Generates expected pretty-printed output', () {
      final source = {
        'z': 2,
        'a': 1,
      };
      final pretty = CanonicalJsonEncoder.encodePretty(source);
      expect(pretty, equals('{\n  "a": 1,\n  "z": 2\n}'));
    });
  });
}
