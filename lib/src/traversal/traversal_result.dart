import '../internal/allocation_tracker.dart';
import '../internal/execution_budget.dart';
import '../models/decision_node.dart';

/// Represents the immutable output result of a decision tree traversal operation.
class TraversalResult {
  /// The ordered sequence of decision nodes forming the traversed path.
  final List<DecisionNode> selectedNodes;

  /// The ordered sequence of unique node identifiers representing the path.
  final List<String> selectedNodeIds;

  /// The identifier of the terminal (end) node of the traversed path.
  final String terminalNodeId;

  /// The accumulated total utility score sum along the selected path.
  final double totalUtility;

  /// Flags whether a fallback search path was returned due to traversal exhaustion or failures.
  final bool wasFallback;

  /// An optional error or failure diagnostic message if traversal succeeded partially or fell back.
  final String? failureReason;

  /// Optional budget tracker captured during traversal.
  final ExecutionBudget? budget;

  /// Optional allocation tracker captured during traversal.
  final AllocationTracker? tracker;

  /// Creates a [TraversalResult] instance.
  ///
  /// Coerces lists into unmodifiable collections to guarantee strict immutability.
  TraversalResult({
    required List<DecisionNode> selectedNodes,
    required List<String> selectedNodeIds,
    required this.terminalNodeId,
    required this.totalUtility,
    required this.wasFallback,
    this.failureReason,
    this.budget,
    this.tracker,
  })  : selectedNodes = List<DecisionNode>.unmodifiable(selectedNodes),
        selectedNodeIds = List<String>.unmodifiable(selectedNodeIds);

  /// Deserializes a [TraversalResult] from a JSON map.
  factory TraversalResult.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['selectedNodes'] as List<dynamic>? ?? const [];
    final rawNodeIds = json['selectedNodeIds'] as List<dynamic>? ?? const [];

    final selectedNodes = rawNodes
        .map((n) => DecisionNode.fromJson(n as Map<String, dynamic>))
        .toList();
    final selectedNodeIds = rawNodeIds.cast<String>().toList();

    final terminalNodeId = json['terminalNodeId'] as String? ?? '';
    final totalUtility = (json['totalUtility'] as num?)?.toDouble() ?? 0.0;
    final wasFallback = json['wasFallback'] as bool? ?? false;
    final failureReason = json['failureReason'] as String?;

    return TraversalResult(
      selectedNodes: selectedNodes,
      selectedNodeIds: selectedNodeIds,
      terminalNodeId: terminalNodeId,
      totalUtility: totalUtility,
      wasFallback: wasFallback,
      failureReason: failureReason,
    );
  }

  /// Serializes this [TraversalResult] into a JSON map with stable, sorted key order.
  Map<String, dynamic> toJson() {
    return {
      'selectedNodes': selectedNodes.map((n) => n.toJson()).toList(),
      'selectedNodeIds': selectedNodeIds.toList(),
      'terminalNodeId': terminalNodeId,
      'totalUtility': totalUtility,
      'wasFallback': wasFallback,
      if (failureReason != null) 'failureReason': failureReason,
    };
  }
}
