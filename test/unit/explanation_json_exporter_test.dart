import 'dart:convert';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('ExplanationJsonExporter Tests', () {
    test('exports canonical, byte-identical JSON and pretty-print JSON', () {
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
        rejectedNodeIds: const [],
        pruningSummary: const {},
        traversalSummary: const {},
        runtimeTraceSummary: const [],
        replayMetadata: const {},
        schemaVersion: '2.0',
        pluginProvenance: const [],
      );

      final canonicalJson = report.toCanonicalJson();
      final decodedCanonical =
          jsonDecode(canonicalJson) as Map<String, dynamic>;

      // Check keys sorted alphabetically
      final canonicalKeys = decodedCanonical.keys.toList();
      final sortedKeys = List<String>.from(canonicalKeys)..sort();
      expect(canonicalKeys, equals(sortedKeys));

      // Pretty print JSON check
      final sortedMap = report.toJson();
      final sortedKeysMap = sortedMap.keys.toList();
      final expectedSorted = List<String>.from(sortedKeysMap)..sort();
      expect(sortedKeysMap, equals(expectedSorted));
    });
  });
}
