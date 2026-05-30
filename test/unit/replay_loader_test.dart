import 'dart:convert';
import 'dart:io';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('ReplayLoader Tests', () {
    late final String validJsonStr;
    late final String corruptJsonStr;
    late final String legacyJsonStr;

    setUpAll(() {
      validJsonStr = File('test/fixtures/replay/valid_debug_snapshot.json')
          .readAsStringSync()
          .trim();
      corruptJsonStr =
          File('test/fixtures/replay/corrupt_debug_snapshot_missing_node.json')
              .readAsStringSync()
              .trim();
      legacyJsonStr = File('test/fixtures/replay/legacy_v1_debug_snapshot.json')
          .readAsStringSync()
          .trim();
    });

    test('load valid DebugSnapshot directly', () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final debugSnapshot = DebugSnapshot.fromJson(jsonMap);

      final session = ReplayLoader.load(debugSnapshot);
      expect(session, isNotNull);
      expect(session.schemaVersion, equals('2.0'));
      expect(session.engineVersion, equals('0.2.0'));
      expect(session.rootId, equals('root'));
      expect(session.selectedPath, equals(['root', 'child1']));
      expect(session.prunedNodeIds, equals(['child2']));
      expect(session.runtimeTraces, contains('Evaluating root'));
      expect(session.pruningTraces,
          contains('Pruning node child2 due to lower score.'));
    });

    test('load valid JSON map', () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final session = ReplayLoader.loadJson(jsonMap);

      expect(session.schemaVersion, equals('2.0'));
      expect(session.engineVersion, equals('0.2.0'));
      expect(session.rootId, equals('root'));
      expect(session.selectedPath, equals(['root', 'child1']));
    });

    test('load canonical JSON string', () {
      final session = ReplayLoader.loadCanonicalJson(validJsonStr);
      expect(session.schemaVersion, equals('2.0'));
      expect(session.selectedPath, equals(['root', 'child1']));
      expect(session.engineVersion, equals('0.2.0'));
    });

    test('reject corrupt JSON with missing selected node in nodeSnapshots', () {
      final jsonMap = jsonDecode(corruptJsonStr) as Map<String, Object?>;
      expect(
        () => ReplayLoader.loadJson(jsonMap),
        throwsA(
          isA<ReplayCorruptException>()
              .having((e) => e.message, 'message',
                  contains('missing from nodeSnapshots'))
              .having((e) => e.missingNodeId, 'missingNodeId',
                  equals('child_missing')),
        ),
      );
    });

    test('reject unsupported newer schema version (> 2.0)', () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final modifiedMap = Map<String, Object?>.from(jsonMap)
        ..['schemaVersion'] = '3.0';

      expect(
        () => ReplayLoader.loadJson(modifiedMap),
        throwsA(
          isA<ReplayCorruptException>()
              .having((e) => e.message, 'message',
                  contains('Unsupported newer schema version'))
              .having((e) => e.schemaVersion, 'schemaVersion', equals('3.0')),
        ),
      );
    });

    test('accept legacy v1 snapshot and upgrade missing fields', () {
      final jsonMap = jsonDecode(legacyJsonStr) as Map<String, Object?>;
      final session = ReplayLoader.loadJson(jsonMap);

      expect(session.schemaVersion, equals('1.0'));
      expect(session.engineVersion, equals('0.1.0'));
      expect(session.rootId, equals('root'));
      expect(session.selectedPath, equals(['root', 'child_v1']));

      // Upgraded default empty unmodifiable collections
      expect(session.prunedNodeIds, isEmpty);
      expect(session.runtimeTraces, isEmpty);
      expect(session.pruningTraces, isEmpty);

      // Verify that mutating these upgraded collections throws UnsupportedError
      expect(() => session.prunedNodeIds.add('error'), throwsUnsupportedError);
      expect(() => session.runtimeTraces.add('error'), throwsUnsupportedError);
      expect(() => session.pruningTraces.add('error'), throwsUnsupportedError);
    });

    test('reject empty selectedPath on non-failed snapshot', () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final modifiedMap = Map<String, Object?>.from(jsonMap)
        ..['selectedPath'] = <String>[];

      expect(
        () => ReplayLoader.loadJson(modifiedMap),
        throwsA(
          isA<ReplayCorruptException>().having(
            (e) => e.message,
            'message',
            contains('selectedPath must not be empty'),
          ),
        ),
      );
    });

    test('accept empty selectedPath if snapshot is failed (metadata has error)',
        () {
      final modifiedMap = <String, Object?>{
        'engineVersion': '0.2.0',
        'rootId': 'root',
        'schemaVersion': '2.0',
        'selectedPath': <String>[],
        'nodeSnapshots': <String, Map<String, dynamic>>{},
        'metadata': <String, dynamic>{'errorMessage': 'Tree cycle detected'},
      };

      final session = ReplayLoader.loadJson(modifiedMap);
      expect(session.selectedPath, isEmpty);
    });

    test('reject non-string values in selectedPath', () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final badPathMap = Map<String, Object?>.from(jsonMap)
        ..['selectedPath'] = [1, 2];
      expect(() => ReplayLoader.loadJson(badPathMap),
          throwsA(isA<ReplayCorruptException>()));
    });

    test('reject non-string values in prunedNodeIds', () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final badPrunedMap = Map<String, Object?>.from(jsonMap)
        ..['prunedNodeIds'] = [1, 2];
      expect(() => ReplayLoader.loadJson(badPrunedMap),
          throwsA(isA<ReplayCorruptException>()));
    });

    test('reject non-string values in runtimeTraces', () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final badRuntimeTraces = Map<String, Object?>.from(jsonMap)
        ..['runtimeTraces'] = [true];
      expect(() => ReplayLoader.loadJson(badRuntimeTraces),
          throwsA(isA<ReplayCorruptException>()));
    });

    test('reject empty rootId', () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final modifiedMap = Map<String, Object?>.from(jsonMap)..['rootId'] = '';
      expect(
        () => ReplayLoader.loadJson(modifiedMap),
        throwsA(
          isA<ReplayCorruptException>().having(
            (e) => e.message,
            'message',
            contains('rootId must not be empty'),
          ),
        ),
      );
    });

    test('never call engine — session has no engine reference', () {
      final jsonMap = jsonDecode(validJsonStr) as Map<String, Object?>;
      final session = ReplayLoader.loadJson(jsonMap);
      // Session only contains a DebugSnapshot, no engine reference
      expect(session.snapshot, isA<DebugSnapshot>());
      // There is no way to invoke the engine from a ReplaySession
    });
  });
}
