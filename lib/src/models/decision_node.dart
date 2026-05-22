import '../math/normalization.dart';

/// Represents a single decision step within a BranchIQ decision tree.
/// Nodes are immutable container objects that hold utility metrics.
class DecisionNode {
  /// The unique identifier of this decision node.
  final String id;

  /// The parent identifier, or null if this is the root node.
  final String? parentId;

  /// The children nodes reachable from this decision node.
  final List<String> childIds;

  /// The transition probability associated with this node.
  final double probability;

  /// The utility impact value of selecting this path.
  final double impact;

  /// The resource or time cost value of selecting this path.
  final double cost;

  /// The depth-decayed confidence value computed at evaluation time.
  final double confidence;

  /// The aggregate utility score computed by the scoring engine.
  final double score;

  /// Custom variables metadata holding custom parameters.
  final Map<String, dynamic> metadata;

  /// Diagnostic tags used for logs or classification.
  final List<String> tags;

  /// The depth level of this node from the root node.
  final int depth;

  /// The logged reason if this node was pruned during traversal.
  final String? pruningReason;

  /// Creates a [DecisionNode] instance.
  ///
  /// The collection parameters [childIds], [metadata], and [tags] are copied to
  /// unmodifiable collections to ensure immutability.
  DecisionNode({
    required this.id,
    this.parentId,
    required List<String> childIds,
    this.probability = 1.0,
    this.impact = 0.0,
    this.cost = 0.0,
    this.confidence = 1.0,
    this.score = 0.0,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
    this.depth = 0,
    this.pruningReason,
  })  : childIds = List<String>.unmodifiable(childIds),
        metadata = Map<String, dynamic>.unmodifiable(metadata),
        tags = List<String>.unmodifiable(tags),
        assert(id.isNotEmpty, 'id must not be empty'),
        assert(probability >= 0.0 && probability <= 1.0,
            'probability must be in range [0.0, 1.0]'),
        assert(impact >= -1.0 && impact <= 1.0,
            'impact must be in range [-1.0, 1.0]'),
        assert(cost >= 0.0, 'cost must be non-negative'),
        assert(confidence >= 0.0 && confidence <= 1.0,
            'confidence must be in range [0.0, 1.0]'),
        assert(score >= -1.0 && score <= 1.0,
            'score must be in range [-1.0, 1.0]'),
        assert(depth >= 0, 'depth must be non-negative');

  /// Creates a compile-time constant [DecisionNode] instance.
  ///
  /// Collections passed to this constructor MUST be compile-time constants (which are immutable).
  const DecisionNode.constant({
    required this.id,
    this.parentId,
    required this.childIds,
    this.probability = 1.0,
    this.impact = 0.0,
    this.cost = 0.0,
    this.confidence = 1.0,
    this.score = 0.0,
    this.metadata = const {},
    this.tags = const [],
    this.depth = 0,
    this.pruningReason,
  })  : assert(id.length > 0, 'id must not be empty'),
        assert(probability >= 0.0 && probability <= 1.0,
            'probability must be in range [0.0, 1.0]'),
        assert(impact >= -1.0 && impact <= 1.0,
            'impact must be in range [-1.0, 1.0]'),
        assert(cost >= 0.0, 'cost must be non-negative'),
        assert(confidence >= 0.0 && confidence <= 1.0,
            'confidence must be in range [0.0, 1.0]'),
        assert(score >= -1.0 && score <= 1.0,
            'score must be in range [-1.0, 1.0]'),
        assert(depth >= 0, 'depth must be non-negative');

  /// Returns a copy of this node with updated attributes.
  ///
  /// Collections are wrapped in unmodifiable lists/maps to protect from reference leaks.
  DecisionNode copyWith({
    double? probability,
    double? impact,
    double? cost,
    double? confidence,
    double? score,
    int? depth,
    String? pruningReason,
    List<String>? childIds,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    return DecisionNode(
      id: id,
      parentId: parentId,
      childIds: childIds != null
          ? List<String>.unmodifiable(childIds)
          : this.childIds,
      probability: probability != null
          ? clampProbability(probability)
          : this.probability,
      impact: impact != null ? clampImpact(impact) : this.impact,
      cost: cost != null ? (cost < 0.0 ? 0.0 : cost) : this.cost,
      confidence:
          confidence != null ? clampConfidence(confidence) : this.confidence,
      score: score ?? this.score,
      metadata: metadata != null
          ? Map<String, dynamic>.unmodifiable(metadata)
          : this.metadata,
      tags: tags != null ? List<String>.unmodifiable(tags) : this.tags,
      depth: depth ?? this.depth,
      pruningReason: pruningReason ?? this.pruningReason,
    );
  }

  /// Deserializes a [DecisionNode] from a JSON map.
  ///
  /// Validates node constraints and cleans parameters using internal normalization helpers.
  factory DecisionNode.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Node id must not be empty.');
    }

    final parentId = json['parentId'] as String?;

    final rawChildIds = json['childIds'] as List<dynamic>? ?? const [];
    final childIds = List<String>.unmodifiable(rawChildIds.cast<String>());

    final probability =
        clampProbability((json['probability'] as num?)?.toDouble() ?? 1.0);
    final impact = clampImpact((json['impact'] as num?)?.toDouble() ?? 0.0);

    final rawCost = (json['cost'] as num?)?.toDouble() ?? 0.0;
    final cost = rawCost < 0.0 ? 0.0 : rawCost;

    final confidence =
        clampConfidence((json['confidence'] as num?)?.toDouble() ?? 1.0);
    final score = (json['score'] as num?)?.toDouble() ?? 0.0;

    final rawMetadata = json['metadata'] as Map<String, dynamic>? ?? const {};
    final metadata = Map<String, dynamic>.unmodifiable(rawMetadata);

    final rawTags = json['tags'] as List<dynamic>? ?? const [];
    final tags = List<String>.unmodifiable(rawTags.cast<String>());

    final depth = json['depth'] as int? ?? 0;
    if (depth < 0) {
      throw ArgumentError('Node depth must be non-negative.');
    }

    final pruningReason = json['pruningReason'] as String?;

    return DecisionNode(
      id: id,
      parentId: parentId,
      childIds: childIds,
      probability: probability,
      impact: impact,
      cost: cost,
      confidence: confidence,
      score: score,
      metadata: metadata,
      tags: tags,
      depth: depth,
      pruningReason: pruningReason,
    );
  }

  /// Serializes this [DecisionNode] into a JSON map with stable key order.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'childIds': childIds.toList(),
      'probability': probability,
      'impact': impact,
      'cost': cost,
      'confidence': confidence,
      'score': score,
      'metadata': Map<String, dynamic>.from(metadata),
      'tags': tags.toList(),
      'depth': depth,
      'pruningReason': pruningReason,
    };
  }
}
