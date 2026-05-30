import 'node_evaluator.dart';

/// An immutable container registry that holds active plugins during tree evaluations.
class PluginRegistry {
  /// The ordered sequence of NodeEvaluators.
  final List<NodeEvaluator> evaluators;

  /// Creates a [PluginRegistry] instance.
  ///
  /// The list of evaluators is wrapped in an unmodifiable collection
  /// to preserve immutability and prevent side-channel modification.
  PluginRegistry({
    List<NodeEvaluator> evaluators = const [],
  }) : evaluators = List<NodeEvaluator>.unmodifiable(evaluators);
}
