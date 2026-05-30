/// Exception thrown when snapshot-driven replay encounters a corrupted,
/// incomplete, or unsupported execution snapshot structure.
class ReplayCorruptException implements Exception {
  /// A descriptive message explaining the corruption or validation failure.
  final String message;

  /// The optional identifier of a node that was referenced but missing in the snapshot.
  final String? missingNodeId;

  /// An optional detail explaining the specific value or integrity mismatch.
  final String? mismatchReason;

  /// The optional version string of the schema that caused the failure.
  final String? schemaVersion;

  /// Creates a [ReplayCorruptException] with deterministic details.
  const ReplayCorruptException(
    this.message, {
    this.missingNodeId,
    this.mismatchReason,
    this.schemaVersion,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ReplayCorruptException: $message');
    if (missingNodeId != null) {
      buffer.write(' (Missing Node ID: $missingNodeId)');
    }
    if (mismatchReason != null) {
      buffer.write(' (Mismatch Reason: $mismatchReason)');
    }
    if (schemaVersion != null) {
      buffer.write(' (Schema Version: $schemaVersion)');
    }
    return buffer.toString();
  }
}
