/// Represents a read-only container of dynamic environment telemetry variables.
class EvaluationContext {
  final Map<String, dynamic> _variables;

  /// Creates an [EvaluationContext] containing dynamic telemetry metrics.
  ///
  /// Restricts values to JSON-serializable primitives (int, double, bool, String, null,
  /// or unmodifiable List/Map of them) to prevent platform leak or hidden mutations.
  EvaluationContext(Map<String, dynamic> variables)
      : _variables = Map<String, dynamic>.unmodifiable(variables) {
    _validateValues(_variables);
  }

  /// Factory constructor that returns a clean empty context.
  const EvaluationContext.empty() : _variables = const {};

  /// Retrieves an environmental variable casted to the requested type.
  T? get<T>(String key) {
    final value = _variables[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Returns true if the key exists in the context map.
  bool contains(String key) => _variables.containsKey(key);

  /// Deserializes an [EvaluationContext] from a JSON map.
  factory EvaluationContext.fromJson(Map<String, dynamic> json) {
    return EvaluationContext(json);
  }

  /// Serializes this [EvaluationContext] into a JSON map with stable, sorted key order.
  Map<String, dynamic> toJson() {
    final sortedKeys = _variables.keys.toList()..sort();
    return {
      for (final key in sortedKeys) key: _variables[key],
    };
  }

  static void _validateValues(Map<String, dynamic> map) {
    for (final entry in map.entries) {
      _validateValue(entry.key, entry.value);
    }
  }

  static void _validateValue(String key, dynamic value) {
    if (value == null || value is num || value is bool || value is String) {
      return;
    }
    if (value is List) {
      for (final item in value) {
        _validateValue(key, item);
      }
      return;
    }
    if (value is Map) {
      for (final subEntry in value.entries) {
        _validateValue('$key.${subEntry.key}', subEntry.value);
      }
      return;
    }
    throw ArgumentError(
      'EvaluationContext key "$key" contains invalid type: ${value.runtimeType}. '
      'Only JSON-serializable primitives are allowed.',
    );
  }
}
