import '../debug/debug_snapshot.dart';
import '../replay/replay_loader.dart';
import '../replay/replay_session.dart';
import 'diff_exceptions.dart';
import 'node_metric_diff.dart';
import 'snapshot_diff.dart';
import 'trace_diff.dart';

/// Central coordinate class for deterministic, synchronous snapshot comparisons.
class SnapshotDiffer {
  /// Compares two loaded [ReplaySession] instances offline and synchronously.
  /// Throws [SnapshotDiffCorruptException] if any required data is corrupt or missing.
  static SnapshotDiff compareSessions({
    required ReplaySession source,
    required ReplaySession target,
  }) {
    try {
      final sourceSelectedPath = source.selectedPath;
      final targetSelectedPath = target.selectedPath;

      final pathChanged =
          _listNotEquals(sourceSelectedPath, targetSelectedPath);

      // Resolve utilities safely
      final sourceUtility = _getUtility(source);
      final targetUtility = _getUtility(target);
      final utilityDelta = targetUtility - sourceUtility;

      // Extract all unique node IDs across both sessions
      final allNodeIds = <String>{
        ...source.nodeSnapshots.keys,
        ...target.nodeSnapshots.keys,
      };

      final addedNodeIds = <String>[];
      final removedNodeIds = <String>[];
      final modifiedNodeIds = <String>[];
      final newlyPrunedNodeIds = <String>[];
      final newlyUnprunedNodeIds = <String>[];
      final nodeMetricDiffs = <String, NodeMetricDiff>{};

      for (final nodeId in allNodeIds) {
        final inSource = source.nodeSnapshots.containsKey(nodeId);
        final inTarget = target.nodeSnapshots.containsKey(nodeId);

        if (inTarget && !inSource) {
          addedNodeIds.add(nodeId);
        } else if (inSource && !inTarget) {
          removedNodeIds.add(nodeId);
        }

        final sourceNode = source.nodeSnapshots[nodeId];
        final targetNode = target.nodeSnapshots[nodeId];

        final sourcePruned = source.prunedNodeIds.contains(nodeId);
        final targetPruned = target.prunedNodeIds.contains(nodeId);

        if (inSource && inTarget) {
          if (targetPruned && !sourcePruned) {
            newlyPrunedNodeIds.add(nodeId);
          } else if (sourcePruned && !targetPruned) {
            newlyUnprunedNodeIds.add(nodeId);
          }
        }

        // Compare individual metrics
        final double? sourceProb =
            inSource ? _parseDouble(sourceNode!['probability']) : null;
        final double? targetProb =
            inTarget ? _parseDouble(targetNode!['probability']) : null;
        final double? probabilityDelta =
            (sourceProb != null && targetProb != null)
                ? targetProb - sourceProb
                : null;

        final double? sourceImpact =
            inSource ? _parseDouble(sourceNode!['impact']) : null;
        final double? targetImpact =
            inTarget ? _parseDouble(targetNode!['impact']) : null;
        final double? impactDelta =
            (sourceImpact != null && targetImpact != null)
                ? targetImpact - sourceImpact
                : null;

        final double? sourceCost =
            inSource ? _parseDouble(sourceNode!['cost']) : null;
        final double? targetCost =
            inTarget ? _parseDouble(targetNode!['cost']) : null;
        final double? costDelta = (sourceCost != null && targetCost != null)
            ? targetCost - sourceCost
            : null;

        final double? sourceConfidence =
            inSource ? _parseDouble(sourceNode!['confidence']) : null;
        final double? targetConfidence =
            inTarget ? _parseDouble(targetNode!['confidence']) : null;
        final double? confidenceDelta =
            (sourceConfidence != null && targetConfidence != null)
                ? targetConfidence - sourceConfidence
                : null;

        final double? sourceScore =
            inSource ? _parseDouble(sourceNode!['score']) : null;
        final double? targetScore =
            inTarget ? _parseDouble(targetNode!['score']) : null;
        final double? scoreDelta = (sourceScore != null && targetScore != null)
            ? targetScore - sourceScore
            : null;

        final pruningStatusChanged =
            inSource && inTarget && (sourcePruned != targetPruned);
        final sourcePruningReason =
            inSource ? sourceNode!['pruningReason'] as String? : null;
        final targetPruningReason =
            inTarget ? targetNode!['pruningReason'] as String? : null;

        // Build list of changed fields
        final changedFields = <String>[];
        if (inSource && inTarget) {
          if (sourceScore != targetScore) {
            changedFields.add('score');
          }
          if (sourceProb != targetProb) {
            changedFields.add('probability');
          }
          if (sourceImpact != targetImpact) {
            changedFields.add('impact');
          }
          if (sourceCost != targetCost) {
            changedFields.add('cost');
          }
          if (sourceConfidence != targetConfidence) {
            changedFields.add('confidence');
          }
          if (sourcePruned != targetPruned) {
            changedFields.add('pruningStatus');
          }
          if (sourcePruningReason != targetPruningReason) {
            changedFields.add('pruningReason');
          }

          if (changedFields.isNotEmpty) {
            modifiedNodeIds.add(nodeId);
          }
        } else if (inTarget) {
          changedFields.add('exists');
          if (targetScore != null) changedFields.add('score');
          if (targetProb != null) changedFields.add('probability');
          if (targetImpact != null) changedFields.add('impact');
          if (targetCost != null) changedFields.add('cost');
          if (targetConfidence != null) changedFields.add('confidence');
          if (targetPruned) changedFields.add('pruningStatus');
          if (targetPruningReason != null) changedFields.add('pruningReason');
        } else if (inSource) {
          changedFields.add('exists');
          if (sourceScore != null) changedFields.add('score');
          if (sourceProb != null) changedFields.add('probability');
          if (sourceImpact != null) changedFields.add('impact');
          if (sourceCost != null) changedFields.add('cost');
          if (sourceConfidence != null) changedFields.add('confidence');
          if (sourcePruned) changedFields.add('pruningStatus');
          if (sourcePruningReason != null) changedFields.add('pruningReason');
        }

        nodeMetricDiffs[nodeId] = NodeMetricDiff(
          nodeId: nodeId,
          existsInSource: inSource,
          existsInTarget: inTarget,
          changedFields: changedFields,
          probabilityDelta: probabilityDelta,
          impactDelta: impactDelta,
          costDelta: costDelta,
          confidenceDelta: confidenceDelta,
          scoreDelta: scoreDelta,
          pruningStatusChanged: pruningStatusChanged,
          sourcePruningReason: sourcePruningReason,
          targetPruningReason: targetPruningReason,
        );
      }

      final traceDiff =
          TraceDiff.compare(source.runtimeTraces, target.runtimeTraces);

      final summary = _generateSummary(
        pathChanged: pathChanged,
        sourcePath: sourceSelectedPath,
        targetPath: targetSelectedPath,
        utilityDelta: utilityDelta,
        added: addedNodeIds,
        removed: removedNodeIds,
        modified: modifiedNodeIds,
      );

      return SnapshotDiff(
        sourceSchemaVersion: source.schemaVersion,
        targetSchemaVersion: target.schemaVersion,
        sourceEngineVersion: source.engineVersion,
        targetEngineVersion: target.engineVersion,
        pathChanged: pathChanged,
        sourceSelectedPath: sourceSelectedPath,
        targetSelectedPath: targetSelectedPath,
        sourceUtility: sourceUtility,
        targetUtility: targetUtility,
        utilityDelta: utilityDelta,
        addedNodeIds: addedNodeIds,
        removedNodeIds: removedNodeIds,
        modifiedNodeIds: modifiedNodeIds,
        newlyPrunedNodeIds: newlyPrunedNodeIds,
        newlyUnprunedNodeIds: newlyUnprunedNodeIds,
        nodeMetricDiffs: nodeMetricDiffs,
        traceDiff: traceDiff,
        summary: summary,
      );
    } catch (e) {
      if (e is SnapshotDiffException) rethrow;
      throw SnapshotDiffCorruptException(
          'Failed to execute deterministic session comparison: $e');
    }
  }

