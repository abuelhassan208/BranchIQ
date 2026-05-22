# BranchIQ

> Deterministic runtime decision intelligence for Dart & Flutter.

BranchIQ evaluates decision trees synchronously, deterministically, and without hidden runtime magic. Given the same tree and configuration, it always produces the same result — guaranteed.

It is a pure Dart library with zero external dependencies. It runs on the calling thread with strict depth and size limits to prevent runaway execution.

---

## Key Features

- **Deterministic**: Identical inputs always produce identical outputs
- **Bounded**: Hard limits on tree depth, node count, and traversal iterations
- **Explainable**: Human-readable traces and structured JSON snapshots
- **Synchronous**: Runs on the calling thread — no isolates, no async, no event-loop delays
- **Pure Dart**: No Flutter dependency, no external packages, no hidden globals
- **Testable & Replayable**: Snapshots can be serialized and replayed in unit tests

---

## Installation

```yaml
dependencies:
  branchiq: ^0.1.0
```

```bash
dart pub get
```

Compatible with Dart SDK `>=3.0.0 <4.0.0`. Works on Flutter (iOS, Android, Web, macOS, Windows, Linux) and standalone Dart.

---

## Quickstart

```dart
import 'package:branchiq/branchiq.dart';

void main() {
  // 1. Define decision nodes
  final root = const DecisionNode.constant(
    id: 'root',
    parentId: null,
    childIds: ['accept', 'decline'],
    depth: 0,
  );

  final accept = const DecisionNode.constant(
    id: 'accept',
    parentId: 'root',
    childIds: [],
    probability: 0.9,   // How likely this outcome is
    impact: 0.8,         // How much value it creates ([-1.0, 1.0])
    cost: 50.0,          // How much it costs (non-negative)
    depth: 1,
  );

  final decline = const DecisionNode.constant(
    id: 'decline',
    parentId: 'root',
    childIds: [],
    probability: 0.1,
    impact: -0.2,
    cost: 10.0,
    depth: 1,
  );

  // 2. Build the tree
  final tree = DecisionTree.fromNodes([root, accept, decline]);

  // 3. Configure evaluation
  final engine = BranchIQEngine.createSync();

  final result = engine.evaluateSync(
    tree: tree,
    scoringConfig: ScoringConfig.balanced(costCeiling: 100.0),
    pruningConfig: PruningConfig.defaultSettings(),
    traversalConfig: const TraversalConfig(),
    enableDebug: true,
  );

  // 4. Read results
  print('State:    ${result.runtimeState}');     // completed
  print('Path:     ${result.bestPath.nodeIds}'); // [root, accept]
  print('Utility:  ${result.totalUtility}');

  // 5. Get a plain-English explanation
  print(engine.explain(result));
}
```

**Output:**

```
State:    completed
Path:     [root, accept]
Utility:  0.6591

Path chosen: root -> accept
Total Utility: 0.659...
State: completed
Traces:
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

---

## How It Works

BranchIQ processes every tree through a fixed, sequential pipeline:

```
Input Tree
    │
    ▼
[ 1. Validation ]  — checks structure, cycles, depth limits
    │
    ▼
[ 2. Scoring ]     — assigns utility scores using probability, impact, and cost
    │
    ▼
[ 3. Pruning ]     — eliminates low-value branches before traversal
    │
    ▼
[ 4. Traversal ]   — selects the highest-utility root-to-leaf path
    │
    ▼
  Result + Traces
```

### Scoring

Each node's score is computed as:

```
score = (wp × probability) + (wi × impact) - (wc × normalizedCost)
```

Weights `wp`, `wi`, `wc` must sum to `1.0`. Costs are normalized against `costCeiling`.

```dart
ScoringConfig(wp: 0.2, wi: 0.7, wc: 0.1, costCeiling: 500.0)
// 20% probability, 70% impact, 10% cost penalty
```

### Pruning

Branches are removed if they fall below any configured threshold:

```dart
PruningConfig(
  minProbability: 0.05,  // Remove branches with p < 5%
  minScore: 0.0,         // Remove branches with score < 0
  beamWidth: 3,          // Keep only top 3 siblings per level
  maxDepth: 4,
  maxNodeLimit: 100,
)
```

### Traversal

Priority-first traversal walks from root to the highest-scoring leaf. Ties are broken by lexicographic node ID order — always reproducible.

---

## Deterministic Guarantees

BranchIQ is designed to be a pure function of its inputs:

| Guarantee | How it's enforced |
|---|---|
| No randomness | No calls to `dart:math.Random` anywhere in the codebase |
| Stable tie-breaking | Equal-scoring nodes sorted by ID (`'a' < 'b'`) |
| No system clock | No `DateTime.now()` or `Stopwatch` inside evaluation |
| Stateless engine | `BranchIQEngine` holds no mutable state between calls |
| Bounded execution | Hard caps on depth (12), nodes (1000), and iterations (1000) |

Running the same evaluation 1000 times always produces identical results. This is verified by the regression test suite.

---

## Debugging & Inspection

Enable debug mode for full runtime diagnostics:

```dart
final result = engine.evaluateSync(..., enableDebug: true);

