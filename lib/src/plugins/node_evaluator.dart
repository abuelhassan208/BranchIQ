import '../models/decision_node.dart';
import '../models/evaluation_context.dart';

/// Represents a synchronous decision pipeline plugin that dynamically
/// adjusts a node's metrics and coordinates based on evaluation context.
abstract class NodeEvaluator {
  /// The unique, stable ASCII-only identifier of this evaluator.
  String get id;

  /// Modifies and returns a copy of [node] based on variables in [context].
  DecisionNode evaluate(DecisionNode node, EvaluationContext context);
}
