/// Base exception class for snapshot diffing operations.
class SnapshotDiffException implements Exception {
  /// The descriptive error message.
  final String message;

  /// Creates a [SnapshotDiffException] with the given message.
  const SnapshotDiffException(this.message);

  @override
  String toString() => 'SnapshotDiffException: $message';
}

/// Thrown when an execution snapshot is corrupt, malformed, or incompatible
/// with the diffing process.
class SnapshotDiffCorruptException extends SnapshotDiffException {
  /// Creates a [SnapshotDiffCorruptException] with the given message.
  const SnapshotDiffCorruptException(super.message);

  @override
  String toString() => 'SnapshotDiffCorruptException: $message';
}
