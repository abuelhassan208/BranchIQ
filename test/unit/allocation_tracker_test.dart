import 'package:branchiq/src/internal/allocation_tracker.dart';
import 'package:test/test.dart';

void main() {
  group('AllocationTracker Tests', () {
    test('initializes with zero counters', () {
      const tracker = AllocationTracker();
      expect(tracker.nodesScored, equals(0));
      expect(tracker.nodesPruned, equals(0));
      expect(tracker.nodesTraversed, equals(0));
      expect(tracker.snapshotsGenerated, equals(0));
    });

    test('tracks single node scored immutably', () {
      const t1 = AllocationTracker();
      final t2 = t1.trackNodeScored();

      expect(t1.nodesScored, equals(0));
      expect(t2.nodesScored, equals(1));
      expect(t2.nodesPruned, equals(0));
      expect(t2.nodesTraversed, equals(0));
      expect(t2.snapshotsGenerated, equals(0));
    });

    test('tracks multiple nodes scored immutably', () {
      const t1 = AllocationTracker();
      final t2 = t1.trackNodesScored(5);

      expect(t1.nodesScored, equals(0));
      expect(t2.nodesScored, equals(5));
    });

    test('tracks single node pruned immutably', () {
      const t1 = AllocationTracker();
      final t2 = t1.trackNodePruned();

      expect(t1.nodesPruned, equals(0));
      expect(t2.nodesPruned, equals(1));
      expect(t2.nodesScored, equals(0));
      expect(t2.nodesTraversed, equals(0));
      expect(t2.snapshotsGenerated, equals(0));
    });

    test('tracks multiple nodes pruned immutably', () {
      const t1 = AllocationTracker();
      final t2 = t1.trackNodesPruned(10);

      expect(t1.nodesPruned, equals(0));
      expect(t2.nodesPruned, equals(10));
    });

    test('tracks single node traversed immutably', () {
      const t1 = AllocationTracker();
      final t2 = t1.trackNodeTraversed();

      expect(t1.nodesTraversed, equals(0));
      expect(t2.nodesTraversed, equals(1));
      expect(t2.nodesScored, equals(0));
      expect(t2.nodesPruned, equals(0));
      expect(t2.snapshotsGenerated, equals(0));
    });

    test('tracks multiple nodes traversed immutably', () {
      const t1 = AllocationTracker();
      final t2 = t1.trackNodesTraversed(8);

      expect(t1.nodesTraversed, equals(0));
      expect(t2.nodesTraversed, equals(8));
    });

    test('tracks snapshot generated immutably', () {
      const t1 = AllocationTracker();
      final t2 = t1.trackSnapshotGenerated();

      expect(t1.snapshotsGenerated, equals(0));
      expect(t2.snapshotsGenerated, equals(1));
      expect(t2.nodesScored, equals(0));
      expect(t2.nodesPruned, equals(0));
      expect(t2.nodesTraversed, equals(0));
    });
  });
}
