import '../replay/replay_session.dart';
import 'decision_comparison.dart';
import 'explanation_exceptions.dart';
import 'explanation_report.dart';
import 'node_explanation.dart';

/// The entrypoint for deterministic, evidence-based explainability in BranchIQ.
/// Evaluates decision parameters from raw [ReplaySession] data only.
class BranchIQExplainer {
  /// Analyzes a [ReplaySession] to generate an immutable [ExplanationReport].
  ///
  /// Throws [ExplanationCorruptException] if critical snapshot details are missing or malformed.
  static ExplanationReport explain(ReplaySession session) {
    try {
      final rootId = session.rootId;
      final selectedPath = session.selectedPath;
      final prunedNodeIds = session.prunedNodeIds;
      final nodeSnapshots = session.nodeSnapshots;

      if (rootId.isEmpty) {
        throw const ExplanationCorruptException(
            'Replay session root ID is empty.');
      }

      // 1. Resolve path utility
      final traversalSummaryMap = session.snapshot.traversalSummaries;
      final rawUtility = traversalSummaryMap['totalUtility'];
      final selectedUtility = _parseDouble(rawUtility) ?? 0.0;

      final nodeExplanations = <String, NodeExplanation>{};

      // 2. Build explanations for each individual node
      for (final entry in nodeSnapshots.entries) {
        final nodeId = entry.key;
        final nodeData = entry.value;

        final rawScore = nodeData['score'];
        final score = _parseDouble(rawScore) ?? 0.0;

        final rawProb = nodeData['probability'];
        final probability = _parseDouble(rawProb);

        final rawImpact = nodeData['impact'];
        final impact = _parseDouble(rawImpact);

        final rawCost = nodeData['cost'];
        final cost = _parseDouble(rawCost);

        final rawConf = nodeData['confidence'];
        final confidence = _parseDouble(rawConf);

        final isPruned = prunedNodeIds.contains(nodeId);
        final pruningStatus = isPruned ? 'pruned' : 'retained';
        final pruningReason = nodeData['pruningReason'] as String?;

        final selected = selectedPath.contains(nodeId);
        final rankIndex = selectedPath.indexOf(nodeId);
        final traversalRank = rankIndex != -1 ? rankIndex + 1 : null;

        // Determine terminal state
        bool isTerminal = false;
        if (selectedPath.isNotEmpty && selectedPath.last == nodeId) {
          isTerminal = true;
        } else {
          final rawChildIds = nodeData['childIds'];
          if (rawChildIds is List && rawChildIds.isEmpty) {
            isTerminal = true;
          } else if (rawChildIds is List && rawChildIds.isNotEmpty) {
            isTerminal = false;
          } else {
            if (selectedPath.contains(nodeId)) {
              isTerminal = selectedPath.last == nodeId;
            } else {
              final currentDepth = _parseInt(nodeData['depth']) ?? 0;
              final hasChildrenAtNextDepth =
                  nodeSnapshots.values.any((otherData) {
                final otherDepth = _parseInt(otherData['depth']) ?? 0;
                final otherParentId = otherData['parentId'] as String?;
                if (otherParentId != null) {
                  return otherParentId == nodeId;
                }
                return otherDepth == currentDepth + 1;
              });
              isTerminal = !hasChildrenAtNextDepth;
            }
          }
        }

        nodeExplanations[nodeId] = NodeExplanation(
          nodeId: nodeId,
          score: score,
          probabilityContribution: probability,
          impactContribution: impact,
          costContribution: cost,
          confidenceContribution: confidence,
          pruningStatus: pruningStatus,
          pruningReason: pruningReason,
          traversalRank: traversalRank,
          selected: selected,
          terminal: isTerminal,
        );
      }

      // Compute rejectedNodeIds (nodes that were not selected)
      final rejectedNodeIds = nodeSnapshots.keys
          .where((id) => !selectedPath.contains(id))
          .toList()
        ..sort();

      final pruningSummary = session.snapshot.scoringSummaries;
      final traversalSummary = session.snapshot.traversalSummaries;

      return ExplanationReport(
        rootId: rootId,
        selectedPath: selectedPath,
        selectedUtility: selectedUtility,
        nodeExplanations: nodeExplanations,
        rejectedNodeIds: rejectedNodeIds,
        pruningSummary: pruningSummary,
        traversalSummary: traversalSummary,
        runtimeTraceSummary: session.runtimeTraces,
        replayMetadata: session.snapshot.metadata,
        schemaVersion: session.schemaVersion,
        pluginProvenance: session.pluginProvenance,
      );
    } catch (e) {
      if (e is ExplanationException) rethrow;
      throw ExplanationCorruptException(
          'Failed to generate explanation report: $e');
    }
  }

