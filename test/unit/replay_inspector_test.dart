import 'dart:convert';
import 'dart:io';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('ReplayInspector Tests', () {
    late final ReplaySession session;
    late final ReplayInspector inspector;

    setUpAll(() {
      final jsonStr = File('test/fixtures/replay/valid_debug_snapshot.json')
          .readAsStringSync()
          .trim();
      final jsonMap = jsonDecode(jsonStr) as Map<String, Object?>;
      session = ReplayLoader.loadJson(jsonMap);
      inspector = ReplayInspector(session);
    });

    test('containsNode returns true for existing nodes', () {
      expect(inspector.containsNode('root'), isTrue);
      expect(inspector.containsNode('child1'), isTrue);
      expect(inspector.containsNode('child2'), isTrue);
    });

    test('containsNode returns false for non-existing nodes', () {
      expect(inspector.containsNode('nonexistent'), isFalse);
      expect(inspector.containsNode(''), isFalse);
    });

    test('inspectNode returns correct node data for existing node', () {
      final rootNode = inspector.inspectNode('root');
      expect(rootNode['id'], equals('root'));
      expect(rootNode['depth'], equals(0));

      final child1Node = inspector.inspectNode('child1');
      expect(child1Node['id'], equals('child1'));
      expect(child1Node['depth'], equals(1));
    });

    test('inspectNode throws ReplayCorruptException for missing node', () {
      expect(
        () => inspector.inspectNode('nonexistent_node'),
        throwsA(
          isA<ReplayCorruptException>()
              .having((e) => e.message, 'message',
                  contains('missing from nodeSnapshots'))
              .having((e) => e.missingNodeId, 'missingNodeId',
                  equals('nonexistent_node')),
        ),
      );
    });

    test('inspectSelectedPath preserves traversal order', () {
      final pathNodes = inspector.inspectSelectedPath();
      expect(pathNodes, hasLength(2));

      // First node in path should be root
      expect(pathNodes[0]['id'], equals('root'));
      // Second node in path should be child1
      expect(pathNodes[1]['id'], equals('child1'));
    });

    test('inspectSelectedPath returns unmodifiable list', () {
      final pathNodes = inspector.inspectSelectedPath();
      expect(() => pathNodes.add({}), throwsUnsupportedError);
    });

    test('inspectPrunedNodes returns nodes sorted lexicographically by id', () {
      final prunedNodes = inspector.inspectPrunedNodes();
      expect(prunedNodes, hasLength(1));
      expect(prunedNodes[0]['id'], equals('child2'));
    });

    test('inspectPrunedNodes sorts multiple pruned nodes lexicographically',
        () {
      // Create a snapshot with multiple pruned nodes
      final multiPrunedJson = <String, Object?>{
        'engineVersion': '0.2.0',
        'rootId': 'root',
        'schemaVersion': '2.0',
        'selectedPath': ['root'],
        'prunedNodeIds': ['zeta_node', 'alpha_node', 'mid_node'],
        'runtimeTraces': <String>[],
        'pruningTraces': <String>[],
        'nodeSnapshots': <String, Map<String, dynamic>>{
          'root': <String, dynamic>{'id': 'root', 'depth': 0},
          'alpha_node': <String, dynamic>{'id': 'alpha_node', 'depth': 1},
          'mid_node': <String, dynamic>{'id': 'mid_node', 'depth': 1},
          'zeta_node': <String, dynamic>{'id': 'zeta_node', 'depth': 1},
        },
      };

      final multiSession = ReplayLoader.loadJson(multiPrunedJson);
      final multiInspector = ReplayInspector(multiSession);
      final sorted = multiInspector.inspectPrunedNodes();

      expect(sorted, hasLength(3));
      expect(sorted[0]['id'], equals('alpha_node'));
      expect(sorted[1]['id'], equals('mid_node'));
      expect(sorted[2]['id'], equals('zeta_node'));
    });

    test('inspectPrunedNodes returns unmodifiable list', () {
      final prunedNodes = inspector.inspectPrunedNodes();
      expect(() => prunedNodes.add({}), throwsUnsupportedError);
    });

    test('runtimeTraceLines returns chronological trace lines', () {
      final traces = inspector.runtimeTraceLines();
      expect(traces, hasLength(3));
      expect(traces[0], equals('Evaluating root'));
      expect(traces[1], equals('Traversing to child1'));
      expect(traces[2], equals('Traversing to child2'));
    });

    test('runtimeTraceLines returns unmodifiable list', () {
      final traces = inspector.runtimeTraceLines();
      expect(() => traces.add('mutant'), throwsUnsupportedError);
    });

    test('pruningTraceLines returns pruning log entries', () {
      final traces = inspector.pruningTraceLines();
      expect(traces, hasLength(1));
      expect(traces[0], equals('Pruning node child2 due to lower score.'));
    });

    test('pruningTraceLines returns unmodifiable list', () {
      final traces = inspector.pruningTraceLines();
      expect(() => traces.add('mutant'), throwsUnsupportedError);
    });
  });
}
