import 'dart:convert';
import 'canonical_float_formatter.dart';
import 'canonicalization_exceptions.dart';

/// Provides deterministic and platform-independent JSON serialization capabilities.
class CanonicalJsonEncoder {
  /// Recursively normalizes Dart objects into a canonical structure.
  ///
  /// Enforces alphabetical key ordering for all maps, strips carriage returns ('\r')
  /// from strings, omits null fields, preserves list orders, formats doubles
  /// to 4 decimal places via [CanonicalFloatFormatter], and rejects unsupported types.
  static Object? normalize(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value.replaceAll('\r', '');
    }
    if (value is int) {
      return value;
    }
    if (value is bool) {
      return value;
    }
    if (value is double) {
      return CanonicalFloatFormatter.format(value);
    }
    if (value is List) {
      return List<Object?>.unmodifiable(value.map(normalize));
    }
    if (value is Map) {
      final sortedKeys = value.keys.map((k) => k.toString()).toList()..sort();
      final normalizedMap = <String, Object?>{};
      for (final key in sortedKeys) {
        final val = value[key];
        if (val != null) {
          final normalizedVal = normalize(val);
          if (normalizedVal != null) {
            normalizedMap[key] = normalizedVal;
          }
        }
      }
      return Map<String, Object?>.unmodifiable(normalizedMap);
    }

    throw CanonicalJsonException(
      'Unsupported type for canonical JSON serialization: ${value.runtimeType}',
    );
  }

  /// Encodes the object into a compact, single-line canonical JSON string.
  static String encode(Object? value) {
    try {
      final normalized = normalize(value);
      return jsonEncode(normalized);
    } on CanonicalizationException {
      rethrow;
    } catch (e) {
      throw CanonicalJsonException('Failed to encode canonical JSON: $e');
    }
  }

  /// Encodes the object into a pretty-printed canonical JSON string for debugging.
  static String encodePretty(Object? value) {
    try {
      final normalized = normalize(value);
      return const JsonEncoder.withIndent('  ').convert(normalized);
    } on CanonicalizationException {
      rethrow;
    } catch (e) {
      throw CanonicalJsonException('Failed to pretty-print canonical JSON: $e');
    }
  }
}
