import 'replay_exceptions.dart';
import 'replay_session.dart';

/// Provides query and inspection APIs over a [ReplaySession]'s reconstructed states.
class ReplayInspector {
  /// The active [ReplaySession] being inspected.
  final ReplaySession session;

  /// Creates a [ReplayInspector] instance.
  ReplayInspector(this.session);

  /// Checks if a node ID exists in the reconstructed snapshot dataset.
  bool containsNode(String nodeId) {
    return session.nodeSnapshots.containsKey(nodeId);
  }

  /// Retrieves a specific node's attributes from the reconstructed snapshot.
  /// Throws [ReplayCorruptException] if the node is missing.
  Map<String, Object?> inspectNode(String nodeId) {
    final node = session.nodeSnapshots[nodeId];
    if (node == null) {
      throw ReplayCorruptException(
        'Requested node "$nodeId" is missing from nodeSnapshots.',
        missingNodeId: nodeId,
      );
    }
    return node;
  }

  /// Returns the node metric snapshots for the selected optimal path,
  /// preserving their original traversal sequence.
  List<Map<String, Object?>> inspectSelectedPath() {
    final pathNodes = <Map<String, Object?>>[];
    for (final nodeId in session.selectedPath) {
      final node = session.nodeSnapshots[nodeId];
      if (node == null) {
        throw ReplayCorruptException(
          'Selected path node "$nodeId" is missing from nodeSnapshots during inspection.',
          missingNodeId: nodeId,
        );
      }
      pathNodes.add(node);
    }
    return List<Map<String, Object?>>.unmodifiable(pathNodes);
  }

  /// Returns the node metric snapshots for all pruned nodes,
  /// sorted lexicographically by their unique node identifier.
  List<Map<String, Object?>> inspectPrunedNodes() {
    final prunedNodes = <Map<String, Object?>>[];
    for (final nodeId in session.prunedNodeIds) {
      final node = session.nodeSnapshots[nodeId];
      if (node != null) {
        prunedNodes.add(node);
      }
    }

    // Sort alphabetically by the 'id' key inside the node maps.
    final sortedList = List<Map<String, Object?>>.from(prunedNodes)
      ..sort((a, b) {
        final aId = (a['id'] as String? ?? '').toString();
        final bId = (b['id'] as String? ?? '').toString();
        return aId.compareTo(bId);
      });

    return List<Map<String, Object?>>.unmodifiable(sortedList);
  }

  /// Returns the chronological runtime trace log lines.
  List<String> runtimeTraceLines() {
    return session.runtimeTraces;
  }

  /// Returns the detailed pruning trace log lines.
  List<String> pruningTraceLines() {
    return session.pruningTraces;
  }
}
