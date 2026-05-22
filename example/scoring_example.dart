import 'package:branchiq/branchiq.dart';

void main() {
  print('=== BranchIQ Scoring & Weight Sensitivity Example ===\n');

  // 1. Construct a tree structure containing two main branches:
  // - High Quality, High Cost (branch_hq)
  // - Moderate Quality, Low Cost (branch_lc)
  // And a nested node under branch_hq to demonstrate confidence decay.
  final root = const DecisionNode.constant(
    id: 'root',
    parentId: null,
    childIds: ['branch_hq', 'branch_lc'],
    depth: 0,
  );

  final branchHq = const DecisionNode.constant(
    id: 'branch_hq',
    parentId: 'root',
    childIds: ['nested_hq_sub'],
    probability: 0.95,
    impact: 0.9, // Very high impact
    cost: 80.0, // High cost
    depth: 1,
  );

  final nestedHqSub = const DecisionNode.constant(
    id: 'nested_hq_sub',
    parentId: 'branch_hq',
    childIds: [],
    probability: 0.9,
    impact: 0.95,
    cost: 10.0,
    depth: 2, // Located at depth 2 (confidence will decay based on depth)
  );

  final branchLc = const DecisionNode.constant(
    id: 'branch_lc',
    parentId: 'root',
    childIds: [],
    probability: 0.8,
    impact: 0.4, // Moderate impact
    cost: 10.0, // Low cost
    depth: 1,
  );

  final tree = DecisionTree.fromNodes([root, branchHq, nestedHqSub, branchLc]);
  final engine = BranchIQEngine.createSync();
  final pruningConfig = PruningConfig.defaultSettings();
  const traversalConfig = TraversalConfig();

  // --- Scenario 1: Quality and Impact Conscious Weight Configuration ---
  // We prioritize impact (wi = 0.7), with lower penalty for cost (wc = 0.1).
  final qualityScoring = ScoringConfig(
    wp: 0.2, // 20% Probability weight
    wi: 0.7, // 70% Impact weight
    wc: 0.1, // 10% Cost penalty weight
    costCeiling: 100.0, // Scales costs relative to 100.0 ceiling
  );

  print('--- Scenario 1: Prioritizing Quality (wi=0.7, wc=0.1) ---');
  final resultQuality = engine.evaluateSync(
    tree: tree,
    scoringConfig: qualityScoring,
    pruningConfig: pruningConfig,
    traversalConfig: traversalConfig,
    enableDebug: true,
  );

  print('Selected Path: ${resultQuality.bestPath.nodeIds.join(' -> ')}');
  print('Total Utility: ${resultQuality.totalUtility.toStringAsFixed(4)}');
  print(
      'Why: Under quality-first weights, the higher impact of branch_hq (0.9) '
      'overcomes its high cost (80.0).');
  print('');

  // --- Scenario 2: Cost Conscious Weight Configuration ---
  // We prioritize keeping costs low (wc = 0.7), and discount high impact (wi = 0.1).
  final costScoring = ScoringConfig(
    wp: 0.2, // 20% Probability weight
    wi: 0.1, // 10% Impact weight
    wc: 0.7, // 70% Cost penalty weight
    costCeiling: 100.0,
  );

  print('--- Scenario 2: Prioritizing Cost Constraints (wi=0.1, wc=0.7) ---');
  final resultCost = engine.evaluateSync(
    tree: tree,
    scoringConfig: costScoring,
    pruningConfig: pruningConfig,
    traversalConfig: traversalConfig,
    enableDebug: true,
  );

  print('Selected Path: ${resultCost.bestPath.nodeIds.join(' -> ')}');
  print('Total Utility: ${resultCost.totalUtility.toStringAsFixed(4)}');
  print('Why: Under cost-conscious weights, the lower cost of branch_lc (10.0) '
      'wins over the expensive branch_hq (80.0), despite branch_hq having superior quality.');
  print('');

  // --- Scenario 3: Confidence Decay and Cost Normalization Demonstration ---
  // Let's examine the detailed scoring for branch_hq and its sub-child nested_hq_sub
  // under Scenario 1 weights to see cost scaling and confidence decay in action.
  final snapshot = engine.exportDebugSnapshot(resultQuality);
  final hqSnap = snapshot.nodeSnapshots['branch_hq']!;
  final subSnap = snapshot.nodeSnapshots['nested_hq_sub']!;

  print('--- Scenario 3: Diagnostics (Confidence Decay & Cost Scaling) ---');
  print('Node "branch_hq" (Depth 1):');
  print(
      '  Raw Cost: 80.0 -> Normalized Cost Penalty: ${(80.0 / 100.0).toStringAsFixed(2)}');
  print('  Confidence: ${(hqSnap['confidence'] as double).toStringAsFixed(4)}');
  print('  Final Score: ${(hqSnap['score'] as double).toStringAsFixed(4)}');
  print('');
  print('Node "nested_hq_sub" (Depth 2):');
  print(
      '  Raw Cost: 10.0 -> Normalized Cost Penalty: ${(10.0 / 100.0).toStringAsFixed(2)}');
  // Confidence decays at deeper levels based on parent confidence and depth
  print('  Decayed Confidence: ${(subSnap['confidence'] as double).toStringAsFixed(4)}');
  print('  Final Score: ${(subSnap['score'] as double).toStringAsFixed(4)}');
}
