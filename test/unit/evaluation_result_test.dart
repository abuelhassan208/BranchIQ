import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('BestPathResult and EvaluationResult Hardening Tests', () {
    test('BestPathResult collection immutability', () {
      const node = DecisionNode.constant(id: 'root', childIds: []);
      final nodesList = [node];
      final nodeIdsList = ['root'];

      final bestPath = BestPathResult(nodes: nodesList, nodeIds: nodeIdsList);

      // Verify that lists inside are unmodifiable
      expect(() => bestPath.nodes.add(node), throwsUnsupportedError);
      expect(() => bestPath.nodeIds.add('other'), throwsUnsupportedError);

      // Verify json serialization
      final json = bestPath.toJson();
      final reconstructed = BestPathResult.fromJson(json);
      expect(reconstructed.nodeIds, equals(['root']));
      expect(reconstructed.nodes.first.id, equals('root'));
    });

    test('EvaluationResult fields and immutability', () {
      const root = DecisionNode.constant(id: 'root', childIds: []);
      final bestPath = BestPathResult(nodes: [root], nodeIds: ['root']);
      final tracesList = ['step1', 'step2'];
      const snapshot = DebugSnapshot(
        engineVersion: '0.1.0',
        rootId: 'root',
        selectedPath: ['root'],
        nodeSnapshots: {},
        pruningTraces: [],
        metadata: {},
      );

      final result = EvaluationResult(
        bestPath: bestPath,
        traces: tracesList,
        durationMs: 15,
        wasFallback: true,
        errorMessage: 'error_occurred',
        debugSnapshot: snapshot,
      );

      expect(result.bestPath.nodeIds, equals(['root']));
      expect(result.traces, equals(['step1', 'step2']));
      expect(() => result.traces.add('step3'), throwsUnsupportedError);
      expect(result.durationMs, equals(15));
      expect(result.wasFallback, isTrue);
      expect(result.errorMessage, equals('error_occurred'));
      expect(result.debugSnapshot?.engineVersion, equals('0.1.0'));
    });

    test('EvaluationResult JSON roundtrip', () {
      const root = DecisionNode.constant(id: 'root', childIds: []);
      final bestPath = BestPathResult(nodes: [root], nodeIds: ['root']);
      const snapshot = DebugSnapshot(
        engineVersion: '0.1.0',
        rootId: 'root',
        selectedPath: ['root'],
        nodeSnapshots: {
          'root': {'score': 0.8}
        },
        pruningTraces: ['pruned_node'],
        metadata: {'run_id': 99},
      );

      final result = EvaluationResult(
        bestPath: bestPath,
        traces: const ['t1'],
        durationMs: 12,
        wasFallback: false,
        debugSnapshot: snapshot,
      );

      final json = result.toJson();
      final reconstructed = EvaluationResult.fromJson(json);

      expect(reconstructed.bestPath.nodeIds, equals(['root']));
      expect(reconstructed.traces, equals(['t1']));
      expect(reconstructed.durationMs, equals(12));
      expect(reconstructed.wasFallback, isFalse);
      expect(reconstructed.errorMessage, isNull);
      expect(reconstructed.debugSnapshot?.rootId, equals('root'));
      expect(reconstructed.debugSnapshot?.nodeSnapshots['root']?['score'],
          equals(0.8));
      expect(
          reconstructed.debugSnapshot?.pruningTraces, equals(['pruned_node']));
      expect(reconstructed.debugSnapshot?.metadata['run_id'], equals(99));
    });
  });
}
