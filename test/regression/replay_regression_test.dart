import 'dart:convert';
import 'dart:io';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('Replay Regression and Determinism Tests', () {
    late final String validJsonStr;

    setUpAll(() {
      validJsonStr = File('test/fixtures/replay/valid_debug_snapshot.json')
          .readAsStringSync()
          .trim();
    });

    test('300+ repeated loadJson calls produce strictly identical sessions',
        () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final referenceSession =
          ReplayLoader.loadJson(Map<String, Object?>.from(jsonMap));
      final referenceCanonical = referenceSession.toCanonicalJson();
      final referenceJson = referenceSession.toJson();
      final referencePathLen = referenceSession.selectedPath.length;
      final referencePrunedLen = referenceSession.prunedNodeIds.length;
      final referenceTracesLen = referenceSession.runtimeTraces.length;

      for (int i = 0; i < 300; i++) {
        final session =
            ReplayLoader.loadJson(Map<String, Object?>.from(jsonMap));

        // Canonical JSON byte-equivalence
        expect(session.toCanonicalJson(), equals(referenceCanonical),
            reason: 'Canonical JSON mismatch at iteration $i');

        // Structural equivalence
        expect(
            session.toJson().keys.toList(), equals(referenceJson.keys.toList()),
            reason: 'JSON keys mismatch at iteration $i');
        expect(session.selectedPath.length, equals(referencePathLen),
            reason: 'selectedPath length mismatch at iteration $i');
        expect(session.prunedNodeIds.length, equals(referencePrunedLen),
            reason: 'prunedNodeIds length mismatch at iteration $i');
        expect(session.runtimeTraces.length, equals(referenceTracesLen),
            reason: 'runtimeTraces length mismatch at iteration $i');

        // Field-level identity
        expect(session.schemaVersion, equals(referenceSession.schemaVersion));
        expect(session.engineVersion, equals(referenceSession.engineVersion));
        expect(session.rootId, equals(referenceSession.rootId));
        expect(session.selectedPath, equals(referenceSession.selectedPath));
        expect(session.prunedNodeIds, equals(referenceSession.prunedNodeIds));
      }
    });

    test(
        '300+ repeated loadCanonicalJson calls produce byte-identical canonical output',
        () {
      final referenceSession = ReplayLoader.loadCanonicalJson(validJsonStr);
      final referenceCanonical = referenceSession.toCanonicalJson();

      for (int i = 0; i < 300; i++) {
        final session = ReplayLoader.loadCanonicalJson(validJsonStr);
        expect(session.toCanonicalJson(), equals(referenceCanonical),
            reason: 'Canonical output mismatch at iteration $i');
      }
    });

    test('300+ ReplayInspector queries produce identical outputs', () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final referenceSession =
          ReplayLoader.loadJson(Map<String, Object?>.from(jsonMap));
      final referenceInspector = ReplayInspector(referenceSession);

      final referencePath = referenceInspector.inspectSelectedPath();
      final referencePruned = referenceInspector.inspectPrunedNodes();
      final referenceRuntimeTraces = referenceInspector.runtimeTraceLines();
      final referencePruningTraces = referenceInspector.pruningTraceLines();

      for (int i = 0; i < 300; i++) {
        final session =
            ReplayLoader.loadJson(Map<String, Object?>.from(jsonMap));
        final inspector = ReplayInspector(session);

        final path = inspector.inspectSelectedPath();
        expect(path.length, equals(referencePath.length),
            reason: 'Path length mismatch at iteration $i');
        for (int j = 0; j < path.length; j++) {
          expect(path[j]['id'], equals(referencePath[j]['id']),
              reason: 'Path node[$j] ID mismatch at iteration $i');
        }

        final pruned = inspector.inspectPrunedNodes();
        expect(pruned.length, equals(referencePruned.length),
            reason: 'Pruned count mismatch at iteration $i');
        for (int j = 0; j < pruned.length; j++) {
          expect(pruned[j]['id'], equals(referencePruned[j]['id']),
              reason: 'Pruned node[$j] ID mismatch at iteration $i');
        }

        expect(inspector.runtimeTraceLines(), equals(referenceRuntimeTraces),
            reason: 'Runtime traces mismatch at iteration $i');
        expect(inspector.pruningTraceLines(), equals(referencePruningTraces),
            reason: 'Pruning traces mismatch at iteration $i');
      }
    });

    test(
        '300+ DebugSnapshot load-and-replay roundtrips produce identical sessions',
        () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final referenceSnapshot = DebugSnapshot.fromJson(jsonMap);
      final referenceSession = ReplayLoader.load(referenceSnapshot);
      final referenceCanonical = referenceSession.toCanonicalJson();

      for (int i = 0; i < 300; i++) {
        final snapshot =
            DebugSnapshot.fromJson(Map<String, Object?>.from(jsonMap));
        final session = ReplayLoader.load(snapshot);
        expect(session.toCanonicalJson(), equals(referenceCanonical),
            reason:
                'DebugSnapshot roundtrip canonical mismatch at iteration $i');
      }
    });
  });
}
