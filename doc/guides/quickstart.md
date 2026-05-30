# BranchIQ Quickstart Guide

Get your first deterministic decision evaluated in under 5 minutes.

---

## Installation

Add BranchIQ to your `pubspec.yaml`:

```yaml
dependencies:
  branchiq: ^0.3.0-beta.3
```

Then run:

```bash
dart pub get
```

---

## Your First Evaluation

BranchIQ evaluates a **decision tree** — a hierarchy of choices, each with a probability of occurring, an impact value, and a cost.

### Step 1: Build a Tree

A tree starts with a **root node** and branches into **child nodes**. Leaf nodes have no children.

```dart
import 'package:branchiq/branchiq.dart';

// Root: the starting decision point
final root = const DecisionNode.constant(
  id: 'root',
  parentId: null,
  childIds: ['accept', 'decline'],
  depth: 0,
);

// Branch A: accept the proposal
final accept = const DecisionNode.constant(
  id: 'accept',
  parentId: 'root',
  childIds: [],
  probability: 0.9,  // 90% likely to occur
  impact: 0.8,       // High positive impact
  cost: 50.0,        // Moderate cost
  depth: 1,
);

// Branch B: decline the proposal
final decline = const DecisionNode.constant(
  id: 'decline',
  parentId: 'root',
  childIds: [],
  probability: 0.1,  // 10% likely
  impact: -0.2,      // Slight negative impact
  cost: 10.0,        // Low cost
  depth: 1,
);

final tree = DecisionTree.fromNodes([root, accept, decline]);
```

> [!NOTE]
> Node IDs must be unique within a tree. The root node has `parentId: null`. All other nodes must reference an existing parent.

---

### Step 2: Configure the Engine

Three configuration objects control how BranchIQ evaluates the tree:

```dart
// ScoringConfig: weights that control how nodes are scored
final scoringConfig = ScoringConfig.balanced(costCeiling: 100.0);

// PruningConfig: filters out low-value branches before traversal
final pruningConfig = PruningConfig.defaultSettings();

// TraversalConfig: determines the pathfinding strategy
const traversalConfig = TraversalConfig();
```

For most use cases, the defaults are a good starting point. See the [Scoring Guide](scoring_guide.md) and [Pruning Guide](pruning_guide.md) for customization.

---

### Step 3: Evaluate

```dart
final engine = BranchIQEngine.createSync();

final result = engine.evaluateSync(
  tree: tree,
  scoringConfig: scoringConfig,
  pruningConfig: pruningConfig,
  traversalConfig: traversalConfig,
  enableDebug: true,
);
```

---

### Step 4: Read the Results

```dart
print('State:    ${result.runtimeState}');   // "completed", "fallback", or "failed"
print('Path:     ${result.bestPath.nodeIds.join(' -> ')}');
print('Utility:  ${result.totalUtility.toStringAsFixed(4)}');
```

Example output:

```
State:    completed
Path:     root -> accept
Utility:  0.6591
```

---

### Step 5: Read the Explanation

```dart
print(engine.explain(result));
```

Output:

```
Path chosen: root -> accept
Total Utility: 0.6591
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

## Complete Example

See [`example/minimal_example.dart`](../../example/minimal_example.dart) for the full runnable example.

```bash
dart run example/minimal_example.dart
```

---

## Next Steps

| Guide | What it explains |
|---|---|
| [Scoring Guide](scoring_guide.md) | How nodes are scored using weights, cost, and confidence |
| [Pruning Guide](pruning_guide.md) | How low-value branches are filtered out before traversal |
| [Traversal Guide](traversal_guide.md) | How the best path is selected deterministically |
| [Debugging Guide](debugging_guide.md) | How to inspect decisions using debug snapshots |
| [Replay Guide](replay_guide.md) | How to reconstruct and inspect past evaluations offline |
| [Explainability Guide](explainability_guide.md) | How to generate evidence-based explanation reports |
| [Snapshot Diff Guide](snapshot_diff_guide.md) | How to compare two evaluations deterministically |

---

## Runtime States

| State | Meaning |
|---|---|
| `completed` | A valid path was found |
| `fallback` | All branches were pruned; engine returned the root node as the safest choice |
| `failed` | Structural validation or a hard safety limit was violated |
