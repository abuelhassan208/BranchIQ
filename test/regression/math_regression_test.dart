import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/math/deterministic_ordering.dart';
import 'package:branchiq/src/math/score_calculator.dart';
import 'package:test/test.dart';

void main() {
  group('Mathematical Regression and Determinism Replay Tests', () {
    test('100+ repeated runs should produce identical scores and ordering', () {
      final config =
          ScoringConfig(wp: 0.35, wi: 0.45, wc: 0.20, costCeiling: 1200.0);

      // Define a baseline set of raw node parameters, including boundary edge cases.
      final rawNodesData = [
        _NodeSpec('node_a',
            probability: 0.9, impact: 0.8, cost: 200.0, confidence: 0.95),
        _NodeSpec('node_b',
            probability: 0.5, impact: 0.5, cost: 600.0, confidence: 0.80),
        _NodeSpec('node_c',
            probability: 0.9,
            impact: 0.8,
            cost: 200.0,
            confidence: 0.95), // Identical to node_a to force tie-breaking
        _NodeSpec('node_d',
            probability: double.nan,
            impact: 0.1,
            cost: 100.0,
            confidence: 0.5), // NaN edge case
        _NodeSpec('node_e',
            probability: 0.7,
            impact: double.infinity,
            cost: 50.0,
            confidence: 0.75), // Infinity edge case
        _NodeSpec('node_f',
            probability: 0.2,
            impact: -0.9,
            cost: 1500.0,
            confidence: 0.90), // High cost out-of-bounds
        _NodeSpec('node_g',
            probability: 0.6,
            impact: -0.2,
            cost: -50.0,
            confidence: 1.5), // Negative cost & large confidence
      ];

      // First run: establish the ground truth baseline
      final baselineNodes = rawNodesData.map((spec) => spec.toNode()).toList();

      // Calculate scores
      final baselineScoredNodes = baselineNodes.map((node) {
        final score = ScoreCalculator.calculateNodeScore(node, config);
        return node.copyWith(score: score);
      }).toList();

      // Sort nodes
      stableNodeSort(baselineScoredNodes);

      // Extract baseline outputs for verification
      final baselineIdsOrder = baselineScoredNodes.map((n) => n.id).toList();
      final baselineScores = baselineScoredNodes.map((n) => n.score).toList();
      final baselineConfidences =
          baselineScoredNodes.map((n) => n.confidence).toList();

      // Repeat execution for 150 iterations to assert complete stability.
      for (int i = 0; i < 150; i++) {
        final iterationNodes =
            rawNodesData.map((spec) => spec.toNode()).toList();

        final iterationScored = iterationNodes.map((node) {
          final score = ScoreCalculator.calculateNodeScore(node, config);
          return node.copyWith(score: score);
        }).toList();

        stableNodeSort(iterationScored);

        final iterationIds = iterationScored.map((n) => n.id).toList();
        final iterationScores = iterationScored.map((n) => n.score).toList();
        final iterationConfidences =
            iterationScored.map((n) => n.confidence).toList();

        // Exact equality check
        expect(iterationIds, equals(baselineIdsOrder),
            reason: 'Iteration $i: Ordering changed.');
        expect(iterationScores, equals(baselineScores),
            reason: 'Iteration $i: Scores changed.');
        expect(iterationConfidences, equals(baselineConfidences),
            reason: 'Iteration $i: Confidences changed.');
      }
    });
  });
}

class _UnvalidatedDecisionNode implements DecisionNode {
  @override
  final String id;
  @override
  final String? parentId;
  @override
  final List<String> childIds;
  @override
  final double probability;
  @override
  final double impact;
  @override
  final double cost;
  @override
  final double confidence;
  @override
  final double score;
  @override
  final Map<String, dynamic> metadata;
  @override
  final List<String> tags;
  @override
  final int depth;
  @override
  final String? pruningReason;

  _UnvalidatedDecisionNode({
    required this.id,
    this.parentId,
    required this.childIds,
    required this.probability,
    required this.impact,
    required this.cost,
    required this.confidence,
    required this.score,
    required this.metadata,
    required this.tags,
    required this.depth,
    this.pruningReason,
  });

  @override
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
    return _UnvalidatedDecisionNode(
      id: id,
      parentId: parentId,
      childIds: childIds ?? this.childIds,
      probability: probability ?? this.probability,
      impact: impact ?? this.impact,
      cost: cost ?? this.cost,
      confidence: confidence ?? this.confidence,
      score: score ?? this.score,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      depth: depth ?? this.depth,
      pruningReason: pruningReason ?? this.pruningReason,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}

class _NodeSpec {
  final String id;
  final double probability;
  final double impact;
  final double cost;
  final double confidence;

  _NodeSpec(
    this.id, {
    required this.probability,
    required this.impact,
    required this.cost,
    required this.confidence,
  });

  DecisionNode toNode() {
    return _UnvalidatedDecisionNode(
      id: id,
      childIds: const [],
      probability: probability,
      impact: impact,
      cost: cost,
      confidence: confidence,
      score: 0.0,
      metadata: const {},
      tags: const [],
      depth: 0,
    );
  }
}
