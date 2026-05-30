/// Exceptions thrown during the canonicalization process in BranchIQ.
class CanonicalizationException implements Exception {
  /// The error message associated with the exception.
  final String message;

  /// Creates a [CanonicalizationException] with the given message.
  const CanonicalizationException(this.message);

  @override
  String toString() => 'CanonicalizationException: $message';
}

/// Thrown when double floating point values fail to meet canonical limits.
class CanonicalFloatFormatException extends CanonicalizationException {
  /// Creates a [CanonicalFloatFormatException] with the given message.
  const CanonicalFloatFormatException(super.message);

  @override
  String toString() => 'CanonicalFloatFormatException: $message';
}

/// Thrown when JSON serialization encounters non-canonical or unsupported states.
class CanonicalJsonException extends CanonicalizationException {
  /// Creates a [CanonicalJsonException] with the given message.
  const CanonicalJsonException(super.message);

  @override
  String toString() => 'CanonicalJsonException: $message';
}

/// Thrown when markdown generation encounters malformed formatting inputs.
class CanonicalMarkdownException extends CanonicalizationException {
  /// Creates a [CanonicalMarkdownException] with the given message.
  const CanonicalMarkdownException(super.message);

  @override
  String toString() => 'CanonicalMarkdownException: $message';
}
