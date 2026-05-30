import 'plugin_registry.dart';

/// Provides validation logic to guarantee registered plugins comply with BranchIQ constraints.
class PluginRegistryValidator {
  /// Validates that a registry's plugin IDs are non-empty, unique, and contain only stable ASCII characters.
  ///
  /// Throws [ArgumentError] if validation fails.
  static void validate(PluginRegistry registry) {
    final seenIds = <String>{};
    for (final evaluator in registry.evaluators) {
      final id = evaluator.id;
      if (id.isEmpty) {
        throw ArgumentError('Plugin ID must not be empty.');
      }
      for (int i = 0; i < id.length; i++) {
        if (id.codeUnitAt(i) > 127) {
          throw ArgumentError(
              'Plugin ID "$id" must contain only ASCII characters.');
        }
      }
      if (!seenIds.add(id)) {
        throw ArgumentError('Duplicate plugin ID detected: "$id".');
      }
    }
  }
}
