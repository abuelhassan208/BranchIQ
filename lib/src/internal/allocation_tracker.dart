/// Lightweight allocation and operations accounting for performance analysis.
class AllocationTracker {
  /// The count of nodes that went through scoring calculation.
  final int nodesScored;

  /// The count of nodes pruned during pruning phases.
  final int nodesPruned;

  /// The count of nodes visited during traversal.
  final int nodesTraversed;

  /// The count of debug/evaluation snapshots generated.
  final int snapshotsGenerated;

  /// Creates a new [AllocationTracker] instance.
  const AllocationTracker({
    this.nodesScored = 0,
    this.nodesPruned = 0,
    this.nodesTraversed = 0,
    this.snapshotsGenerated = 0,
  });

  /// Tracks scoring of a single node.
  AllocationTracker trackNodeScored() {
    return AllocationTracker(
      nodesScored: nodesScored + 1,
      nodesPruned: nodesPruned,
      nodesTraversed: nodesTraversed,
      snapshotsGenerated: snapshotsGenerated,
    );
  }

  /// Tracks scoring of multiple nodes at once to reduce intermediate allocations.
  AllocationTracker trackNodesScored(int count) {
    return AllocationTracker(
      nodesScored: nodesScored + count,
      nodesPruned: nodesPruned,
      nodesTraversed: nodesTraversed,
      snapshotsGenerated: snapshotsGenerated,
    );
  }

  /// Tracks pruning of a single node.
  AllocationTracker trackNodePruned() {
    return AllocationTracker(
      nodesScored: nodesScored,
      nodesPruned: nodesPruned + 1,
      nodesTraversed: nodesTraversed,
      snapshotsGenerated: snapshotsGenerated,
    );
  }

  /// Tracks pruning of multiple nodes.
  AllocationTracker trackNodesPruned(int count) {
    return AllocationTracker(
      nodesScored: nodesScored,
      nodesPruned: nodesPruned + count,
      nodesTraversed: nodesTraversed,
      snapshotsGenerated: snapshotsGenerated,
    );
  }

  /// Tracks traversal of a single node.
  AllocationTracker trackNodeTraversed() {
    return AllocationTracker(
      nodesScored: nodesScored,
      nodesPruned: nodesPruned,
      nodesTraversed: nodesTraversed + 1,
      snapshotsGenerated: snapshotsGenerated,
    );
  }

  /// Tracks traversal of multiple nodes.
  AllocationTracker trackNodesTraversed(int count) {
    return AllocationTracker(
      nodesScored: nodesScored,
      nodesPruned: nodesPruned,
      nodesTraversed: nodesTraversed + count,
      snapshotsGenerated: snapshotsGenerated,
    );
  }

  /// Tracks generation of a debug snapshot.
  AllocationTracker trackSnapshotGenerated() {
    return AllocationTracker(
      nodesScored: nodesScored,
      nodesPruned: nodesPruned,
      nodesTraversed: nodesTraversed,
      snapshotsGenerated: snapshotsGenerated + 1,
    );
  }
}
