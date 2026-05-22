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
