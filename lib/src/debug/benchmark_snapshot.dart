/// Represents a stable, serialized representation of execution metrics.
/// This avoids wall-clock profiling to ensure 100% deterministic outputs across environments.
class BenchmarkSnapshot {
  /// Total nodes in the decision tree structure.
  final int totalNodes;

  /// Iteration count performed during traversal of the tree.
  final int traversalIterations;

  /// Total logic steps executed during evaluation pipeline.
  final int executionSteps;

  /// Number of nodes retained after the pruning phase.
  final int retainedNodes;

  /// Number of nodes pruned during pruning.
  final int prunedNodes;

  /// Length of the selected optimal path.
  final int selectedPathLength;

  /// A deterministic estimate of internal object allocations.
  final int estimatedAllocationCount;

  /// The final runtime state when the evaluation completed.
  final String runtimeState;

  /// Creates a [BenchmarkSnapshot] instance.
  const BenchmarkSnapshot({
    required this.totalNodes,
    required this.traversalIterations,
    required this.executionSteps,
    required this.retainedNodes,
    required this.prunedNodes,
    required this.selectedPathLength,
    required this.estimatedAllocationCount,
    required this.runtimeState,
  });

  /// Deserializes a [BenchmarkSnapshot] from a JSON map.
  factory BenchmarkSnapshot.fromJson(Map<String, dynamic> json) {
    return BenchmarkSnapshot(
      totalNodes: json['totalNodes'] as int? ?? 0,
      traversalIterations: json['traversalIterations'] as int? ?? 0,
      executionSteps: json['executionSteps'] as int? ?? 0,
      retainedNodes: json['retainedNodes'] as int? ?? 0,
      prunedNodes: json['prunedNodes'] as int? ?? 0,
      selectedPathLength: json['selectedPathLength'] as int? ?? 0,
      estimatedAllocationCount: json['estimatedAllocationCount'] as int? ?? 0,
      runtimeState: json['runtimeState'] as String? ?? 'unknown',
    );
  }

  /// Serializes this [BenchmarkSnapshot] into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'totalNodes': totalNodes,
      'traversalIterations': traversalIterations,
      'executionSteps': executionSteps,
      'retainedNodes': retainedNodes,
      'prunedNodes': prunedNodes,
      'selectedPathLength': selectedPathLength,
      'estimatedAllocationCount': estimatedAllocationCount,
      'runtimeState': runtimeState,
    };
  }

  @override
  String toString() {
    return 'BenchmarkSnapshot(totalNodes: $totalNodes, '
        'traversalIterations: $traversalIterations, '
        'executionSteps: $executionSteps, '
        'retainedNodes: $retainedNodes, '
        'prunedNodes: $prunedNodes, '
        'selectedPathLength: $selectedPathLength, '
        'estimatedAllocationCount: $estimatedAllocationCount, '
        'runtimeState: $runtimeState)';
  }
}
