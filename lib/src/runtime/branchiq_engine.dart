import '../config/pruning_config.dart';
import '../config/scoring_config.dart';
import '../config/traversal_config.dart';
import '../debug/debug_snapshot.dart';
import '../models/decision_tree.dart';
import '../models/evaluation_context.dart';
import '../models/evaluation_result.dart';
import '../plugins/plugin_registry.dart';
import 'runtime_pipeline.dart';

/// The public entry point for evaluating [DecisionTree] structures.
///
/// Create an instance using [BranchIQEngine.createSync] and evaluate trees
/// using [evaluateSync]. All evaluation is synchronous and deterministic:
/// identical inputs always produce identical outputs.
///
/// Example:
/// ```dart
/// final engine = BranchIQEngine.createSync();
/// final result = engine.evaluateSync(
///   tree: tree,
///   scoringConfig: ScoringConfig.balanced(),
///   pruningConfig: PruningConfig.defaultSettings(),
///   traversalConfig: const TraversalConfig(),
/// );
/// print(result.bestPath.nodeIds); // ['root', 'accept']
/// ```
abstract class BranchIQEngine {
  /// Creates a synchronous, stateless evaluation engine instance.
  ///
  /// The engine holds no mutable state between calls. Running [evaluateSync]
  /// multiple times with the same inputs always returns the same result.
  factory BranchIQEngine.createSync() => _BranchIQEngineImpl();

  /// Evaluates [tree] synchronously and returns the deterministic best path.
  ///
  /// The evaluation runs a four-phase pipeline on the calling thread:
  /// 1. **Validation** — checks tree structure, cycles, and depth limits.
  /// 2. **Scoring** — assigns utility scores using [scoringConfig] weights.
  /// 3. **Pruning** — removes low-value branches using [pruningConfig] thresholds.
  /// 4. **Traversal** — selects the highest-utility root-to-leaf path.
  ///
  /// Returns an [EvaluationResult] whose [EvaluationResult.runtimeState] is:
  /// - `'completed'` — a valid path was found.
  /// - `'fallback'` — all branches were pruned; root node is returned.
  /// - `'failed'` — a structural or safety limit violation occurred.
  ///
  /// Set [enableDebug] to `true` to populate [EvaluationResult.debugSnapshot]
  /// and [EvaluationResult.traces] with full diagnostic information.
  ///
  /// Set [enableBenchmark] to `true` to populate
  /// [EvaluationResult.benchmarkSnapshot] with deterministic execution metrics.
  ///
  /// Throws [ArgumentError] if required configuration is missing.
  EvaluationResult evaluateSync({
    required DecisionTree tree,
    ScoringConfig? scoringConfig,
    PruningConfig? pruningConfig,
    TraversalConfig? traversalConfig,
    EvaluationContext? context,
    PluginRegistry? plugins,
    bool enableDebug = false,
    bool enableBenchmark = false,
    @Deprecated('Use scoringConfig instead') ScoringConfig? scoring,
    @Deprecated('Use pruningConfig instead') PruningConfig? pruning,
    @Deprecated('Use traversalConfig instead') TraversalConfig? traversal,
  });

  /// Returns a human-readable explanation of why [result]'s path was chosen.
  ///
  /// The explanation includes the selected path, total utility score, runtime
  /// state, and the chronological pipeline trace log (if debug was enabled).
  ///
  /// This method is safe to call on failed or fallback results.
  String explain(EvaluationResult result);

  /// Exports the complete evaluation state to a [DebugSnapshot].
  ///
  /// If [result] already contains a debug snapshot (from [enableDebug]),
  /// returns it directly. Otherwise returns a lightweight snapshot containing
  /// only the selected path, total utility, and runtime traces.
  ///
  /// The returned snapshot is fully JSON-serializable via [DebugSnapshot.toJson].
  DebugSnapshot exportDebugSnapshot(EvaluationResult result);
}

class _BranchIQEngineImpl implements BranchIQEngine {
  @override
  EvaluationResult evaluateSync({
    required DecisionTree tree,
    ScoringConfig? scoringConfig,
    PruningConfig? pruningConfig,
    TraversalConfig? traversalConfig,
    EvaluationContext? context,
    PluginRegistry? plugins,
    bool enableDebug = false,
    bool enableBenchmark = false,
    ScoringConfig? scoring,
    PruningConfig? pruning,
    TraversalConfig? traversal,
  }) {
    final resolvedScoring = scoringConfig ?? scoring;
    final resolvedPruning = pruningConfig ?? pruning;
    final resolvedTraversal = traversalConfig ?? traversal;

    if (resolvedScoring == null) {
      throw ArgumentError(
          'Scoring configuration must be provided via scoringConfig or scoring.');
    }
    if (resolvedPruning == null) {
      throw ArgumentError(
          'Pruning configuration must be provided via pruningConfig or pruning.');
    }
    if (resolvedTraversal == null) {
      throw ArgumentError(
          'Traversal configuration must be provided via traversalConfig or traversal.');
    }

    return RuntimePipeline.runPipeline(
      tree: tree,
      scoringConfig: resolvedScoring,
      pruningConfig: resolvedPruning,
      traversalConfig: resolvedTraversal,
      context: context,
      plugins: plugins,
      enableDebug: enableDebug,
      enableBenchmark: enableBenchmark,
    );
  }

  @override
  String explain(EvaluationResult result) {
    if (result.errorMessage != null) {
      return 'Evaluation failed: ${result.errorMessage}\nTraces:\n${result.traces.join('\n')}';
    }
    final pathStr = result.bestPath.nodeIds.isEmpty
        ? 'None (Fallback)'
        : result.bestPath.nodeIds.join(' -> ');
    return 'Path chosen: $pathStr\nTotal Utility: ${result.totalUtility}\nState: ${result.runtimeState}\nTraces:\n${result.traces.join('\n')}';
  }

  @override
  DebugSnapshot exportDebugSnapshot(EvaluationResult result) {
    if (result.debugSnapshot != null) {
      return result.debugSnapshot!;
    }
    return DebugSnapshot(
      engineVersion: '0.1.0',
      rootId: result.bestPath.nodes.isNotEmpty
          ? result.bestPath.nodes.first.id
          : '',
      selectedPath: result.bestPath.nodeIds,
      nodeSnapshots: const {},
      pruningTraces: const [],
      metadata: const {},
      runtimeTraces: result.traces,
      prunedNodeIds: const [],
      scoringSummaries: const {},
      traversalSummaries: {
        'totalUtility': result.totalUtility,
      },
    );
  }
}
