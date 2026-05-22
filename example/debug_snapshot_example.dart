import 'dart:convert';
import 'package:branchiq/branchiq.dart';

void main() {
  print('=== BranchIQ Debug Snapshot Example ===\n');

  // Build a tree to inspect.
  final root = DecisionNode(
    id: 'root',
    childIds: ['approve', 'defer', 'reject'],
    depth: 0,
  );

  final approve = DecisionNode(
    id: 'approve',
    parentId: 'root',
    childIds: ['approve_fast', 'approve_reviewed'],
    probability: 0.85,
    impact: 0.7,
    cost: 50.0,
    depth: 1,
  );

  final approveFast = DecisionNode(
    id: 'approve_fast',
    parentId: 'approve',
    childIds: [],
    probability: 0.95,
    impact: 0.6,
    cost: 20.0,
    depth: 2,
  );

  final approveReviewed = DecisionNode(
    id: 'approve_reviewed',
    parentId: 'approve',
    childIds: [],
    probability: 0.7,
    impact: 0.9,
    cost: 80.0,
    depth: 2,
  );

  final defer = DecisionNode(
    id: 'defer',
    parentId: 'root',
    childIds: [],
    probability: 0.6,
    impact: 0.2,
    cost: 10.0,
    depth: 1,
  );

  final reject = DecisionNode(
    id: 'reject',
    parentId: 'root',
    childIds: [],
    probability: 0.02, // Will be pruned by minProbability
    impact: -0.3,
    cost: 5.0,
    depth: 1,
  );

  final tree = DecisionTree.fromNodes([
    root,
    approve,
    approveFast,
    approveReviewed,
    defer,
    reject,
  ]);

  final engine = BranchIQEngine.createSync();

  final result = engine.evaluateSync(
    tree: tree,
    scoringConfig: ScoringConfig.balanced(costCeiling: 100.0),
    pruningConfig: PruningConfig(
      minProbability: 0.05,
      minScore: -1.0,
      beamWidth: 3,
      maxDepth: 4,
      maxNodeLimit: 100,
    ),
    traversalConfig: const TraversalConfig(),
    enableDebug: true, // Enable full debug snapshot collection
  );

  // --- 1. Basic Outcome ---
  print('--- Evaluation Outcome ---');
  print('Runtime State: ${result.runtimeState}');
  print('Selected Path: ${result.bestPath.nodeIds.join(' -> ')}');
  print('Total Utility: ${result.totalUtility.toStringAsFixed(4)}');
  print('');

  // --- 2. Runtime Traces ---
  // Traces show each pipeline phase: validation, scoring, pruning, traversal.
  print('--- Runtime Traces ---');
  for (final trace in result.traces) {
    print('  $trace');
  }
  print('');

  // --- 3. Export and Inspect the DebugSnapshot ---
  final snapshot = engine.exportDebugSnapshot(result);

  print('--- Debug Snapshot Overview ---');
  print('Engine Version:  ${snapshot.engineVersion}');
  print('Root Node ID:    ${snapshot.rootId}');
  print('Selected Path:   ${snapshot.selectedPath.join(' -> ')}');
  print('Pruned Node IDs: ${snapshot.prunedNodeIds.join(', ')}');
  print('');

  // --- 4. Per-Node Scoring Details ---
  print('--- Per-Node Scoring Snapshot ---');
  final sortedIds = snapshot.nodeSnapshots.keys.toList()..sort();
  for (final id in sortedIds) {
    final nodeData = snapshot.nodeSnapshots[id]!;
    final pruned = nodeData['pruningReason'] != null
        ? '  PRUNED (${nodeData['pruningReason']})'
        : '';
    print('  [$id] score=${(nodeData['score'] as double).toStringAsFixed(4)}'
        '  confidence=${(nodeData['confidence'] as double).toStringAsFixed(4)}'
        '  depth=${nodeData['depth']}$pruned');
  }
  print('');

  // --- 5. Traversal & Scoring Summaries ---
  print('--- Traversal Summaries ---');
  for (final entry in snapshot.traversalSummaries.entries) {
    print('  ${entry.key}: ${entry.value}');
  }
  print('');
  print('--- Scoring Summaries ---');
  for (final entry in snapshot.scoringSummaries.entries) {
    print('  ${entry.key}: ${entry.value}');
  }
  print('');

  // --- 6. Full JSON Export ---
  // The full debug snapshot can be serialized for logging or storage.
  print('--- Full Debug Snapshot (JSON) ---');
  const encoder = JsonEncoder.withIndent('  ');
  print(encoder.convert(snapshot.toJson()));
}
