import 'package:branchiq/branchiq.dart';

/// BranchIQ v0.2 Snapshot Diffing Example
///
/// Demonstrates:
///   1. Build and evaluate a decision tree under two slightly different scenarios.
///   2. Export the execution snapshots.
///   3. Compare the snapshots deterministically using [SnapshotDiffer].
///   4. Print the beautiful markdown diff output.
///
/// Uses ONLY public APIs exported from `package:branchiq`.
void main() {
  print('=== BranchIQ Snapshot Diffing Example ===\n');

  // Scenario A: Standard Tree (Low approve_auto cost)
  final treeA = DecisionTree.fromNodes([
    DecisionNode(id: 'root', childIds: ['approve', 'defer'], depth: 0),
    DecisionNode(
      id: 'approve',
      parentId: 'root',
      childIds: ['approve_auto'],
      probability: 0.90,
      impact: 0.8,
      cost: 40.0,
      depth: 1,
    ),
    DecisionNode(
      id: 'approve_auto',
      parentId: 'approve',
      childIds: [],
      probability: 0.95,
      impact: 0.7,
      cost: 10.0, // Low cost
      depth: 2,
    ),
    DecisionNode(
      id: 'defer',
      parentId: 'root',
      childIds: [],
      probability: 0.60,
      impact: 0.3,
      cost: 5.0,
      depth: 1,
    ),
  ]);

  // Scenario B: Slightly modified metrics (approve_auto cost and probability changed)
  final treeB = DecisionTree.fromNodes([
    DecisionNode(id: 'root', childIds: ['approve', 'defer'], depth: 0),
    DecisionNode(
      id: 'approve',
      parentId: 'root',
      childIds: ['approve_auto'],
      probability: 0.90,
      impact: 0.8,
      cost: 40.0,
      depth: 1,
    ),
    DecisionNode(
      id: 'approve_auto',
      parentId: 'approve',
      childIds: [],
      probability: 0.85, // Probability decreased slightly
      impact: 0.7,
      cost: 80.0, // Cost increased dramatically
      depth: 2,
    ),
    DecisionNode(
      id: 'defer',
      parentId: 'root',
      childIds: [],
      probability: 0.60,
      impact: 0.3,
      cost: 5.0,
      depth: 1,
    ),
  ]);

  final engine = BranchIQEngine.createSync();

  final resultA = engine.evaluateSync(
    tree: treeA,
    scoringConfig: ScoringConfig.balanced(costCeiling: 100.0),
    pruningConfig: PruningConfig(
      minProbability: 0.05,
      minScore: -1.0,
      beamWidth: 4,
      maxDepth: 5,
      maxNodeLimit: 100,
    ),
    traversalConfig: const TraversalConfig(),
    enableDebug: true,
  );

  final resultB = engine.evaluateSync(
    tree: treeB,
    scoringConfig: ScoringConfig.balanced(costCeiling: 100.0),
    pruningConfig: PruningConfig(
      minProbability: 0.05,
      minScore: -1.0,
      beamWidth: 4,
      maxDepth: 5,
      maxNodeLimit: 100,
    ),
    traversalConfig: const TraversalConfig(),
    enableDebug: true,
  );

  // 2. Export debug snapshots
  final snapA = engine.exportDebugSnapshot(resultA);
  final snapB = engine.exportDebugSnapshot(resultB);

  print('--- original paths & utilities ---');
  print('Evaluation A selected path: ${snapA.selectedPath.join(" → ")}');
  print('Evaluation B selected path: ${snapB.selectedPath.join(" → ")}\n');

  // 3. Compare Snapshots
  print('--- Comparing Snapshots (Offline) ---');
  final diff = SnapshotDiffer.compareSnapshots(source: snapA, target: snapB);
  print('Snapshot Diff generated successfully.\n');

  // 4. Output Markdown Diff Report
  print('--- Markdown Diff Report Output ---');
  print(diff.toMarkdown());

  print('=== BranchIQ Snapshot Diffing Example Complete ===');
}
