import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/math/score_calculator.dart';
import 'package:test/test.dart';

class MockScoringConfig implements ScoringConfig {
  @override
  final double wp;
  @override
  final double wi;
  @override
  final double wc;
  @override
  final double costCeiling;

  MockScoringConfig({
    required this.wp,
    required this.wi,
    required this.wc,
    required this.costCeiling,
  });

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}

class MockDecisionNode implements DecisionNode {
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

  MockDecisionNode({
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
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}

void main() {
  group('ScoreCalculator Tests', () {
    test('calculateNodeScore should compute correct MAUT utility score', () {
      final config =
          ScoringConfig(wp: 0.4, wi: 0.4, wc: 0.2, costCeiling: 500.0);
      const node = DecisionNode.constant(
        id: 'node_1',
        childIds: [],
        probability: 0.8,
        impact: 0.5,
        confidence: 0.9,
        cost: 100.0,
      );

      final score = ScoreCalculator.calculateNodeScore(node, config);
      final expectedCNorm = 100.0 / (500.0 + 1e-9);
      final expectedRaw = (0.4 * 0.8) + (0.4 * 0.5) - (0.2 * expectedCNorm);
      final expectedScore = 0.9 * expectedRaw;

      expect(score, closeTo(expectedScore, 1e-9));
    });

    test('calculateNodeScore should sanitize out-of-bound inputs', () {
      final config =
          ScoringConfig(wp: 0.4, wi: 0.4, wc: 0.2, costCeiling: 500.0);
      final node = MockDecisionNode(
        id: 'node_1',
        childIds: const [],
        probability: 1.5,
        impact: -2.0,
        confidence: -0.5,
        cost: -100.0,
        score: 0.0,
        metadata: const {},
        tags: const [],
        depth: 0,
      );

      final score = ScoreCalculator.calculateNodeScore(node, config);
      expect(score, equals(0.0));
    });

    test('calculateNodeScore should throw if weights do not sum to 1.0', () {
      final badConfig =
          MockScoringConfig(wp: 0.5, wi: 0.5, wc: 0.5, costCeiling: 1000.0);
      const node = DecisionNode.constant(id: 'node_1', childIds: []);

      expect(
        () => ScoreCalculator.calculateNodeScore(node, badConfig),
        throwsArgumentError,
      );
    });

    test('ScoringConfig constructor should validate inputs', () {
      expect(() => ScoringConfig(wp: 0.3, wi: 0.3, wc: 0.4, costCeiling: 100.0),
          returnsNormally);
      expect(() => ScoringConfig(wp: 0.1, wi: 0.2, wc: 0.3, costCeiling: 100.0),
          throwsArgumentError);
      expect(
          () => ScoringConfig(wp: -0.1, wi: 0.6, wc: 0.5, costCeiling: 100.0),
          throwsArgumentError);
      expect(() => ScoringConfig(wp: 0.3, wi: 0.3, wc: 0.4, costCeiling: 0.0),
          throwsArgumentError);
      expect(() => ScoringConfig(wp: 0.3, wi: 0.3, wc: 0.4, costCeiling: -50.0),
          throwsArgumentError);
    });
  });
}
