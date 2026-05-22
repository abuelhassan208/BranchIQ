# Debugging Guide

BranchIQ provides structured diagnostics to help you understand exactly why a path was chosen and where the evaluation process went.

---

## Enabling Debug Mode

Pass `enableDebug: true` when calling `evaluateSync`:

```dart
final result = engine.evaluateSync(
  tree: tree,
  scoringConfig: scoringConfig,
  pruningConfig: pruningConfig,
  traversalConfig: traversalConfig,
  enableDebug: true,  // Activates full trace collection
);
```

Without this flag, `result.debugSnapshot` will be `null` and `result.traces` will be empty.

---

## Runtime Traces

Runtime traces are a chronological log of the evaluation pipeline phases.

```dart
for (final trace in result.traces) {
  print(trace);
}
```

Example output:

```
[VALIDATION] Validation started.
[VALIDATION] Validation successful.
[SCORING] Scoring started.
[SCORING] Scoring completed.
[PRUNING] Pruning started.
[PRUNING] Pruning completed.
[TRAVERSAL] Traversal started.
[TRAVERSAL] Traversal completed.
[COMPLETION] Pipeline completed in completed state.
```

Trace phases:
| Phase | What it covers |
|---|---|
| `[VALIDATION]` | Structural tree checks, cycle detection |
| `[SCORING]` | BFS confidence propagation and node scoring |
| `[PRUNING]` | Branch elimination by probability, score, beam width |
| `[TRAVERSAL]` | Priority-first path search |
| `[FALLBACK]` | Activated when no valid child paths exist |
| `[COMPLETION]` | Final pipeline state |

---

## The DebugSnapshot

The `DebugSnapshot` contains everything about the completed evaluation:

```dart
final snapshot = engine.exportDebugSnapshot(result);

print('Root ID:        ${snapshot.rootId}');
print('Selected Path:  ${snapshot.selectedPath.join(' -> ')}');
print('Pruned Nodes:   ${snapshot.prunedNodeIds.join(', ')}');
print('Engine Version: ${snapshot.engineVersion}');
```

---

## Per-Node Scoring Snapshot

Every node in the tree gets an entry in `nodeSnapshots`, showing its computed score, depth, confidence, and pruning reason (if any).

```dart
for (final entry in snapshot.nodeSnapshots.entries) {
  final id = entry.key;
  final data = entry.value;

  print('[$id]');
  print('  score:      ${data['score']}');
  print('  confidence: ${data['confidence']}');
  print('  depth:      ${data['depth']}');

  if (data['pruningReason'] != null) {
    print('  PRUNED:     ${data['pruningReason']}');
  }
}
```

---

## Pruning Diagnostics

To see only the pruned nodes:

```dart
for (final id in snapshot.prunedNodeIds) {
  final reason = snapshot.nodeSnapshots[id]?['pruningReason'];
  print('Pruned "$id": $reason');
}
```

| Pruning Reason | Meaning |
|---|---|
| `probabilityBelowThreshold` | Node `probability` was below `minProbability` |
| `scoreBelowThreshold` | Node score was below `minScore` |
| `beamWidthExceeded` | Node ranked outside the top-N siblings |
| `maxDepthExceeded` | Node was deeper than `maxDepth` |
| `maxNodeLimitExceeded` | Total node evaluation budget was exhausted |

---

## Traversal & Scoring Summaries

Compact summaries of the configuration used during evaluation:

```dart
print('Traversal Summaries:');
snapshot.traversalSummaries.forEach((k, v) => print('  $k: $v'));

print('Scoring Summaries:');
snapshot.scoringSummaries.forEach((k, v) => print('  $k: $v'));
```

Example output:

```
Traversal Summaries:
  strategy: priorityFirst
  maxDepth: 4
  maxNodeLimit: 100
  totalUtility: 0.888

Scoring Summaries:
  costCeiling: 100.0
  wp: 0.333
  wi: 0.333
  wc: 0.333
```

---

## Benchmark Snapshots

Enable benchmark mode to collect execution metrics:

```dart
final result = engine.evaluateSync(
  ...
  enableBenchmark: true,
);

final bench = result.benchmarkSnapshot!;
print('Nodes evaluated:   ${bench.totalNodes}');
print('Traversal steps:   ${bench.traversalIterations}');
print('Execution steps:   ${bench.executionSteps}');
print('Nodes retained:    ${bench.retainedNodes}');
print('Nodes pruned:      ${bench.prunedNodes}');
print('Est. allocations:  ${bench.estimatedAllocationCount}');
```

> [!NOTE]
> BranchIQ benchmarks measure **structural execution counts**, not wall-clock time. This makes them reproducible and safe for regression testing.

---

## Full JSON Export

The entire debug snapshot can be serialized to JSON for logging, storage, or test assertions:

```dart
import 'dart:convert';

final snapshot = engine.exportDebugSnapshot(result);
const encoder = JsonEncoder.withIndent('  ');
print(encoder.convert(snapshot.toJson()));
```

---

## Diagnosing Failures

When `result.runtimeState == 'failed'`, the error is available in `result.errorMessage`:

```dart
if (result.runtimeState == 'failed') {
  print('Evaluation failed: ${result.errorMessage}');
}
```

Common failure causes:
- Tree exceeds depth limit (max 12 levels)
- Tree has more than 1000 nodes
- Cycle detected in the tree structure
- Invalid node references (missing parent or child IDs)

---

## Full Example

See [`example/debug_snapshot_example.dart`](../../example/debug_snapshot_example.dart):

```bash
dart run example/debug_snapshot_example.dart
```
