import 'canonicalization_exceptions.dart';

/// Formats and validates floating-point numbers in a platform-invariant,
/// locale-agnostic, and deterministic manner.
class CanonicalFloatFormatter {
  /// Formats all finite doubles to exactly 4 decimal places with a dot separator,
  /// maps positive infinity to `"INFINITY"`, negative infinity to `"-INFINITY"`,
  /// normalizes negative zero to `"0.0000"`, and rejects NaN.
  static String format(double value) {
    if (value.isNaN) {
      throw const CanonicalFloatFormatException(
          'NaN is not a valid snapshot numeric state.');
    }
    if (value == double.infinity) {
      return 'INFINITY';
    }
    if (value == double.negativeInfinity) {
      return '-INFINITY';
    }

    // Normalize negative zero
    final normalized = value == -0.0 ? 0.0 : value;

    // Use toStringAsFixed(4) to ensure exactly 4 decimal places and a dot decimal separator.
    // toStringAsFixed in Dart is locale-agnostic and always uses '.' as decimal separator.
    return normalized.toStringAsFixed(4);
  }

  /// Verifies if a given string represents a valid canonical floating-point representation.
  static bool isCanonical(String value) {
    if (value == 'INFINITY' || value == '-INFINITY') {
      return true;
    }

    // Must match optional minus, digits, a dot, and exactly 4 digits.
    final regex = RegExp(r'^[-]?[0-9]+\.[0-9]{4}$');
    if (!regex.hasMatch(value)) {
      return false;
    }

    // Negative zero is normalized to positive zero, so "-0.0000" is non-canonical.
    if (value == '-0.0000') {
      return false;
    }

    try {
      final parsed = double.parse(value);
      // Double check that round-tripping yields the exact same string
      // (rejects formats like "01.0000" or "-00.5000").
      return format(parsed) == value;
    } catch (_) {
      return false;
    }
  }
}
