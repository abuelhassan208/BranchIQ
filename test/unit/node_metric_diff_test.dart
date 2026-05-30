import 'package:test/test.dart';
import 'package:branchiq/branchiq.dart';

void main() {
  group('NodeMetricDiff Tests', () {
    test('constructs and computes fields correctly', () {
      final diff = NodeMetricDiff(
        nodeId: 'node1',
        existsInSource: true,
        existsInTarget: true,
        changedFields: ['score', 'probability'],
        probabilityDelta: 0.1,
        impactDelta: -0.05,
        costDelta: 2.5,
        confidenceDelta: 0.0,
        scoreDelta: 0.15,
        pruningStatusChanged: false,
        sourcePruningReason: null,
        targetPruningReason: null,
      );

      expect(diff.nodeId, equals('node1'));
      expect(diff.existsInSource, isTrue);
      expect(diff.existsInTarget, isTrue);
      expect(diff.changedFields,
          equals(['probability', 'score'])); // Sorted lexicographically
      expect(diff.probabilityDelta, equals(0.1));
      expect(diff.impactDelta, equals(-0.05));
      expect(diff.costDelta, equals(2.5));
      expect(diff.confidenceDelta, equals(0.0));
      expect(diff.scoreDelta, equals(0.15));
      expect(diff.pruningStatusChanged, isFalse);
    });

    test('serializes to JSON correctly omitting nulls', () {
      final diff = NodeMetricDiff(
        nodeId: 'node2',
        existsInSource: true,
        existsInTarget: false,
        changedFields: ['exists'],
        pruningStatusChanged: true,
        sourcePruningReason: 'probabilityBelowThreshold',
      );

      final json = diff.toJson();
      expect(json['nodeId'], equals('node2'));
      expect(json['existsInSource'], isTrue);
      expect(json['existsInTarget'], isFalse);
      expect(json['changedFields'], equals(['exists']));
      expect(json['pruningStatusChanged'], isTrue);
      expect(json['sourcePruningReason'], equals('probabilityBelowThreshold'));

      // Check that optional null fields are omitted
      expect(json.containsKey('probabilityDelta'), isFalse);
      expect(json.containsKey('impactDelta'), isFalse);
      expect(json.containsKey('costDelta'), isFalse);
      expect(json.containsKey('confidenceDelta'), isFalse);
      expect(json.containsKey('scoreDelta'), isFalse);
      expect(json.containsKey('targetPruningReason'), isFalse);
    });

    test('generates byte-identical canonical JSON', () {
      final diff = NodeMetricDiff(
        nodeId: 'node3',
        existsInSource: true,
        existsInTarget: true,
        changedFields: ['cost'],
        costDelta: 5.0,
        pruningStatusChanged: false,
      );

      final canonicalJson = diff.toCanonicalJson();
      expect(canonicalJson, contains('"nodeId":"node3"'));
      expect(
          canonicalJson, contains('"costDelta":"5.0000"')); // formatted float
    });
  });
}
