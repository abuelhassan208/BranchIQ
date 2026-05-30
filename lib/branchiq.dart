/// BranchIQ public API library entry point.
/// Provides bounded deterministic runtime decision intelligence for Dart and Flutter.
library branchiq;

export 'src/models/decision_node.dart' show DecisionNode;
export 'src/models/decision_tree.dart' show DecisionTree;
export 'src/config/scoring_config.dart' show ScoringConfig;
export 'src/config/pruning_config.dart' show PruningConfig;
export 'src/config/traversal_config.dart'
    show TraversalConfig, TraversalStrategy;
export 'src/models/evaluation_context.dart' show EvaluationContext;
export 'src/models/evaluation_result.dart'
    show EvaluationResult, BestPathResult;
export 'src/debug/benchmark_snapshot.dart' show BenchmarkSnapshot;
export 'src/debug/debug_snapshot.dart' show DebugSnapshot;
export 'src/validation/tree_validator.dart'
    show InvalidTreeException, OrphanNodeException, CycleDetectedException;
export 'src/runtime/branchiq_engine.dart' show BranchIQEngine;

// v0.2 Replay Layer exports
export 'src/replay/replay_exceptions.dart' show ReplayCorruptException;
export 'src/replay/replay_loader.dart' show ReplayLoader;
export 'src/replay/replay_session.dart' show ReplaySession;
export 'src/replay/replay_inspector.dart' show ReplayInspector;

// v0.2 Explainability Layer exports
export 'src/explainability/branchiq_explainer.dart' show BranchIQExplainer;
export 'src/explainability/explanation_report.dart' show ExplanationReport;
export 'src/explainability/node_explanation.dart' show NodeExplanation;
export 'src/explainability/decision_comparison.dart' show DecisionComparison;
export 'src/explainability/explanation_exceptions.dart'
    show ExplanationException, ExplanationCorruptException;

// v0.2 Snapshot Diffing Layer exports
export 'src/diff/snapshot_differ.dart' show SnapshotDiffer;
export 'src/diff/snapshot_diff.dart' show SnapshotDiff;
export 'src/diff/node_metric_diff.dart' show NodeMetricDiff;
export 'src/diff/trace_diff.dart' show TraceDiff;
export 'src/diff/diff_exceptions.dart'
    show SnapshotDiffException, SnapshotDiffCorruptException;

// v0.3 Plugin Infrastructure exports
export 'src/plugins/node_evaluator.dart' show NodeEvaluator;
export 'src/plugins/plugin_registry.dart' show PluginRegistry;
