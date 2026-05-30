import 'package:branchiq/branchiq.dart';

/// BranchIQ v0.2 Explainability Example
///
/// Demonstrates:
///   1. Build a decision tree and evaluate it with debug logging enabled.
///   2. Reconstruct a [ReplaySession] from the resulting debug snapshot.
///   3. Generate an [ExplanationReport] offline without re-running tree execution.
///   4. Export stable markdown report.
///   5. Deterministically compare two paths under the same session context.
///
/// Uses ONLY public APIs exported from `package:branchiq`.
void main() {
  print('=== BranchIQ Explainability Example ===\n');

  // 1. Build and evaluate a decision tree
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
  print('Total Utility:  ${result.totalUtility.toStringAsFixed(4)}\n');

  // 2. Load the DebugSnapshot into a ReplaySession
  final snapshot = engine.exportDebugSnapshot(result);
  final session = ReplayLoader.load(snapshot);

  // 3. Generate ExplanationReport
  print('--- Generating Explanation Report (Offline) ---');
  final report = BranchIQExplainer.explain(session);
  print('Explanation generated successfully.');
  print('Root Node:        ${report.rootId}');
  print('Selected Path:    ${report.selectedPath.join(' → ')}');
  print('Selected Utility: ${report.selectedUtility.toStringAsFixed(4)}');
  print('Rejected Nodes:   ${report.rejectedNodeIds.join(', ')}\n');

  // 4. Export Markdown Report
  print('--- Markdown Explanation Report Output ---');
  final markdown = report.toMarkdown();
  print(markdown);
  print('');

  // 5. Compare Selected Path against Alternative Path (e.g. Defer Path)
  print('--- Path Comparison ---');
  final comparison = BranchIQExplainer.comparePaths(
    session: session,
    selectedPath: ['root', 'approve', 'approve_auto'],
    rejectedPath: ['root', 'defer'],
  );

  final comparisonMarkdown = comparison.toMarkdown();
  print(comparisonMarkdown);

  print('\n=== BranchIQ Explainability Example Complete ===');
}
