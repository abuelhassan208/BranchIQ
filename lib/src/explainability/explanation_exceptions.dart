/// Base exception class for BranchIQ explainability errors.
class ExplanationException implements Exception {
  /// The underlying diagnostic message.
  final String message;

  /// Creates an [ExplanationException] with a deterministic message.
  const ExplanationException(this.message);

  @override
  String toString() => 'ExplanationException: $message';
}

/// Thrown when a loaded replay session snapshot is structurally corrupt
/// or misses critical data elements required to generate decision explainability.
class ExplanationCorruptException extends ExplanationException {
  /// The unique identifier of the node associated with the failure, if any.
  final String nodeId;

  /// Creates an [ExplanationCorruptException] mapping to a specific node.
  const ExplanationCorruptException(super.message, {this.nodeId = ''});

  @override
  String toString() {
    final nodeInfo = nodeId.isNotEmpty ? ' (Node ID: $nodeId)' : '';
    return 'ExplanationCorruptException: $message$nodeInfo';
  }
}
