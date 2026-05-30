import '../../src/canonicalization/canonical_json_encoder.dart';
import '../debug/debug_snapshot.dart';

/// Represents an immutable, snapshot-driven replay session.
/// Reconstructs the exact state of an engine evaluation from a static execution snapshot.
class ReplaySession {
  /// The source execution [DebugSnapshot] that powered this session.
  final DebugSnapshot snapshot;

  /// The schema version of this snapshot's structured payload.
  final String schemaVersion;

  /// The engine version that performed the original evaluation.
  final String engineVersion;

  /// The ordered sequence of node IDs representing the chosen path.
  final List<String> selectedPath;

  /// The list of identifiers of nodes that were excluded via pruning.
  final List<String> prunedNodeIds;

  /// Chronological logs capturing runtime execution steps.
  final List<String> runtimeTraces;

  /// Detailed trace messages logged by pruning strategies.
  final List<String> pruningTraces;

  /// The dictionary mapping node IDs to their metric snapshots.
  final Map<String, Map<String, Object?>> nodeSnapshots;

  /// The unique identifier of the tree root node.
  final String rootId;

  /// The plugin provenance records of evaluated node modifications.
  final List<Map<String, dynamic>> pluginProvenance;

  /// Creates a [ReplaySession] instance. All collections are wrapped in
  /// unmodifiable lists and maps to guarantee immutable isolation.
  ReplaySession({
    required this.snapshot,
    required this.schemaVersion,
    required this.engineVersion,
    required List<String> selectedPath,
    required List<String> prunedNodeIds,
    required List<String> runtimeTraces,
    required List<String> pruningTraces,
    required Map<String, Map<String, dynamic>> nodeSnapshots,
    required this.rootId,
    required List<Map<String, dynamic>> pluginProvenance,
  })  : selectedPath = List<String>.unmodifiable(selectedPath),
        prunedNodeIds = List<String>.unmodifiable(prunedNodeIds),
        runtimeTraces = List<String>.unmodifiable(runtimeTraces),
        pruningTraces = List<String>.unmodifiable(pruningTraces),
        pluginProvenance = List<Map<String, dynamic>>.unmodifiable(
          pluginProvenance.map(
            (val) => Map<String, dynamic>.unmodifiable(val),
          ),
        ),
        nodeSnapshots = Map<String, Map<String, Object?>>.unmodifiable(
          nodeSnapshots.map(
            (key, val) => MapEntry(
              key,
              Map<String, Object?>.unmodifiable(val),
            ),
          ),
        );

  /// Returns a stable JSON map representation of this session.
  Map<String, Object?> toJson() {
    return {
      'engineVersion': engineVersion,
      'nodeSnapshots': nodeSnapshots,
      'pluginProvenance': pluginProvenance,
      'prunedNodeIds': prunedNodeIds,
      'pruningTraces': pruningTraces,
      'rootId': rootId,
      'runtimeTraces': runtimeTraces,
      'schemaVersion': schemaVersion,
      'selectedPath': selectedPath,
    };
  }

  /// Returns a compact, byte-identical canonical JSON string representing this session.
  String toCanonicalJson() {
    return CanonicalJsonEncoder.encode(toJson());
  }
}
