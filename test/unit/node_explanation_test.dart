import 'dart:convert';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('NodeExplanation Tests', () {
    test('creates explanation with correct properties', () {
      const exp = NodeExplanation(
        nodeId: 'node_a',
        score: 0.8500,
        probabilityContribution: 0.9000,
        impactContribution: 0.8000,
        costContribution: 0.2000,
        confidenceContribution: 0.9500,
        pruningStatus: 'retained',
        pruningReason: null,
        traversalRank: 1,
        selected: true,
        terminal: false,
      );

      expect(exp.nodeId, equals('node_a'));
      expect(exp.score, equals(0.8500));
      expect(exp.probabilityContribution, equals(0.9000));
      expect(exp.impactContribution, equals(0.8000));
      expect(exp.costContribution, equals(0.2000));
      expect(exp.confidenceContribution, equals(0.9500));
      expect(exp.pruningStatus, equals('retained'));
      expect(exp.pruningReason, isNull);
      expect(exp.traversalRank, equals(1));
      expect(exp.selected, isTrue);
      expect(exp.terminal, isFalse);
    });

    test('serializes to stable JSON map with sorted keys', () {
      const exp = NodeExplanation(
        nodeId: 'node_a',
        score: 0.8500,
        pruningStatus: 'retained',
        selected: true,
        terminal: true,
      );

      final jsonMap = exp.toJson();
      expect(jsonMap['nodeId'], equals('node_a'));
      expect(jsonMap['score'], equals(0.8500));
      expect(jsonMap['pruningStatus'], equals('retained'));
      expect(jsonMap['selected'], isTrue);
      expect(jsonMap['terminal'], isTrue);

      // JSON properties must not contain optional fields when they are null
      expect(jsonMap.containsKey('probabilityContribution'), isFalse);
      expect(jsonMap.containsKey('impactContribution'), isFalse);
      expect(jsonMap.containsKey('costContribution'), isFalse);
      expect(jsonMap.containsKey('confidenceContribution'), isFalse);
      expect(jsonMap.containsKey('pruningReason'), isFalse);
      expect(jsonMap.containsKey('traversalRank'), isFalse);
    });

    test('converts to canonical JSON string with formatted floats', () {
      const exp = NodeExplanation(
        nodeId: 'node_b',
        score: 0.123456,
        probabilityContribution: 0.99999,
        pruningStatus: 'pruned',
        pruningReason: 'Score below threshold',
        selected: false,
        terminal: true,
      );

      final canonicalJson = exp.toCanonicalJson();

      // Doubles must be formatted to exactly 4 decimal places in canonical JSON
      expect(canonicalJson, contains('"score":"0.1235"'));
      expect(canonicalJson, contains('"probabilityContribution":"1.0000"'));
      expect(canonicalJson, contains('"pruningStatus":"pruned"'));
      expect(
          canonicalJson, contains('"pruningReason":"Score below threshold"'));

      // Check key ordering alphabetically
      final decoded = jsonDecode(canonicalJson) as Map<String, dynamic>;
      final keys = decoded.keys.toList();
      final sortedKeys = List<String>.from(keys)..sort();
      expect(keys, equals(sortedKeys));
    });
  });
}
