import 'dart:convert';
import 'benchmark_snapshot.dart';

/// Represents a stable, serialized representation of the evaluation execution state.
class DebugSnapshot {
  /// The engine version used for path calculations.
  final String engineVersion;

  /// The unique identifier of the tree root node.
  final String rootId;

  /// The ordered sequence of node IDs selected as optimal path.
  final List<String> selectedPath;

  /// Detailed snapshot data for evaluated decision nodes.
  final Map<String, Map<String, dynamic>> nodeSnapshots;

  /// Diagnostics information logged during the pruning operations.
  final List<String> pruningTraces;

  /// Custom telemetry attributes registered inside evaluation context.
  final Map<String, dynamic> metadata;

  /// Operational logs captured during engine execution steps.
  final List<String> runtimeTraces;

  /// Identifiers of all nodes excluded during pruning steps.
  final List<String> prunedNodeIds;

  /// Telemetry summaries for node scoring parameters and weights.
  final Map<String, dynamic> scoringSummaries;

  /// Telemetry summaries for search depth and utility results.
  final Map<String, dynamic> traversalSummaries;

  /// Optional benchmark execution snapshot containing resource usage metrics.
  final BenchmarkSnapshot? benchmarkSnapshot;

  /// The plugin provenance records of evaluated node modifications.
  final List<Map<String, dynamic>> pluginProvenance;

  /// Creates a [DebugSnapshot] instance.
  const DebugSnapshot({
    required this.engineVersion,
    required this.rootId,
    required this.selectedPath,
    required this.nodeSnapshots,
    required this.pruningTraces,
    required this.metadata,
    this.runtimeTraces = const [],
    this.prunedNodeIds = const [],
    this.scoringSummaries = const {},
    this.traversalSummaries = const {},
    this.benchmarkSnapshot,
    this.pluginProvenance = const [],
  });

  /// Deserializes a [DebugSnapshot] from a JSON map.
  factory DebugSnapshot.fromJson(Map<String, dynamic> json) {
    final engineVersion = json['engineVersion'] as String? ?? '0.1.0';
    final rootId = json['rootId'] as String? ?? '';

    final rawPath = json['selectedPath'] as List<dynamic>? ?? const [];
    final selectedPath = List<String>.unmodifiable(rawPath.cast<String>());

    final rawSnapshots =
        json['nodeSnapshots'] as Map<String, dynamic>? ?? const {};
    final nodeSnapshots = <String, Map<String, dynamic>>{};
    for (final entry in rawSnapshots.entries) {
      if (entry.value is Map) {
        nodeSnapshots[entry.key] = Map<String, dynamic>.unmodifiable(
          (entry.value as Map).cast<String, dynamic>(),
        );
      }
    }

    final rawPruningTraces =
        json['pruningTraces'] as List<dynamic>? ?? const [];
    final pruningTraces =
        List<String>.unmodifiable(rawPruningTraces.cast<String>());

    final rawMetadata = json['metadata'] as Map<String, dynamic>? ?? const {};
    final metadata = Map<String, dynamic>.unmodifiable(rawMetadata);

    final rawRuntimeTraces =
        json['runtimeTraces'] as List<dynamic>? ?? const [];
    final runtimeTraces =
        List<String>.unmodifiable(rawRuntimeTraces.cast<String>());

    final rawPrunedNodeIds =
        json['prunedNodeIds'] as List<dynamic>? ?? const [];
    final prunedNodeIds =
        List<String>.unmodifiable(rawPrunedNodeIds.cast<String>());

    final rawScoringSummaries =
        json['scoringSummaries'] as Map<String, dynamic>? ?? const {};
    final scoringSummaries =
        Map<String, dynamic>.unmodifiable(rawScoringSummaries);

    final rawTraversalSummaries =
        json['traversalSummaries'] as Map<String, dynamic>? ?? const {};
    final traversalSummaries =
        Map<String, dynamic>.unmodifiable(rawTraversalSummaries);

    final rawBenchmark = json['benchmarkSnapshot'] as Map<String, dynamic>?;
    final benchmarkSnapshot =
        rawBenchmark != null ? BenchmarkSnapshot.fromJson(rawBenchmark) : null;

    final rawProvenance =
        json['pluginProvenance'] as List<dynamic>? ?? const [];
    final pluginProvenance = <Map<String, dynamic>>[];
    for (final item in rawProvenance) {
      if (item is Map) {
        pluginProvenance.add(Map<String, dynamic>.unmodifiable(
          item.cast<String, dynamic>(),
        ));
      }
    }

    return DebugSnapshot(
      engineVersion: engineVersion,
      rootId: rootId,
      selectedPath: selectedPath,
      nodeSnapshots:
          Map<String, Map<String, dynamic>>.unmodifiable(nodeSnapshots),
      pruningTraces: pruningTraces,
      metadata: metadata,
      runtimeTraces: runtimeTraces,
      prunedNodeIds: prunedNodeIds,
      scoringSummaries: scoringSummaries,
      traversalSummaries: traversalSummaries,
      benchmarkSnapshot: benchmarkSnapshot,
      pluginProvenance:
          List<Map<String, dynamic>>.unmodifiable(pluginProvenance),
    );
  }

  /// Serializes this [DebugSnapshot] into a JSON map with stable, sorted key order.
  Map<String, dynamic> toJson() {
    // Sort snapshots and metadata keys lexicographically to guarantee stable export.
    final sortedSnapshots = Map.fromEntries(
      nodeSnapshots.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final sortedMetadata = Map.fromEntries(
      metadata.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final sortedScoring = Map.fromEntries(
      scoringSummaries.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final sortedTraversal = Map.fromEntries(
      traversalSummaries.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );

    final sortedProvenance = pluginProvenance.map((prov) {
      final modifiedFields = prov['modifiedFields'];
      final sortedModified = modifiedFields is Map
          ? Map.fromEntries(
              modifiedFields.entries.toList()
                ..sort((a, b) => a.key.toString().compareTo(b.key.toString())),
            )
          : modifiedFields;
      final sortedProv = Map.fromEntries(
        prov.entries.toList()
          ..sort((a, b) => a.key.toString().compareTo(b.key.toString())),
      );
      if (sortedModified != null) {
        sortedProv['modifiedFields'] = sortedModified;
      }
      return Map<String, dynamic>.unmodifiable(sortedProv);
    }).toList();

    return {
      'engineVersion': engineVersion,
      'rootId': rootId,
      'selectedPath': selectedPath.toList(),
      'nodeSnapshots': sortedSnapshots,
      'pluginProvenance': sortedProvenance,
      'pruningTraces': pruningTraces.toList(),
      'metadata': sortedMetadata,
      'runtimeTraces': runtimeTraces.toList(),
      'prunedNodeIds': prunedNodeIds.toList(),
      'scoringSummaries': sortedScoring,
      'traversalSummaries': sortedTraversal,
      if (benchmarkSnapshot != null)
        'benchmarkSnapshot': benchmarkSnapshot?.toJson(),
    };
  }

  /// Converts this execution snapshot into a pretty-printed JSON string.
  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
