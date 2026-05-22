import '../config/pruning_config.dart';
import '../config/scoring_config.dart';
import '../config/traversal_config.dart';
import '../debug/runtime_trace.dart';
import '../models/decision_tree.dart';
import 'runtime_state.dart';

/// Wraps the configuration parameters passed to the engine.
class EvaluationConfigs {
  /// The scoring configuration parameters.
  final ScoringConfig scoring;

  /// The pruning configuration parameters.
  final PruningConfig pruning;

  /// The path search traversal configuration parameters.
  final TraversalConfig traversal;

  /// Creates an [EvaluationConfigs] instance.
  const EvaluationConfigs({
    required this.scoring,
    required this.pruning,
    required this.traversal,
  });

  /// Deserializes [EvaluationConfigs] from a JSON map.
  factory EvaluationConfigs.fromJson(Map<String, dynamic> json) {
    return EvaluationConfigs(
      scoring: ScoringConfig.fromJson(json['scoring'] as Map<String, dynamic>),
      pruning: PruningConfig.fromJson(json['pruning'] as Map<String, dynamic>),
      traversal:
          TraversalConfig.fromJson(json['traversal'] as Map<String, dynamic>),
    );
  }

  /// Serializes this instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'scoring': scoring.toJson(),
      'pruning': pruning.toJson(),
      'traversal': traversal.toJson(),
    };
  }
}

/// Represents an immutable execution session recording status, logs, and parameters.
class EvaluationSession {
  /// The unique identifier assigned to this evaluation session.
  final String sessionId;

  /// The current state of the engine pipeline.
  final RuntimeState runtimeState;

  /// Monotonically increasing placeholder timestamp when evaluation started.
  final int startedAt;

  /// Monotonically increasing placeholder timestamp when evaluation finished.
  final int? completedAt;

  /// The tree structure evaluated in this session.
  final DecisionTree tree;

  /// Configurations utilized for the evaluation process.
  final EvaluationConfigs configs;

  /// Event trace diagnostic logs collected when debugging is enabled.
  final List<RuntimeTrace> traces;

  /// Indicates if debug logs and metrics capture is enabled.
  final bool debugEnabled;

  /// Creates an [EvaluationSession] instance.
  ///
  /// Coerces lists into unmodifiable collections to guarantee strict immutability.
  EvaluationSession({
    required this.sessionId,
    required this.runtimeState,
    required this.startedAt,
    this.completedAt,
    required this.tree,
    required this.configs,
    required List<RuntimeTrace> traces,
    required this.debugEnabled,
  }) : traces = List<RuntimeTrace>.unmodifiable(traces);

  /// Returns a modified copy of this session with updated parameters.
  EvaluationSession copyWith({
    RuntimeState? runtimeState,
    int? completedAt,
    DecisionTree? tree,
    List<RuntimeTrace>? traces,
  }) {
    return EvaluationSession(
      sessionId: sessionId,
      runtimeState: runtimeState ?? this.runtimeState,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      tree: tree ?? this.tree,
      configs: configs,
      traces: traces ?? this.traces,
      debugEnabled: debugEnabled,
    );
  }

  /// Deserializes [EvaluationSession] from a JSON map.
  factory EvaluationSession.fromJson(Map<String, dynamic> json) {
    final rawTraces = json['traces'] as List<dynamic>? ?? const [];
    final traces = rawTraces
        .map((t) => RuntimeTrace.fromJson(t as Map<String, dynamic>))
        .toList();

    return EvaluationSession(
      sessionId: json['sessionId'] as String,
      runtimeState: RuntimeState.fromString(json['runtimeState'] as String),
      startedAt: json['startedAt'] as int,
      completedAt: json['completedAt'] as int?,
      tree: DecisionTree.fromJson(json['tree'] as Map<String, dynamic>),
      configs:
          EvaluationConfigs.fromJson(json['configs'] as Map<String, dynamic>),
      traces: traces,
      debugEnabled: json['debugEnabled'] as bool? ?? false,
    );
  }

  /// Serializes this [EvaluationSession] into a JSON map with stable key order.
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'runtimeState': runtimeState.name,
      'startedAt': startedAt,
      if (completedAt != null) 'completedAt': completedAt,
      'tree': tree.toJson(),
      'configs': configs.toJson(),
      'traces': traces.map((t) => t.toJson()).toList(),
      'debugEnabled': debugEnabled,
    };
  }
}
