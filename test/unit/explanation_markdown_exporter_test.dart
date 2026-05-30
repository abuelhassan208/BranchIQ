import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('ExplanationMarkdownExporter Tests', () {
    test('generates expected markdown headings and structure', () {
      final nodeExplanations = {
        'root': const NodeExplanation(
          nodeId: 'root',
          score: 1.0000,
          pruningStatus: 'retained',
          selected: true,
          terminal: false,
          traversalRank: 1,
        ),
        'approve': const NodeExplanation(
          nodeId: 'approve',
          score: 0.9500,
          pruningStatus: 'retained',
          selected: true,
          terminal: true,
          traversalRank: 2,
        ),
        'reject': const NodeExplanation(
          nodeId: 'reject',
          score: 0.1500,
          pruningStatus: 'pruned',
          pruningReason: 'Score below threshold',
          selected: false,
          terminal: true,
        ),
      };

      final report = ExplanationReport(
        rootId: 'root',
        selectedPath: ['root', 'approve'],
        selectedUtility: 0.9500,
        nodeExplanations: nodeExplanations,
        rejectedNodeIds: ['reject'],
        pruningSummary: {'costCeiling': 10.0},
        traversalSummary: {'strategy': 'best_utility'},
        runtimeTraceSummary: [
          'Validation started',
          'Validation successful',
          'Pipeline completed'
        ],
        replayMetadata: {'telemetry': 'enabled'},
        schemaVersion: '2.0',
        pluginProvenance: const [],
      );

      final markdown = report.toMarkdown();

      // Check for exact heading structures
      expect(markdown, contains('# BranchIQ Explanation Report'));
      expect(markdown, contains('## Selected Path'));
      expect(markdown, contains('## Utility Summary'));
      expect(markdown, contains('## Traversal Analysis'));
      expect(markdown, contains('## Pruning Analysis'));
      expect(markdown, contains('## Node Explanations'));
      expect(markdown, contains('## Runtime Traces'));

      // Check formatted content and floats
      expect(markdown, contains('Path: root → approve'));
      expect(markdown, contains('- root'));
      expect(markdown, contains('- approve'));
      expect(markdown, contains('0.9500')); // Selected Path Utility formatted
      expect(markdown, contains('best_utility'));
      expect(markdown, contains('Score below threshold'));

      // Check table presence for node explanations
      expect(markdown, contains('Node ID'));
      expect(markdown, contains('Score'));
      expect(markdown, contains('Status'));
      expect(markdown, contains('Selected'));
      expect(markdown, contains('Terminal'));
      expect(markdown, contains('Rank'));
      expect(markdown, contains('Pruning Reason'));
    });
  });
}
