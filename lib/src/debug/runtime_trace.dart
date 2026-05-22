/// Represents the structural phases of the runtime decision pipeline.
enum TracePhase {
  /// Validation of tree structure hierarchy.
  validation,

  /// Utility scoring computations.
  scoring,

  /// Node pruning filters.
  pruning,

  /// Optimal path traversal.
  traversal,

  /// Fallback logic executions.
  fallback,

  /// Pipeline completion trace.
  completion;

  /// Returns the corresponding [TracePhase] matching the provided string.
  static TracePhase fromString(String val) {
    return TracePhase.values.firstWhere(
      (e) => e.name == val,
      orElse: () => throw ArgumentError('Unknown TracePhase: "$val".'),
    );
  }
}

/// Represents an immutable diagnostic log event recorded during evaluation.
class RuntimeTrace {
  /// The execution phase when this event was captured.
  final TracePhase phase;

  /// The diagnostic log message.
  final String message;

  /// An optional node identifier target associated with this event.
  final String? nodeId;

  /// Optional telemetry variables and snapshot attributes.
  final Map<String, dynamic>? metadata;

  /// Creates a [RuntimeTrace] instance.
  const RuntimeTrace({
    required this.phase,
    required this.message,
    this.nodeId,
    this.metadata,
  });

  /// Deserializes a [RuntimeTrace] from a JSON map.
  factory RuntimeTrace.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'] as Map<String, dynamic>?;
    return RuntimeTrace(
      phase: TracePhase.fromString(json['phase'] as String),
      message: json['message'] as String,
      nodeId: json['nodeId'] as String?,
      metadata: rawMetadata != null
          ? Map<String, dynamic>.unmodifiable(rawMetadata)
          : null,
    );
  }

  /// Serializes this [RuntimeTrace] into a JSON map with stable, sorted key order.
  Map<String, dynamic> toJson() {
    Map<String, dynamic>? sortedMetadata;
    if (metadata != null) {
      final keys = metadata!.keys.toList()..sort();
      sortedMetadata = {for (final k in keys) k: metadata![k]};
    }

    return {
      'phase': phase.name,
      'message': message,
      if (nodeId != null) 'nodeId': nodeId,
      if (sortedMetadata != null) 'metadata': sortedMetadata,
    };
  }

  @override
  String toString() {
    final nodeStr = nodeId != null ? ' (Node: $nodeId)' : '';
    final metaStr = metadata != null ? ' Meta: $metadata' : '';
    return '[${phase.name.toUpperCase()}] $message$nodeStr$metaStr';
  }
}
