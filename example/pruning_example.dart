import 'package:branchiq/branchiq.dart';

// Helper to display pruned vs retained nodes from the debug snapshot.
void _printPruningSummary(EvaluationResult result) {
  final snapshot = result.debugSnapshot;
  if (snapshot == null) {
    print('No debug snapshot available.');
    return;
  }

  final retained = <String>[];
  final pruned = <String, String>{};

  for (final entry in snapshot.nodeSnapshots.entries) {
    final reason = entry.value['pruningReason'] as String?;
    if (reason != null && reason != 'none' && reason.isNotEmpty) {
      pruned[entry.key] = reason;
    } else {
      retained.add(entry.key);
    }
  }

  retained.sort();
  final prunedKeys = pruned.keys.toList()..sort();

  print('  Retained Nodes [${retained.length}]: ${retained.join(', ')}');
  print('  Pruned Nodes   [${prunedKeys.length}]:');
  for (final id in prunedKeys) {
    print('    - "$id": reason = ${pruned[id]}');
  }
}

void main() {
  print('=== BranchIQ Pruning Behavior Example ===\n');

  // Build a moderately complex 3-branch tree.
  // - "safe"   : high probability, modest impact
  // - "risky"  : very low probability (will be pruned by minProbability)
  // - "costly" : low score after cost penalization (will be pruned by minScore)
  // - Additionally, siblings "b1".."b4" exceed the beamWidth and get beam-pruned.
  final root = DecisionNode(
    id: 'root',
    childIds: ['safe', 'risky', 'costly', 'b1', 'b2', 'b3', 'b4'],
    depth: 0,
  );

  final safe = DecisionNode(
    id: 'safe',
    parentId: 'root',
    childIds: [],
    probability: 0.9,
    impact: 0.5,
    cost: 20.0,
    depth: 1,
  );

  final risky = DecisionNode(
    id: 'risky',
    parentId: 'root',
    childIds: [],
    probability: 0.03, // Below minProbability threshold -> pruned
    impact: 0.9,
    cost: 5.0,
    depth: 1,
  );

  final costly = DecisionNode(
    id: 'costly',
    parentId: 'root',
    childIds: [],
    probability: 0.8,
    impact: -0.5, // Very low (negative) impact -> score below minScore
    cost: 900.0, // High cost
    depth: 1,
  );

  // Extra siblings to trigger beam width pruning (beamWidth=3 allows only top 3).
  final siblings = ['b1', 'b2', 'b3', 'b4'].map((id) => DecisionNode(
        id: id,
        parentId: 'root',
        childIds: [],
        probability: 0.5,
        impact: 0.1,
        cost: 50.0,
        depth: 1,
      ));

  final tree = DecisionTree.fromNodes([
    root,
    safe,
    risky,
    costly,
    ...siblings,
  ]);

  final engine = BranchIQEngine.createSync();
  final scoringConfig = ScoringConfig.balanced(costCeiling: 1000.0);

  // Configure pruning thresholds:
  // - minProbability: nodes with p < 0.05 are pruned
  // - minScore:       nodes with score < 0.0 are pruned
  // - beamWidth:      only the top 3 children at each level are retained
  final pruningConfig = PruningConfig(
    minProbability: 0.05,
    minScore: 0.0,
    beamWidth: 3,
    maxDepth: 4,
    maxNodeLimit: 100,
  );

  final result = engine.evaluateSync(
    tree: tree,
    scoringConfig: scoringConfig,
    pruningConfig: pruningConfig,
    traversalConfig: const TraversalConfig(),
    enableDebug: true,
  );

  print('Runtime State:  ${result.runtimeState}');
  print('Selected Path:  ${result.bestPath.nodeIds.join(' -> ')}');
  print('Total Utility:  ${result.totalUtility.toStringAsFixed(4)}');
  print('');

  // --- Pruning Breakdown ---
  print('--- Pruning Breakdown ---');
  print('Rules applied:');
  print('  1. minProbability = 0.05  -> removes "risky" (p=0.03)');
  print(
      '  2. minScore       = 0.0   -> removes "costly" (negative impact + high cost)');
  print(
      '  3. beamWidth      = 3     -> removes excess siblings beyond top 3 by score');
  print('');
  _printPruningSummary(result);
  print('');

  // --- Fallback Scenario ---
  // Show that if ALL branches get pruned, the engine gracefully falls back to root.
  print('--- Fallback Scenario: All Branches Pruned ---');
  final aggressivePruning = PruningConfig(
    minProbability:
        1.0, // Demands p == 1.0 exactly — virtually no node qualifies
    minScore: 0.99, // Demands near-perfect score
    beamWidth: 1,
    maxDepth: 4,
    maxNodeLimit: 100,
  );

  final fallbackResult = engine.evaluateSync(
    tree: tree,
    scoringConfig: scoringConfig,
    pruningConfig: aggressivePruning,
    traversalConfig: const TraversalConfig(),
  );

  print('Runtime State:  ${fallbackResult.runtimeState}');
  print('Selected Path:  ${fallbackResult.bestPath.nodeIds.join(' -> ')}');
  print(
      'Note: When all children are pruned, the engine falls back to the root node '
      'rather than failing.');
}
