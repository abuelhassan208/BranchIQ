import 'dart:convert';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('ExplanationReport Tests', () {
    test('creates report with immutable collections', () {
      final nodeExplanations = {
        'root': const NodeExplanation(
          nodeId: 'root',
          score: 1.0000,
          pruningStatus: 'retained',
          selected: true,
          terminal: false,
          traversalRank: 1,
        ),
        'child': const NodeExplanation(
          nodeId: 'child',
          score: 0.8500,
          pruningStatus: 'retained',
          selected: true,
          terminal: true,
          traversalRank: 2,
        ),
      };

      final report = ExplanationReport(
        rootId: 'root',
        selectedPath: ['root', 'child'],
        selectedUtility: 0.8500,
        nodeExplanations: nodeExplanations,
        rejectedNodeIds: ['pruned_node'],
        pruningSummary: {'threshold': 0.5},
        traversalSummary: {'strategy': 'depth_first'},
        runtimeTraceSummary: ['step 1', 'step 2'],
        replayMetadata: {'env': 'test'},
        schemaVersion: '2.0',
        pluginProvenance: const [],
      );

      expect(report.rootId, equals('root'));
      expect(report.selectedPath, equals(['root', 'child']));
      expect(report.selectedUtility, equals(0.8500));
      expect(report.nodeExplanations.containsKey('root'), isTrue);
      expect(report.rejectedNodeIds, equals(['pruned_node']));
      expect(report.schemaVersion, equals('2.0'));

      // Invariants: collections must be immutable and throw UnsupportedError on modification attempts
      expect(() => report.selectedPath.add('new_node'), throwsUnsupportedError);
      expect(
          () => report.rejectedNodeIds.add('new_node'), throwsUnsupportedError);
      expect(
          () => report.nodeExplanations['new_node'] = nodeExplanations['root']!,
          throwsUnsupportedError);
    });

    test('serializes to stable canonical JSON representation', () {
      final nodeExplanations = {
        'root': const NodeExplanation(
          nodeId: 'root',
          score: 1.0000,
          pruningStatus: 'retained',
          selected: true,
          terminal: true,
        ),
      };

      final report = ExplanationReport(
        rootId: 'root',
        selectedPath: ['root'],
        selectedUtility: 1.0000,
        nodeExplanations: nodeExplanations,
        rejectedNodeIds: [
          'c_node',
          'a_node',
          'b_node'
        ], // lexicographical sorting needed
        pruningSummary: {'a': 1},
        traversalSummary: {'b': 2},
        runtimeTraceSummary: ['trace1'],
        replayMetadata: {'meta': 'val'},
        schemaVersion: '2.0',
        pluginProvenance: const [],
      );

      final jsonMap = report.toJson();
      expect(jsonMap['rootId'], equals('root'));
      expect(jsonMap['selectedUtility'], equals(1.0000));

      // rejectedNodeIds must be sorted lexicographically
      expect(
          jsonMap['rejectedNodeIds'], equals(['a_node', 'b_node', 'c_node']));

      final canonicalStr = report.toCanonicalJson();
      final decoded = jsonDecode(canonicalStr) as Map<String, dynamic>;
      final keys = decoded.keys.toList();
      final sortedKeys = List<String>.from(keys)..sort();
      expect(keys, equals(sortedKeys));
    });
  });
}
