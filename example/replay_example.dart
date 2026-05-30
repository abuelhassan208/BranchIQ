import 'package:branchiq/branchiq.dart';

/// BranchIQ v0.2 Replay Example
///
/// Demonstrates the complete snapshot-driven replay lifecycle:
///   1. Run engine with debug enabled
///   2. Serialize snapshot to canonical JSON
///   3. Reconstruct a ReplaySession from that string
///   4. Query the session using ReplayInspector
///
/// This example uses ONLY public APIs exported from `package:branchiq`.
void main() {
  print('=== BranchIQ Replay Example ===\n');

  // ──────────────────────────────────────────────
  // 1. Build and evaluate a decision tree
  // ──────────────────────────────────────────────
  final tree = DecisionTree.fromNodes([
    DecisionNode(
      id: 'root',
      childIds: ['approve', 'defer', 'reject'],
      depth: 0,
    ),
    DecisionNode(
      id: 'approve',
      parentId: 'root',
      childIds: ['approve_auto', 'approve_manual'],
      probability: 0.85,
      impact: 0.7,
      cost: 50.0,
      depth: 1,
    ),
    DecisionNode(
      id: 'approve_auto',
      parentId: 'approve',
      childIds: [],
      probability: 0.95,
      impact: 0.6,
      cost: 10.0,
      depth: 2,
    ),
    DecisionNode(
      id: 'approve_manual',
      parentId: 'approve',
      childIds: [],
      probability: 0.70,
      impact: 0.9,
      cost: 90.0,
      depth: 2,
    ),
    DecisionNode(
      id: 'defer',
      parentId: 'root',
      childIds: [],
      probability: 0.60,
      impact: 0.2,
      cost: 5.0,
      depth: 1,
    ),
    DecisionNode(
      id: 'reject',
      parentId: 'root',
      childIds: [],
      probability: 0.02,
      impact: -0.3,
      cost: 1.0,
      depth: 1,
    ),
  ]);

  final engine = BranchIQEngine.createSync();

  final result = engine.evaluateSync(
    tree: tree,
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

  print('--- Original Evaluation ---');
  print('Selected Path: ${result.bestPath.nodeIds.join(' → ')}');
  print('Total Utility:  ${result.totalUtility.toStringAsFixed(4)}');
  print('');

  // ──────────────────────────────────────────────
  // 2. Export snapshot & serialize to canonical JSON
  // ──────────────────────────────────────────────
  final snapshot = engine.exportDebugSnapshot(result);

  // Load the snapshot into a ReplaySession
  final session = ReplayLoader.load(snapshot);

  // Serialize to a byte-identical canonical string (safe for storage, diffing, etc.)
  final canonicalJson = session.toCanonicalJson();
  print('--- Canonical JSON (first 200 chars) ---');
  print(canonicalJson.substring(0, canonicalJson.length.clamp(0, 200)));
  print('... (${canonicalJson.length} bytes total)');
  print('');

  // ──────────────────────────────────────────────
  // 3. Reconstruct session from canonical JSON (simulates loading from disk)
  // ──────────────────────────────────────────────
  final restoredSession = ReplayLoader.loadCanonicalJson(canonicalJson);

  print('--- Restored Session ---');
  print('Schema Version: ${restoredSession.schemaVersion}');
  print('Engine Version: ${restoredSession.engineVersion}');
  print('Root ID:        ${restoredSession.rootId}');
  print('Selected Path:  ${restoredSession.selectedPath.join(' → ')}');
  print('Pruned Nodes:   ${restoredSession.prunedNodeIds.join(', ')}');
  print('');

  // Verify byte-identity: the restored session produces the exact same canonical output
  final restoredCanonical = restoredSession.toCanonicalJson();
  assert(canonicalJson == restoredCanonical,
      'Canonical roundtrip MUST be byte-identical');
  print('✓ Canonical roundtrip verified — byte-identical');
  print('');

  // ──────────────────────────────────────────────
  // 4. Inspect the session using ReplayInspector
  // ──────────────────────────────────────────────
  final inspector = ReplayInspector(restoredSession);

  print('--- Path Inspection (traversal order) ---');
  final pathNodes = inspector.inspectSelectedPath();
  for (final node in pathNodes) {
    print('  [${node['id']}]  score=${node['score']}  depth=${node['depth']}');
  }
  print('');

  print('--- Pruned Node Inspection (lexicographic order) ---');
  final prunedNodes = inspector.inspectPrunedNodes();
  if (prunedNodes.isEmpty) {
    print('  (no pruned nodes with snapshot data)');
  } else {
    for (final node in prunedNodes) {
      print(
          '  [${node['id']}]  score=${node['score']}  depth=${node['depth']}');
    }
  }
  print('');

  print('--- Runtime Traces ---');
  for (final trace in inspector.runtimeTraceLines()) {
    print('  $trace');
  }
  print('');

  print('--- Pruning Traces ---');
  for (final trace in inspector.pruningTraceLines()) {
    print('  $trace');
  }
  print('');

  // ──────────────────────────────────────────────
  // 5. Individual node lookup
  // ──────────────────────────────────────────────
  print('--- Single Node Lookup ---');
  if (inspector.containsNode('approve')) {
    final approveData = inspector.inspectNode('approve');
    print('  Node "approve":');
    for (final entry in approveData.entries) {
      print('    ${entry.key}: ${entry.value}');
    }
  }
  print('');

  // Demonstrate error handling for missing nodes
  print('--- Missing Node Handling ---');
  try {
    inspector.inspectNode('nonexistent_node');
  } on ReplayCorruptException catch (e) {
    print('  Caught expected error: $e');
  }

  print('\n=== Replay Example Complete ===');
}
