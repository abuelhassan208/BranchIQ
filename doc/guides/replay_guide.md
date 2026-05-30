# Replay Guide

BranchIQ v0.2 provides a snapshot-driven replay layer that lets you reconstruct, inspect, and compare past evaluations without re-running the engine.

---

## Architecture Overview

The replay layer is built around four public classes:

| Class | Purpose |
|---|---|
| `ReplayLoader` | Loads a `DebugSnapshot` (direct, JSON map, or canonical string) into a `ReplaySession` |
| `ReplaySession` | Holds the immutable, reconstructed evaluation state |
| `ReplayInspector` | Provides query APIs over a session's nodes, paths, and traces |
| `ReplayCorruptException` | Thrown when a snapshot fails integrity validation |

The replay layer is **closed**. It never re-runs scoring, pruning, or traversal. All data comes exclusively from the serialized snapshot.

---

## Quick Start

```dart
import 'package:branchiq/branchiq.dart';

// 1. Run the engine with debug mode
final result = engine.evaluateSync(
  tree: tree,
  scoringConfig: scoringConfig,
  pruningConfig: pruningConfig,
  traversalConfig: traversalConfig,
  enableDebug: true,
);

// 2. Export and load the snapshot
final snapshot = engine.exportDebugSnapshot(result);
final session = ReplayLoader.load(snapshot);

// 3. Serialize to canonical JSON (safe for storage and diffing)
final canonicalJson = session.toCanonicalJson();

// 4. Later — reconstruct from the stored string
final restored = ReplayLoader.loadCanonicalJson(canonicalJson);

// 5. Inspect
final inspector = ReplayInspector(restored);
final path = inspector.inspectSelectedPath();
final pruned = inspector.inspectPrunedNodes();
```

---

## Loading Snapshots

`ReplayLoader` supports three input formats:

### Direct DebugSnapshot

```dart
final session = ReplayLoader.load(snapshot);
```

This extracts the JSON payload from the snapshot, injects a `schemaVersion` if missing, and runs full validation.

### Raw JSON Map

```dart
final jsonMap = jsonDecode(jsonString) as Map<String, Object?>;
final session = ReplayLoader.loadJson(jsonMap);
```

Useful when you've stored the snapshot as a JSON file. The loader validates all types, upgrades legacy v1 fields to safe defaults, and checks structural integrity.

### Canonical JSON String

```dart
final session = ReplayLoader.loadCanonicalJson(canonicalJsonString);
```

Performs byte-equivalence validation first (the string must exactly match the canonical output of `CanonicalJsonEncoder.encode`), then loads.

---

## Validation Rules

The loader applies these integrity checks:

| Rule | Error |
|---|---|
| `schemaVersion > 2.0` | `ReplayCorruptException` with `schemaVersion` detail |
| `rootId` is empty | `ReplayCorruptException` |
| `selectedPath` references a missing node | `ReplayCorruptException` with `missingNodeId` |
| `selectedPath` is empty on a non-failed evaluation | `ReplayCorruptException` |
| List fields contain non-String elements | `ReplayCorruptException` |

> [!NOTE]
> Legacy v1 snapshots (without `schemaVersion`, `prunedNodeIds`, or trace fields) are accepted and upgraded. Missing fields default to empty unmodifiable collections.

---

## Working with ReplaySession

A `ReplaySession` is immutable. All collections are wrapped in `List.unmodifiable` or `Map.unmodifiable`:

```dart
session.selectedPath.add('x');     // ← throws UnsupportedError
session.nodeSnapshots['x'] = {};   // ← throws UnsupportedError
```

### Serialization

| Method | Output |
|---|---|
| `toJson()` | Stable `Map<String, Object?>` with alphabetically sorted top-level keys |
| `toCanonicalJson()` | Compact, byte-identical canonical JSON string |

The canonical JSON output is guaranteed to be identical across invocations, platforms, and Dart runtimes.

---

## Inspecting Sessions

`ReplayInspector` provides offline queries over a session:

### Node Lookup

```dart
final inspector = ReplayInspector(session);

if (inspector.containsNode('approve')) {
  final nodeData = inspector.inspectNode('approve');
  print('Score: ${nodeData['score']}');
}
```

Calling `inspectNode` for a missing node throws `ReplayCorruptException`.

### Selected Path

```dart
final pathNodes = inspector.inspectSelectedPath();
for (final node in pathNodes) {
  print('[${node['id']}] score=${node['score']} depth=${node['depth']}');
}
```

Returns nodes in the original traversal order.

### Pruned Nodes

```dart
final prunedNodes = inspector.inspectPrunedNodes();
```

Returns pruned node data **sorted lexicographically by node ID** — deterministic ordering for diffs and regression tests.

### Trace Logs

```dart
inspector.runtimeTraceLines();   // Chronological engine execution log
inspector.pruningTraceLines();   // Pruning-specific trace entries
```

---

## Error Handling

All replay errors surface as `ReplayCorruptException`:

```dart
try {
  final session = ReplayLoader.loadCanonicalJson(jsonString);
} on ReplayCorruptException catch (e) {
  print('Corruption: ${e.message}');
  print('Missing node: ${e.missingNodeId}');
  print('Mismatch: ${e.mismatchReason}');
  print('Schema: ${e.schemaVersion}');
}
```

The exception carries structured diagnostic properties so tooling can report precise failure causes.

---

## Replay Safety Guarantees

The replay layer enforces these invariants:

1. **No engine calls** — `ReplaySession` and `ReplayInspector` never invoke `BranchIQEngine.evaluateSync()` or any scoring, pruning, or traversal logic.
2. **No mutation** — All session collections are `unmodifiable`. The source `DebugSnapshot` is never modified.
3. **No async** — Every operation is synchronous. No isolates, no futures, no I/O.
4. **Byte-identical serialization** — `toCanonicalJson()` produces the exact same string on every call, on every platform.
5. **Deterministic ordering** — Selected path preserves traversal order; pruned nodes are sorted lexicographically.

---

## Full Example

See [`example/replay_example.dart`](../../example/replay_example.dart):

```bash
dart run example/replay_example.dart
```
