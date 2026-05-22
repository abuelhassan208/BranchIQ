import 'package:branchiq/branchiq.dart';

void main() {
  print('=== BranchIQ Traversal & Path Selection Example ===\n');

  // Build a multi-level decision tree.
  // Root branches into "strategy_a" and "strategy_b".
  // Each strategy has two sub-options.
  // The traversal engine selects the highest-utility leaf-to-root path.
  //
  // Tree structure:
  //
  //             root
  //           /       \
  //       strategy_a  strategy_b
  //       /      \       /      \
  //    a_deep   a_wide  b_fast  b_thorough

  final root = DecisionNode(
    id: 'root',
    childIds: ['strategy_a', 'strategy_b'],
    depth: 0,
  );

  final strategyA = DecisionNode(
    id: 'strategy_a',
    parentId: 'root',
    childIds: ['a_deep', 'a_wide'],
    probability: 0.8,
    impact: 0.5,
    cost: 30.0,
    depth: 1,
  );

  final strategyB = DecisionNode(
    id: 'strategy_b',
    parentId: 'root',
    childIds: ['b_fast', 'b_thorough'],
    probability: 0.75,
    impact: 0.4,
    cost: 20.0,
    depth: 1,
  );

  final aDeep = DecisionNode(
    id: 'a_deep',
    parentId: 'strategy_a',
    childIds: [],
    probability: 0.85,
    impact: 0.9, // Best overall impact
    cost: 60.0,
    depth: 2,
  );

  final aWide = DecisionNode(
    id: 'a_wide',
    parentId: 'strategy_a',
    childIds: [],
    probability: 0.7,
    impact: 0.55,
    cost: 15.0,
    depth: 2,
  );

  final bFast = DecisionNode(
    id: 'b_fast',
    parentId: 'strategy_b',
    childIds: [],
    probability: 0.95,
    impact: 0.3,
    cost: 5.0,
    depth: 2,
  );

  final bThorough = DecisionNode(
    id: 'b_thorough',
    parentId: 'strategy_b',
    childIds: [],
    probability: 0.6,
    impact: 0.7,
    cost: 40.0,
    depth: 2,
  );

  final tree = DecisionTree.fromNodes([
    root,
    strategyA,
    strategyB,
    aDeep,
    aWide,
    bFast,
    bThorough,
  ]);

  final engine = BranchIQEngine.createSync();
  final pruningConfig = PruningConfig.defaultSettings();

  // --- Scenario 1: Quality-Biased Scoring (impact dominates) ---
  print('--- Scenario 1: Quality-Biased Scoring (impact 70%, cost 10%) ---');
  final qualityScoring = ScoringConfig(
    wp: 0.2,
    wi: 0.7,
    wc: 0.1,
    costCeiling: 100.0,
  );

  final resultQuality = engine.evaluateSync(
    tree: tree,
    scoringConfig: qualityScoring,
    pruningConfig: pruningConfig,
    traversalConfig: const TraversalConfig(),
  );

  print('Selected Path:  ${resultQuality.bestPath.nodeIds.join(' -> ')}');
  print('Total Utility:  ${resultQuality.totalUtility.toStringAsFixed(4)}');
  print('Why: "a_deep" scores highest due to impact=0.9, despite cost=60.0 '
      'being largely discounted by the low cost weight (wc=0.1).');
  print('');

  // --- Scenario 2: Speed/Cost-Biased Scoring ---
  print('--- Scenario 2: Cost-Biased Scoring (cost 70%, impact 10%) ---');
  final costScoring = ScoringConfig(
    wp: 0.2,
    wi: 0.1,
    wc: 0.7,
    costCeiling: 100.0,
  );

  final resultCost = engine.evaluateSync(
    tree: tree,
    scoringConfig: costScoring,
    pruningConfig: pruningConfig,
    traversalConfig: const TraversalConfig(),
  );

  print('Selected Path:  ${resultCost.bestPath.nodeIds.join(' -> ')}');
  print('Total Utility:  ${resultCost.totalUtility.toStringAsFixed(4)}');
  print('Why: "b_fast" wins because it has the lowest cost (5.0), which is '
      'the dominant factor with wc=0.7.');
  print('');

  // --- Scenario 3: Tie-breaking explanation ---
  // Create two nodes with equal probability, impact, and cost to demonstrate
  // that BranchIQ uses stable lexicographic node ID sorting to break ties.
  print('--- Scenario 3: Deterministic Tie-Breaking ---');

  final tieRoot = DecisionNode(
    id: 'root',
    childIds: ['option_alpha', 'option_zeta'],
    depth: 0,
  );
  final optionAlpha = DecisionNode(
    id: 'option_alpha',
    parentId: 'root',
    childIds: [],
    probability: 0.8,
    impact: 0.5,
    cost: 10.0,
    depth: 1,
  );
  final optionZeta = DecisionNode(
    id: 'option_zeta',
    parentId: 'root',
    childIds: [],
    probability: 0.8, // Identical to option_alpha
    impact: 0.5, // Identical to option_alpha
    cost: 10.0, // Identical to option_alpha
    depth: 1,
  );

  final tieTree = DecisionTree.fromNodes([tieRoot, optionAlpha, optionZeta]);
  final balanced = ScoringConfig.balanced(costCeiling: 100.0);

  final tieResult = engine.evaluateSync(
    tree: tieTree,
    scoringConfig: balanced,
    pruningConfig: PruningConfig.defaultSettings(),
    traversalConfig: const TraversalConfig(),
  );

  print('Selected Path:  ${tieResult.bestPath.nodeIds.join(' -> ')}');
  print('Why: Both nodes have identical metrics. BranchIQ resolves ties '
      'by lexicographic node ID order: "option_alpha" < "option_zeta".');
  print('This is deterministic — the same tie is always broken identically.');
}
