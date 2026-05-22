import '../debug/benchmark_snapshot.dart';
import '../debug/debug_snapshot.dart';
import 'decision_node.dart';

/// Wraps the ordered sequence of optimal decision nodes selected by the engine.
class BestPathResult {
  /// The list of decision nodes forming the final path.
  final List<DecisionNode> nodes;

  /// The list of unique node identifiers representing the path.
  final List<String> nodeIds;

  /// Creates a [BestPathResult] instance.
  BestPathResult({
    required List<DecisionNode> nodes,
    required List<String> nodeIds,
  })  : nodes = List<DecisionNode>.unmodifiable(nodes),
        nodeIds = List<String>.unmodifiable(nodeIds);

  /// Deserializes a [BestPathResult] from a JSON map.
  factory BestPathResult.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as List<dynamic>? ?? const [];
    final nodes = rawNodes
        .map((n) => DecisionNode.fromJson(n as Map<String, dynamic>))
        .toList();
    final rawNodeIds = json['nodeIds'] as List<dynamic>? ?? const [];
    final nodeIds = rawNodeIds.cast<String>();
    return BestPathResult(nodes: nodes, nodeIds: nodeIds);
  }

  /// Serializes this [BestPathResult] into a JSON map with stable key order.
  Map<String, dynamic> toJson() {
    return {
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'nodeIds': nodeIds.toList(),
    };
  }
}

/// Contains the final evaluation path and debugging traces from traversal.
class EvaluationResult {
  /// The computed optimal traversal path result.
  final BestPathResult bestPath;

  /// Diagnostic trace entries logged during scoring and pruning steps.
  final List<String> traces;

  /// The duration in milliseconds of the evaluation run.
  final int durationMs;

  /// Flags whether a fallback search algorithm or default path was selected.
  final bool wasFallback;

  /// Optional error message in the event of partial execution failure.
  final String? errorMessage;

  /// Diagnostic snapshot detailing traversal frontiers.
  final DebugSnapshot? debugSnapshot;

  /// The total utility score sum of the selected path.
  final double totalUtility;

  /// The name of the final runtime state when the evaluation completed.
  final String runtimeState;

  /// Optional benchmark execution snapshot containing resource usage metrics.
  final BenchmarkSnapshot? benchmarkSnapshot;

  /// Creates an [EvaluationResult] instance.
  EvaluationResult({
    required this.bestPath,
    List<String> traces = const [],
    this.durationMs = 0,
    this.wasFallback = false,
    this.errorMessage,
    this.debugSnapshot,
    this.totalUtility = 0.0,
    this.runtimeState = 'completed',
    this.benchmarkSnapshot,
  }) : traces = List<String>.unmodifiable(traces);

  /// Deserializes an [EvaluationResult] from a JSON map.
  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    final bestPath = BestPathResult.fromJson(
        json['bestPath'] as Map<String, dynamic>? ?? const {});
    final rawTraces = json['traces'] as List<dynamic>? ?? const [];
    final traces = rawTraces.cast<String>();
    final durationMs = json['durationMs'] as int? ?? 0;
    final wasFallback = json['wasFallback'] as bool? ?? false;
    final errorMessage = json['errorMessage'] as String?;
    final rawSnapshot = json['debugSnapshot'] as Map<String, dynamic>?;
    final debugSnapshot =
        rawSnapshot != null ? DebugSnapshot.fromJson(rawSnapshot) : null;
    final totalUtility = (json['totalUtility'] as num?)?.toDouble() ?? 0.0;
    final runtimeState = json['runtimeState'] as String? ?? 'completed';
    final rawBenchmark = json['benchmarkSnapshot'] as Map<String, dynamic>?;
    final benchmarkSnapshot =
        rawBenchmark != null ? BenchmarkSnapshot.fromJson(rawBenchmark) : null;

    return EvaluationResult(
      bestPath: bestPath,
      traces: traces,
      durationMs: durationMs,
      wasFallback: wasFallback,
      errorMessage: errorMessage,
      debugSnapshot: debugSnapshot,
      totalUtility: totalUtility,
      runtimeState: runtimeState,
      benchmarkSnapshot: benchmarkSnapshot,
    );
  }

  /// Serializes this [EvaluationResult] into a JSON map with stable key order.
  Map<String, dynamic> toJson() {
    return {
      'bestPath': bestPath.toJson(),
      'traces': traces.toList(),
      'durationMs': durationMs,
      'wasFallback': wasFallback,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (debugSnapshot != null) 'debugSnapshot': debugSnapshot?.toJson(),
      'totalUtility': totalUtility,
      'runtimeState': runtimeState,
      if (benchmarkSnapshot != null)
        'benchmarkSnapshot': benchmarkSnapshot?.toJson(),
    };
  }
}
