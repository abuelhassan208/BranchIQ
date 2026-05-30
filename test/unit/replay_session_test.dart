import 'dart:convert';
import 'dart:io';
import 'package:branchiq/branchiq.dart';
import 'package:test/test.dart';

void main() {
  group('ReplaySession Tests', () {
    late final ReplaySession session;

    setUpAll(() {
      final jsonStr = File('test/fixtures/replay/valid_debug_snapshot.json')
          .readAsStringSync()
          .trim();
      final jsonMap = jsonDecode(jsonStr) as Map<String, Object?>;
      session = ReplayLoader.loadJson(jsonMap);
    });

    test('all collections are unmodifiable', () {
      expect(() => session.selectedPath.add('mutant'), throwsUnsupportedError);
      expect(() => session.prunedNodeIds.add('mutant'), throwsUnsupportedError);
      expect(() => session.runtimeTraces.add('mutant'), throwsUnsupportedError);
      expect(() => session.pruningTraces.add('mutant'), throwsUnsupportedError);
      expect(
          () => session.nodeSnapshots['mutant'] = {}, throwsUnsupportedError);

      // Nested node snapshot maps must also be unmodifiable
      final firstNode = session.nodeSnapshots[session.selectedPath.first]!;
      expect(() => firstNode['mutant'] = true, throwsUnsupportedError);
    });

    test('toJson produces stable key-sorted map', () {
      final json = session.toJson();

      expect(json, isA<Map<String, Object?>>());
      expect(
          json.keys.toList(),
          equals([
            'engineVersion',
            'nodeSnapshots',
            'pluginProvenance',
            'prunedNodeIds',
            'pruningTraces',
            'rootId',
            'runtimeTraces',
            'schemaVersion',
            'selectedPath',
          ]));
    });

    test('toJson preserves all session values', () {
      final json = session.toJson();
      expect(json['engineVersion'], equals('0.2.0'));
      expect(json['rootId'], equals('root'));
      expect(json['schemaVersion'], equals('2.0'));
      expect(json['selectedPath'], equals(['root', 'child1']));
      expect(json['prunedNodeIds'], equals(['child2']));
    });

    test('toCanonicalJson produces byte-identical output across calls', () {
      final canonical1 = session.toCanonicalJson();
      final canonical2 = session.toCanonicalJson();

      expect(canonical1, equals(canonical2));
      expect(canonical1, isA<String>());
      expect(canonical1, isNot(contains('\r')));
    });

    test('toCanonicalJson is compact (no whitespace indentation)', () {
      final canonical = session.toCanonicalJson();
      expect(canonical, isNot(contains('\n')));
      // No pretty-printing spaces after colons/commas
      expect(canonical, isNot(contains(': ')));
    });

    test('toJson and toCanonicalJson agree on content', () {
      final json = session.toJson();
      final fromCanonical =
          jsonDecode(session.toCanonicalJson()) as Map<String, Object?>;

      // Both should have the same keys
      expect(fromCanonical.keys.toSet(), equals(json.keys.toSet()));
      expect(fromCanonical['engineVersion'], equals(json['engineVersion']));
      expect(fromCanonical['rootId'], equals(json['rootId']));
      expect(fromCanonical['schemaVersion'], equals(json['schemaVersion']));
    });

    test('schema version defaults to 1.0 for legacy snapshots', () {
      final legacyStr =
          File('test/fixtures/replay/legacy_v1_debug_snapshot.json')
              .readAsStringSync()
              .trim();
      final legacyMap = jsonDecode(legacyStr) as Map<String, Object?>;
      final legacySession = ReplayLoader.loadJson(legacyMap);

      expect(legacySession.schemaVersion, equals('1.0'));

      final json = legacySession.toJson();
      expect(json['schemaVersion'], equals('1.0'));
    });

    test('session contains original DebugSnapshot reference', () {
      expect(session.snapshot, isA<DebugSnapshot>());
      expect(session.snapshot.rootId, equals(session.rootId));
      expect(session.snapshot.engineVersion, equals(session.engineVersion));
    });
  });
}