// Per-node scoring details
final snapshot = engine.exportDebugSnapshot(result);

for (final entry in snapshot.nodeSnapshots.entries) {
  final data = entry.value;
  print('${entry.key}: score=${data['score']}  pruned=${data['pruningReason']}');
}
```

Export the full snapshot to JSON:

```dart
import 'dart:convert';

final json = engine.exportDebugSnapshot(result).toJson();
print(const JsonEncoder.withIndent('  ').convert(json));
```

---

## Benchmark Mode

Collect execution metrics without wall-clock timing:

```dart
final result = engine.evaluateSync(..., enableBenchmark: true);

final bench = result.benchmarkSnapshot!;
print('Nodes evaluated:  ${bench.totalNodes}');
print('Traversal steps:  ${bench.traversalIterations}');
print('Nodes pruned:     ${bench.prunedNodes}');
print('Est. allocations: ${bench.estimatedAllocationCount}');
```

Benchmark snapshots are deterministic — the same tree always produces the same counts.

---

## Runtime States

| State | Meaning |
|---|---|
| `completed` | A valid path was found |
| `fallback` | All branches were pruned; root was returned as the safe default |
| `failed` | A structural or safety limit violation occurred |

When `failed`, inspect the error:

```dart
if (result.runtimeState == 'failed') {
  print('Error: ${result.errorMessage}');
}
```

---

## Safety Limits

BranchIQ enforces hard limits to protect your application:

| Limit | Default | Meaning |
|---|---|---|
| Max tree depth | 12 levels | Prevents deep recursion |
| Max node count | 1000 nodes | Prevents runaway memory use |
| Max traversal iterations | 1000 | Prevents infinite loops |
| Max children per node | 10 | Bounds local fan-out |

Trees violating these limits are rejected at construction time with a clear error.

---

## Examples

All examples are runnable:

```bash
dart run example/minimal_example.dart        # Basic evaluation
dart run example/scoring_example.dart         # Scoring weights & sensitivity
dart run example/pruning_example.dart         # Pruning rules & fallback
dart run example/traversal_example.dart       # Path selection & tie-breaking
dart run example/debug_snapshot_example.dart  # Debug snapshot inspection
dart run example/benchmark_example.dart       # Benchmark mode & determinism
```

---

## Documentation

| Guide | Topic |
|---|---|
| [Quickstart](doc/guides/quickstart.md) | Installation, first evaluation, reading results |
| [Scoring Guide](doc/guides/scoring_guide.md) | Weights, cost normalization, confidence decay |
| [Pruning Guide](doc/guides/pruning_guide.md) | Probability, score, beam width, fallback |
| [Traversal Guide](doc/guides/traversal_guide.md) | Path selection, tie-breaking, accumulated utility |
| [Debugging Guide](doc/guides/debugging_guide.md) | Traces, debug snapshots, benchmark metrics |

Core architecture documents are in [`doc/core/`](doc/core/).

---

## Use Cases

- **Cache vs. network selection**: Route requests based on signal quality, data age, and battery constraints
- **Adaptive retry policies**: Schedule retries based on backoff intervals and network telemetry
- **Offline-first decision flows**: Determine whether to serve cached or fresh content
- **Deterministic UI routing**: Direct onboarding or feature-flag flows based on user profile scores
- **Bounded workflow orchestration**: Find the next step in multi-stage workflows without hardcoded if-else trees

*BranchIQ is a deterministic routing and scoring engine. It is not a machine learning system, an autonomous agent, or an AI framework.*

---

## Architecture Principles

- **Deterministic** — same inputs, same outputs, always
- **Bounded** — execution is capped by depth and node limits
- **Explainable** — every decision produces inspectable traces
- **Synchronous** — runs on the calling thread; no async, no isolates
- **Pure Dart** — no external dependencies, no Flutter requirement
- **Testable** — stateless engine, replayable snapshots, full test suite

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

Key rules:
- All changes must maintain strict determinism
- No randomness, no system clock access, no isolates
- All mathematical and scoring code requires 100% unit test coverage

---

## Stability

BranchIQ v0.1.0 is a developer preview. The core evaluation pipeline is stable. Public API signatures may evolve before v1.0.

---

## License

MIT License — see [LICENSE](LICENSE).

---

*BranchIQ exists to make runtime decision systems deterministic, explainable, and bounded — without hidden magic.*
