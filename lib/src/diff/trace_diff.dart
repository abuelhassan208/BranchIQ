import '../canonicalization/canonical_json_encoder.dart';

/// Represents the differences in runtime traces between two evaluations.
/// Preserves relative chronological trace ordering.
class TraceDiff {
  /// Traces that exist only in the source evaluation, in their original order.
  final List<String> sourceOnlyTraces;

  /// Traces that exist only in the target evaluation, in their original order.
  final List<String> targetOnlyTraces;

  /// Traces present in both evaluations, in source chronological order.
  final List<String> sharedTraces;

  /// The difference in trace count (target count - source count).
  final int traceCountDelta;

  /// Creates a [TraceDiff] instance. All lists are stored as unmodifiable collections.
  TraceDiff({
    required List<String> sourceOnlyTraces,
    required List<String> targetOnlyTraces,
    required List<String> sharedTraces,
    required this.traceCountDelta,
  })  : sourceOnlyTraces = List<String>.unmodifiable(sourceOnlyTraces),
        targetOnlyTraces = List<String>.unmodifiable(targetOnlyTraces),
        sharedTraces = List<String>.unmodifiable(sharedTraces);

  /// Computes a [TraceDiff] from source and target trace lists chronologically.
  factory TraceDiff.compare(List<String> source, List<String> target) {
    final sourceOnly = source.where((t) => !target.contains(t)).toList();
    final targetOnly = target.where((t) => !source.contains(t)).toList();
    final shared = source.where((t) => target.contains(t)).toList();

    return TraceDiff(
      sourceOnlyTraces: sourceOnly,
      targetOnlyTraces: targetOnly,
      sharedTraces: shared,
      traceCountDelta: target.length - source.length,
    );
  }

  /// Converts this trace diff into a stable JSON Map.
  Map<String, Object?> toJson() {
    return {
      'sharedTraces': sharedTraces,
      'sourceOnlyTraces': sourceOnlyTraces,
      'targetOnlyTraces': targetOnlyTraces,
      'traceCountDelta': traceCountDelta,
    };
  }

  /// Compiles this trace diff into a compact, platform-invariant
  /// and byte-identical canonical JSON string.
  String toCanonicalJson() {
    return CanonicalJsonEncoder.encode(toJson());
  }
}
