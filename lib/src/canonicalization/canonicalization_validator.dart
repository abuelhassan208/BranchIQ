import 'dart:convert';
import 'canonical_json_encoder.dart';
import 'canonicalization_exceptions.dart';

/// Provides validation engines to guarantee that structures and strings match
/// BranchIQ's strict canonicalization format rules.
class CanonicalizationValidator {
  /// Recursively inspects a decoded object to verify that it only contains
  /// JSON-safe types (null, bool, int, double, String, List, Map) and no
  /// forbidden characters like carriage returns.
  static void validateJsonSafe(Object? value) {
    if (value == null || value is bool || value is int) {
      return;
    }
    if (value is double) {
      if (value.isNaN) {
        throw const CanonicalJsonException(
            'NaN is not allowed in canonical JSON structures.');
      }
      if (value.isInfinite) {
        throw const CanonicalJsonException(
            'Infinite values are not allowed in canonical JSON structures.');
      }
      return;
    }
    if (value is String) {
      if (value.contains('\r')) {
        throw const CanonicalJsonException(
            'Carriage return \\r is forbidden in canonical structures.');
      }
      return;
    }
    if (value is List) {
      for (final item in value) {
        validateJsonSafe(item);
      }
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw CanonicalJsonException(
            'Map keys must be String types, got: ${entry.key.runtimeType}',
          );
        }
        validateJsonSafe(entry.value);
      }
      return;
    }

    throw CanonicalJsonException(
      'Unsupported type encountered in canonical validation: ${value.runtimeType}',
    );
  }

  /// Recursively validates that all keys in the Map (and nested Maps) are sorted lexicographically.
  static void validateSortedMapKeys(Map<dynamic, dynamic> map) {
    final keys = map.keys.map((k) => k.toString()).toList();
    for (int i = 0; i < keys.length - 1; i++) {
      if (keys[i].compareTo(keys[i + 1]) > 0) {
        throw CanonicalJsonException(
          'Map keys are not sorted alphabetically. Key "${keys[i]}" should come after "${keys[i + 1]}".',
        );
      }
    }
    for (final val in map.values) {
      if (val is Map<dynamic, dynamic>) {
        validateSortedMapKeys(val);
      }
    }
  }

  /// Validates that a serialized JSON string is formatted strictly according to
  /// canonical guidelines (no extra whitespace, sorted keys, LF newlines, no '\r',
  /// and exact 4-decimal floats via string representations).
  ///
  /// Uses a round-trip byte-equivalence check for bulletproof correctness.
  static void validateCanonicalJsonString(String json) {
    if (json.contains('\r')) {
      throw const CanonicalJsonException(
          'Carriage return \\r is forbidden in canonical JSON.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (e) {
      throw CanonicalJsonException('Invalid JSON payload: $e');
    }

    // 1. Recursive checks for safe types and structure
    validateJsonSafe(decoded);
    if (decoded is Map) {
      validateSortedMapKeys(decoded);
    }

    // 2. Exact round-trip verification to detect spacing, sorting, or format drift
    final reencoded = CanonicalJsonEncoder.encode(decoded);
    if (reencoded != json) {
      throw const CanonicalJsonException(
        'JSON string is not in canonical form (failed roundtrip byte-equivalence check).',
      );
    }
  }

  /// Returns true if the given JSON string complies with strict canonical formats.
  static bool isCanonicalJsonString(String json) {
    try {
      validateCanonicalJsonString(json);
      return true;
    } catch (_) {
      return false;
    }
  }
}
