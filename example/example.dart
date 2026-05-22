import 'package:branchiq/branchiq.dart';

void main() {
  print('=== BranchIQ Minimal Example ===\n');

  // 1. Define a simple decision tree hierarchy.
  // Nodes represent choices or states, each containing:
  // - id: unique identifier
  // - parentId: id of the parent node
  // - childIds: ids of the children nodes
  // - depth: level in the hierarchy (root is 0)
  // - probability, impact, cost: metrics used for scoring
  final root = const DecisionNode.constant(
    id: 'root',
    parentId: null,
    childIds: ['accept', 'decline'],
    depth: 0,
  );

  final accept = const DecisionNode.constant(
    id: 'accept',
    parentId: 'root',
    childIds: [],
    probability: 0.9,
    impact: 0.8,
    cost: 50.0,
    depth: 1,
  );

  final decline = const DecisionNode.constant(
    id: 'decline',
    parentId: 'root',
    childIds: [],
    probability: 0.1,
    impact: -0.2,
    cost: 10.0,
    depth: 1,
  );

  final tree = DecisionTree.fromNodes([root, accept, decline]);

  // 2. Define configurations.
  // - ScoringConfig.balanced() balances probability, impact, and cost evenly.
  // - PruningConfig.defaultSettings() uses standard search boundaries.
  // - TraversalConfig determines pathfinding strategies.
  final scoringConfig = ScoringConfig.balanced(costCeiling: 100.0);
  final pruningConfig = PruningConfig.defaultSettings();
  const traversalConfig = TraversalConfig();

  // 3. Create the engine instance.
  final engine = BranchIQEngine.createSync();

  // 4. Synchronously evaluate the tree (enable debug to populate trace logs).
  final result = engine.evaluateSync(
    tree: tree,
    scoringConfig: scoringConfig,
    pruningConfig: pruningConfig,
    traversalConfig: traversalConfig,
    enableDebug: true,
  );

  // 5. Output the deterministic decision details.
  print('Runtime State: ${result.runtimeState}');
  print('Selected Path: ${result.bestPath.nodeIds.join(' -> ')}');
  print('Total Path Utility: ${result.totalUtility.toStringAsFixed(4)}');
  print('\nExplanation Trace:');
  print(engine.explain(result));
}
