import 'package:branchiq/branchiq.dart';

void main() {
  print(
      '================================================================================');
  print(
      '                  BranchIQ Bounded Deterministic Benchmark Runner                ');
  print(
      '================================================================================\n');

  final engine = BranchIQEngine.createSync();
  final scoringConfig = ScoringConfig.balanced();
  final pruningConfig = PruningConfig.defaultSettings();
  const traversalConfig = TraversalConfig();

  // 1. Benchmark: Deep Chain Tree
  print('## Benchmark 1: Deep Chain Tree (Max Depth Limit = 12)');
  final deepTree = _generateDeepChainTree(12);
  final deepResult = engine.evaluateSync(
    tree: deepTree,
    scoringConfig: scoringConfig,
    pruningConfig: pruningConfig,
    traversalConfig: traversalConfig,
    enableBenchmark: true,
  );
  _printResult(deepResult);

  // 2. Benchmark: Wide Tree
  print('## Benchmark 2: Wide Fan-Out Tree (Max Sibling Limit = 10)');
  final wideTree = _generateWideTree(10);
  final wideResult = engine.evaluateSync(
    tree: wideTree,
    scoringConfig: scoringConfig,
    pruningConfig: pruningConfig,
    traversalConfig: traversalConfig,
    enableBenchmark: true,
  );
  _printResult(wideResult);

  // 3. Benchmark: Balanced Tree
  print('## Benchmark 3: Balanced Binary Tree (Depth = 4, Nodes = 31)');
  final balancedTree = _generateBalancedBinaryTree(4);
  final balancedResult = engine.evaluateSync(
    tree: balancedTree,
    scoringConfig: scoringConfig,
    pruningConfig: pruningConfig,
    traversalConfig: traversalConfig,
    enableBenchmark: true,
  );
  _printResult(balancedResult);

  print(
      '================================================================================');
  print(
      '                  Benchmark execution successfully completed                   ');
  print(
      '================================================================================');
}

DecisionTree _generateDeepChainTree(int depth) {
  final nodes = <DecisionNode>[];
  for (int d = 1; d <= depth; d++) {
    nodes.add(
      DecisionNode.constant(
        id: 'node_$d',
        parentId: d == 1 ? 'root' : 'node_${d - 1}',
        childIds: d == depth ? const [] : ['node_${d + 1}'],
        depth: d,
        score: 0.9,
        confidence: 0.95,
      ),
    );
  }
  final root = DecisionNode.constant(
    id: 'root',
    parentId: null,
    childIds: depth > 0 ? ['node_1'] : const [],
    depth: 0,
    score: 0.9,
    confidence: 1.0,
  );
  nodes.add(root);
  return DecisionTree.fromNodes(nodes);
}

DecisionTree _generateWideTree(int childCount) {
  final childIds = List.generate(childCount, (i) => 'child_$i');
  final nodes = <DecisionNode>[];
  for (final cid in childIds) {
    nodes.add(
      DecisionNode.constant(
        id: cid,
        parentId: 'root',
        childIds: const [],
        depth: 1,
        score: 0.5 +
            (childIds.indexOf(cid) * 0.04), // deterministic varying scores
        confidence: 0.9,
      ),
    );
  }
  final root = DecisionNode.constant(
    id: 'root',
    parentId: null,
    childIds: childIds,
    depth: 0,
    score: 0.8,
    confidence: 1.0,
  );
  nodes.add(root);
  return DecisionTree.fromNodes(nodes);
}

DecisionTree _generateBalancedBinaryTree(int maxDepth) {
  final nodes = <DecisionNode>[];

  void createChildren(String parentId, int depth, int siblingIndex) {
    if (depth > maxDepth) return;

    final leftId = '${parentId}_l';
    final rightId = '${parentId}_r';

    nodes.add(DecisionNode.constant(
      id: leftId,
      parentId: parentId,
      childIds: depth == maxDepth ? const [] : ['${leftId}_l', '${leftId}_r'],
      depth: depth,
      score: 0.8 - (depth * 0.05),
      confidence: 0.9,
    ));

    nodes.add(DecisionNode.constant(
      id: rightId,
      parentId: parentId,
      childIds: depth == maxDepth ? const [] : ['${rightId}_l', '${rightId}_r'],
      depth: depth,
      score: 0.75 - (depth * 0.05),
      confidence: 0.85,
    ));

    createChildren(leftId, depth + 1, 0);
    createChildren(rightId, depth + 1, 1);
  }

  final root = const DecisionNode.constant(
    id: 'root',
    parentId: null,
    childIds: ['root_l', 'root_r'],
    depth: 0,
    score: 0.9,
    confidence: 1.0,
  );
  nodes.add(root);

  createChildren('root', 1, 0);

  return DecisionTree.fromNodes(nodes);
}

void _printResult(EvaluationResult result) {
  final bench = result.benchmarkSnapshot;
  if (bench == null) {
    print('Error: Benchmark mode was not successfully configured.\n');
    return;
  }

  print('| Metric | Value |');
  print('| :--- | :--- |');
  print('| **Total Nodes** | ${bench.totalNodes} |');
  print('| **Traversal Iterations** | ${bench.traversalIterations} |');
  print('| **Execution Steps** | ${bench.executionSteps} |');
  print('| **Retained Nodes** | ${bench.retainedNodes} |');
  print('| **Pruned Nodes** | ${bench.prunedNodes} |');
  print('| **Selected Path Length** | ${bench.selectedPathLength} |');
  print(
      '| **Estimated Allocation Count** | ${bench.estimatedAllocationCount} |');
  print('| **Runtime State** | ${bench.runtimeState} |');
  print('| **Selected Path** | `${result.bestPath.nodeIds.join(' -> ')}` |');
  print(
      '| **Total Path Utility** | ${result.totalUtility.toStringAsFixed(4)} |\n');
}
