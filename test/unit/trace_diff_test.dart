import 'package:test/test.dart';
import 'package:branchiq/branchiq.dart';

void main() {
  group('TraceDiff Tests', () {
    test('computes chronological trace differences correctly', () {
      final source = [
        'Evaluating root',
        'Traversing approve',
        'Pruning reject'
      ];
      final target = ['Evaluating root', 'Traversing defer', 'New step'];

      final diff = TraceDiff.compare(source, target);

      expect(diff.sourceOnlyTraces,
          equals(['Traversing approve', 'Pruning reject']));
      expect(diff.targetOnlyTraces, equals(['Traversing defer', 'New step']));
      expect(diff.sharedTraces, equals(['Evaluating root']));
      expect(diff.traceCountDelta, equals(0)); // 3 - 3
    });

    test(
        'retains exact relative ordering in source-only and target-only traces',
        () {
      final source = ['A', 'B', 'C'];
      final target = ['B', 'D', 'E'];

      final diff = TraceDiff.compare(source, target);

      expect(diff.sourceOnlyTraces, equals(['A', 'C']));
      expect(diff.targetOnlyTraces, equals(['D', 'E']));
      expect(diff.sharedTraces, equals(['B']));
      expect(diff.traceCountDelta, equals(0));
    });

    test('serializes to JSON correctly', () {
      final source = ['A'];
      final target = ['A', 'B'];

      final diff = TraceDiff.compare(source, target);
      final json = diff.toJson();

      expect(json['sharedTraces'], equals(['A']));
      expect(json['sourceOnlyTraces'], isEmpty);
      expect(json['targetOnlyTraces'], equals(['B']));
      expect(json['traceCountDelta'], equals(1));
    });
  });
}
