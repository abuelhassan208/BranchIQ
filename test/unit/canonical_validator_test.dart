import 'package:branchiq/src/canonicalization/canonicalization_exceptions.dart';
import 'package:branchiq/src/canonicalization/canonicalization_validator.dart';
import 'package:test/test.dart';

void main() {
  group('CanonicalizationValidator Unit Tests', () {
    test('validateJsonSafe permits primitive types, lists, and maps', () {
      final safe = {
        'string': 'Hello',
        'int': 42,
        'double': 123.45,
        'bool': true,
        'nullValue': null,
        'list': [1, '2', null],
        'nested': {
          'key': 'value',
        }
      };

      expect(() => CanonicalizationValidator.validateJsonSafe(safe),
          returnsNormally);
    });

    test('validateJsonSafe rejects carriage returns', () {
      final badString = 'Hello\rWorld';
      expect(
        () => CanonicalizationValidator.validateJsonSafe(badString),
        throwsA(isA<CanonicalJsonException>()),
      );

      final nestedBadString = {
        'list': ['safe', 'bad\rvalue'],
      };
      expect(
        () => CanonicalizationValidator.validateJsonSafe(nestedBadString),
        throwsA(isA<CanonicalJsonException>()),
      );
    });

    test('validateJsonSafe rejects unsupported types', () {
      expect(
        () => CanonicalizationValidator.validateJsonSafe(DateTime.now()),
        throwsA(isA<CanonicalJsonException>()),
      );
    });

    test('validateSortedMapKeys verifies correct key ordering', () {
      final sorted = {
        'a': 1,
        'b': 2,
        'c': {
          'x': 1,
          'y': 2,
        }
      };
      expect(() => CanonicalizationValidator.validateSortedMapKeys(sorted),
          returnsNormally);

      final unsorted = {
        'b': 1,
        'a': 2, // Out of order!
      };
      expect(
        () => CanonicalizationValidator.validateSortedMapKeys(unsorted),
        throwsA(isA<CanonicalJsonException>()),
      );
    });

    test('validateCanonicalJsonString validates byte-identical structures', () {
      final canonicalJson = '{"a":1,"b":"0.5000","c":["x","y"]}';
      expect(
        () => CanonicalizationValidator.validateCanonicalJsonString(
            canonicalJson),
        returnsNormally,
      );
      expect(CanonicalizationValidator.isCanonicalJsonString(canonicalJson),
          isTrue);
    });

    test('validateCanonicalJsonString rejects formatted or spaced JSON', () {
      final spacedJson = '{"a": 1, "b": "0.5000"}'; // spaces after colons
      expect(
        () => CanonicalizationValidator.validateCanonicalJsonString(spacedJson),
        throwsA(isA<CanonicalJsonException>()),
      );
      expect(
          CanonicalizationValidator.isCanonicalJsonString(spacedJson), isFalse);
    });

    test('validateCanonicalJsonString rejects non-canonical float formats', () {
      final nonCanonicalFloat = '{"a":1.0}'; // Should be "1.0000"
      expect(
        () => CanonicalizationValidator.validateCanonicalJsonString(
            nonCanonicalFloat),
        throwsA(isA<CanonicalJsonException>()),
      );
    });
  });
}