  /// Synchronously compares the selected path with an alternative (rejected) path.
  static DecisionComparison comparePaths({
    required ReplaySession session,
    required List<String> selectedPath,
    required List<String> rejectedPath,
  }) {
    if (selectedPath.isEmpty) {
      throw const ExplanationException('Selected path cannot be empty.');
    }
    if (rejectedPath.isEmpty) {
      throw const ExplanationException('Rejected path cannot be empty.');
    }

    final nodeSnapshots = session.nodeSnapshots;

    // Check that all nodes in selectedPath exist in snapshots
    for (final id in selectedPath) {
      if (!nodeSnapshots.containsKey(id)) {
        throw ExplanationException(
            'Selected path node "$id" does not exist in replay snapshots.');
      }
    }

    // Check that all nodes in rejectedPath exist in snapshots
    for (final id in rejectedPath) {
      if (!nodeSnapshots.containsKey(id)) {
        throw ExplanationException(
            'Rejected path node "$id" does not exist in replay snapshots.');
      }
    }

    // Helper to calculate total utility of a path (score of its leaf node)
    double calculatePathUtility(List<String> path) {
      final lastNodeId = path.last;
      final lastNodeData = nodeSnapshots[lastNodeId]!;
      return _parseDouble(lastNodeData['score']) ?? 0.0;
    }

    final selectedUtility = calculatePathUtility(selectedPath);
    final rejectedUtility = calculatePathUtility(rejectedPath);
    final utilityDelta = selectedUtility - rejectedUtility;

    final selectedLength = selectedPath.length;
    final rejectedLength = rejectedPath.length;
    final lengthDelta = selectedLength - rejectedLength;

    final scoreDifferences = <String, double>{};
    final confidenceDifferences = <String, double>{};
    final prunedInRejectedOnly = <String>[];
    final pruningDifferences = <String>[];

    // Analyze overlapping and non-overlapping nodes
    for (final id in nodeSnapshots.keys) {
      final inSel = selectedPath.contains(id);
      final inRej = rejectedPath.contains(id);

      if (inSel || inRej) {
        final isPruned = session.prunedNodeIds.contains(id);

        if (inRej && !inSel && isPruned) {
          prunedInRejectedOnly.add(id);
        }

        // Compare overlapping nodes
        if (inSel && inRej) {
          scoreDifferences[id] = 0.0;
          confidenceDifferences[id] = 0.0;
        }
      }
    }

    for (final id in prunedInRejectedOnly) {
      final nodeData = nodeSnapshots[id]!;
      final reason =
          nodeData['pruningReason'] as String? ?? 'No reason provided';
      pruningDifferences
          .add('Node "$id" was pruned on the rejected path. Reason: $reason');
    }

    return DecisionComparison(
      selectedPath: selectedPath,
      rejectedPath: rejectedPath,
      selectedUtility: selectedUtility,
      rejectedUtility: rejectedUtility,
      utilityDelta: utilityDelta,
      selectedLength: selectedLength,
      rejectedLength: rejectedLength,
      lengthDelta: lengthDelta,
      scoreDifferences: scoreDifferences,
      confidenceDifferences: confidenceDifferences,
      prunedInRejectedOnly: prunedInRejectedOnly..sort(),
      pruningDifferences: pruningDifferences,
    );
  }

  static double? _parseDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