  /// Compares two [DebugSnapshot] instances offline and synchronously.
  static SnapshotDiff compareSnapshots({
    required DebugSnapshot source,
    required DebugSnapshot target,
  }) {
    final sourceSession = ReplayLoader.load(source);
    final targetSession = ReplayLoader.load(target);
    return compareSessions(source: sourceSession, target: targetSession);
  }

  /// Compares two canonical JSON strings offline and synchronously.
  static SnapshotDiff compareCanonicalJson({
    required String sourceJson,
    required String targetJson,
  }) {
    final sourceSession = ReplayLoader.loadCanonicalJson(sourceJson);
    final targetSession = ReplayLoader.loadCanonicalJson(targetJson);
    return compareSessions(source: sourceSession, target: targetSession);
  }

  static double _getUtility(ReplaySession session) {
    final trav = session.snapshot.traversalSummaries;
    final rawUtil = trav['totalUtility'];
    final parsed = _parseDouble(rawUtil);
    if (parsed != null) return parsed;

    if (session.selectedPath.isNotEmpty) {
      final lastNodeId = session.selectedPath.last;
      final lastNodeData = session.nodeSnapshots[lastNodeId];
      if (lastNodeData != null) {
        final score = _parseDouble(lastNodeData['score']);
        if (score != null) return score;
      }
    }
    return 0.0;
  }

  static double? _parseDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _listNotEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  static String _generateSummary({
    required bool pathChanged,
    required List<String> sourcePath,
    required List<String> targetPath,
    required double utilityDelta,
    required List<String> added,
    required List<String> removed,
    required List<String> modified,
  }) {
    if (!pathChanged &&
        utilityDelta == 0.0 &&
        added.isEmpty &&
        removed.isEmpty &&
        modified.isEmpty) {
      return 'Evaluations are identical across selected path, total utility, and node metrics.';
    }

    final buffer = StringBuffer();
    if (pathChanged) {
      buffer.write(
          'Selected pathway changed from [${sourcePath.join(" → ")}] to [${targetPath.join(" → ")}]. ');
    } else {
      buffer.write(
          'Selected pathway remains unchanged [${sourcePath.join(" → ")}]. ');
    }

    final deltaStr = utilityDelta > 0
        ? '+${utilityDelta.toStringAsFixed(4)}'
        : utilityDelta.toStringAsFixed(4);
    buffer.write('Utility delta: $deltaStr. ');

    final parts = <String>[];
    if (added.isNotEmpty) parts.add('${added.length} node(s) added');
    if (removed.isNotEmpty) parts.add('${removed.length} node(s) removed');
    if (modified.isNotEmpty) parts.add('${modified.length} node(s) modified');

    if (parts.isNotEmpty) {
      buffer.write('Structure changed: ${parts.join(", ")}.');
    } else {
      buffer.write('Structure remains identical.');
    }

    return buffer.toString();
  }
}
