import 'dart:convert';
import 'package:branchiq/branchiq.dart';

// Constructs a balanced binary decision tree of a given depth.
// Returns a flat list of all nodes.
List<DecisionNode> _buildBalancedTree(int depth) {
  final nodes = <DecisionNode>[];
  final queue = <({String id, String? parentId, int level})>[
    (id: 'root', parentId: null, level: 0),
  ];

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    final isLeaf = current.level >= depth;

    final childIds =
        isLeaf ? <String>[] : ['${current.id}_L', '${current.id}_R'];

    nodes.add(DecisionNode(
      id: current.id,
      parentId: current.parentId,
      childIds: childIds,
      probability: 0.9,
      impact: 0.6,
      cost: 30.0,
      depth: current.level,
    ));

    if (!isLeaf) {
      for (final childId in childIds) {
        queue
            .add((id: childId, parentId: current.id, level: current.level + 1));
      }
    }
  }
  return nodes;
}

void _printBenchmark(String label, BenchmarkSnapshot bench) {
  print('--- $label ---');
  print('  Total Nodes:               ${bench.totalNodes}');
  print('  Traversal Iterations:      ${bench.traversalIterations}');
  print('  Execution Steps:           ${bench.executionSteps}');
  print('  Retained Nodes:            ${bench.retainedNodes}');
  print('  Pruned Nodes:              ${bench.prunedNodes}');
  print('  Selected Path Length:      ${bench.selectedPathLength}');
  print('  Est. Allocation Count:     ${bench.estimatedAllocationCount}');
  print('  Runtime State:             ${bench.runtimeState}');
  print('');
}

void main() {
  print('=== BranchIQ Benchmark Mode Example ===\n');
  print('BranchIQ benchmarks are deterministic — no wall-clock timers or');
  print('Stopwatches are used. Metrics represent structured execution counts:');
  print('scoring steps, traversal iterations, and estimated allocations.\n');

  final engine = BranchIQEngine.createSync();
  final scoringConfig = ScoringConfig.balanced(costCeiling: 100.0);
  final pruningConfig = PruningConfig.defaultSettings();
  const traversalConfig = TraversalConfig();

  // --- Benchmark 1: Small Tree (depth 2, 7 nodes) ---
  final smallNodes = _buildBalancedTree(2);
  final smallTree = DecisionTree.fromNodes(smallNodes);

  final smallResult = engine.evaluateSync(
    tree: smallTree,
    scoringConfig: scoringConfig,
    pruningConfig: pruningConfig,
    traversalConfig: traversalConfig,
    enableBenchmark: true,
  );

  _printBenchmark(
    'Small Tree (depth=2, ~7 nodes)',
    smallResult.benchmarkSnapshot!,
  );

  // --- Benchmark 2: Medium Tree (depth 4, 31 nodes) ---
  final mediumNodes = _buildBalancedTree(4);
  final mediumTree = DecisionTree.fromNodes(mediumNodes);

  final mediumResult = engine.evaluateSync(
    tree: mediumTree,
    scoringConfig: scoringConfig,
    pruningConfig: pruningConfig,
    traversalConfig: traversalConfig,
    enableBenchmark: true,
  );

  _printBenchmark(
    'Medium Tree (depth=4, ~31 nodes)',
    mediumResult.benchmarkSnapshot!,
  );

  // --- Benchmark 3: Demonstrating deterministic replay ---
  // Running the same benchmark twice always produces identical metrics.
  print('--- Determinism Verification: Running Medium Benchmark 3x ---');
  final runs = List.generate(
      3,
      (_) => engine.evaluateSync(
            tree: mediumTree,
            scoringConfig: scoringConfig,
            pruningConfig: pruningConfig,
            traversalConfig: traversalConfig,
            enableBenchmark: true,
          ));

  final benchmarkJsons =
      runs.map((r) => jsonEncode(r.benchmarkSnapshot!.toJson())).toSet();

  if (benchmarkJsons.length == 1) {
    print('  All 3 runs produced identical BenchmarkSnapshot output. PASS');
  } else {
    print('  MISMATCH: runs differed (this should never happen).');
  }
  print('');

  // --- Philosophy Note ---
  print('--- Bounded Execution Philosophy ---');
  print('BranchIQ guarantees:');
  print(
      '  - No unbounded loops: node counts, depths, and iterations are all capped.');
  print(
      '  - No randomness:      identical input always produces identical output.');
  print(
      '  - No external timing: metrics are step/iteration counts, not clock durations.');
  print(
      '  - Reproducible:       benchmark snapshots can be serialized and stored.');
  print('');
  print('Benchmark snapshot (JSON):');
  const encoder = JsonEncoder.withIndent('  ');
  print(encoder.convert(mediumResult.benchmarkSnapshot!.toJson()));
}
