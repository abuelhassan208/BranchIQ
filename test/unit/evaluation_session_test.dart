import 'dart:convert';
import 'package:branchiq/branchiq.dart';
import 'package:branchiq/src/runtime/evaluation_session.dart';
import 'package:branchiq/src/runtime/runtime_state.dart';
import 'package:branchiq/src/debug/runtime_trace.dart';
import 'package:test/test.dart';

void main() {
  group('EvaluationSession Tests', () {
    final root = const DecisionNode.constant(id: 'root', childIds: []);
    final tree = DecisionTree.fromNodes([root]);
    final configs = EvaluationConfigs(
      scoring: ScoringConfig.balanced(),
      pruning: PruningConfig.defaultSettings(),
      traversal: const TraversalConfig(),
    );

    test('should construct with correct attributes', () {
      final session = EvaluationSession(
        sessionId: 'test_session',
        runtimeState: RuntimeState.idle,
        startedAt: 12345,
        tree: tree,
        configs: configs,
        traces: const [],
        debugEnabled: true,
      );

      expect(session.sessionId, equals('test_session'));
      expect(session.runtimeState, equals(RuntimeState.idle));
      expect(session.startedAt, equals(12345));
      expect(session.completedAt, isNull);
      expect(session.tree.root.id, equals('root'));
      expect(session.traces, isEmpty);
      expect(session.debugEnabled, isTrue);
    });

    test('should enforce immutable unmodifiable traces list', () {
      final traceList = <RuntimeTrace>[
        const RuntimeTrace(phase: TracePhase.validation, message: 'Step 1'),
      ];
      final session = EvaluationSession(
        sessionId: 'test_session',
        runtimeState: RuntimeState.idle,
        startedAt: 12345,
        tree: tree,
        configs: configs,
        traces: traceList,
        debugEnabled: true,
      );

      expect(session.traces, hasLength(1));
      expect(
          () => (session.traces as List).add(
              const RuntimeTrace(phase: TracePhase.scoring, message: 'Step 2')),
          throwsUnsupportedError);
    });

    test('copyWith should return a new instance with updated properties', () {
      final session = EvaluationSession(
        sessionId: 'test_session',
        runtimeState: RuntimeState.idle,
        startedAt: 12345,
        tree: tree,
        configs: configs,
        traces: const [],
        debugEnabled: true,
      );

      final updated = session.copyWith(
        runtimeState: RuntimeState.completed,
        completedAt: 12350,
        traces: [
          const RuntimeTrace(phase: TracePhase.completion, message: 'Done')
        ],
      );

      expect(updated.sessionId, equals(session.sessionId));
      expect(updated.runtimeState, equals(RuntimeState.completed));
      expect(updated.startedAt, equals(12345));
      expect(updated.completedAt, equals(12350));
      expect(updated.traces, hasLength(1));
      expect(updated.traces.first.message, equals('Done'));
      expect(updated.debugEnabled, isTrue);
    });

    test('should support stable JSON roundtrip serialization', () {
      final session = EvaluationSession(
        sessionId: 'test_session',
        runtimeState: RuntimeState.completed,
        startedAt: 12345,
        completedAt: 12350,
        tree: tree,
        configs: configs,
        traces: const [
          RuntimeTrace(
              phase: TracePhase.validation, message: 'Validation start'),
          RuntimeTrace(phase: TracePhase.completion, message: 'Completion end'),
        ],
        debugEnabled: true,
      );

      final jsonMap = session.toJson();
      expect(jsonMap['sessionId'], equals('test_session'));
      expect(jsonMap['runtimeState'], equals('completed'));
      expect(jsonMap['startedAt'], equals(12345));
      expect(jsonMap['completedAt'], equals(12350));
      expect(jsonMap['debugEnabled'], isTrue);

      final jsonStr1 = json.encode(jsonMap);

      final reconstructed = EvaluationSession.fromJson(jsonMap);
      final jsonStr2 = json.encode(reconstructed.toJson());

      expect(jsonStr1, equals(jsonStr2));
      expect(reconstructed.sessionId, equals(session.sessionId));
      expect(reconstructed.runtimeState, equals(session.runtimeState));
      expect(reconstructed.traces, hasLength(2));
      expect(reconstructed.traces.first.message, equals('Validation start'));
      expect(reconstructed.traces.last.message, equals('Completion end'));
    });
  });
}
