# Pruning Guide

Pruning removes low-value branches from the decision tree **before traversal begins**. This keeps evaluation fast and focused on meaningful paths.

---

## Why Prune?

In a large decision tree, many branches may be:
- Highly unlikely to occur (low `probability`)
- Net-negative in value (low or negative `score`)
- Too numerous to evaluate efficiently (wide fan-out)

Pruning eliminates these branches early, so the traversal engine only explores paths worth considering.

---

## Pruning Rules

All three rules are applied together during the pruning phase. A node is pruned if **any** rule applies.

### 1. Probability Pruning

Removes nodes whose `probability` is below a minimum threshold.

```dart
PruningConfig(
  minProbability: 0.05, // Prune any node with p < 5%
  ...
)
```

**Before pruning:**
```
root
├── safe     (p=0.9)  ✓ retained
├── risky    (p=0.03) ✗ pruned  (probabilityBelowThreshold)
└── moderate (p=0.7)  ✓ retained
```

**After pruning:**
```
root
├── safe     ✓
└── moderate ✓
```

---

### 2. Score Pruning

Removes nodes whose computed score is below a minimum threshold.

```dart
PruningConfig(
  minScore: 0.0, // Prune any node with score < 0.0
  ...
)
```

**Example:**
```
root
├── profitable  (score=0.65) ✓ retained
├── break_even  (score=0.01) ✓ retained
└── costly_loss (score=-0.2) ✗ pruned  (scoreBelowThreshold)
```

> [!TIP]
> Set `minScore: -1.0` to disable score pruning (all nodes pass). This is the default.

---

### 3. Beam Width Pruning

At each level in the tree, only the top-N scoring siblings are retained. The rest are removed.

```dart
PruningConfig(
  beamWidth: 3, // At each level, keep only the 3 highest-scoring siblings
  ...
)
```

**Example (beamWidth = 3):**
```
root
├── option_a (score=0.80) ✓ rank 1 — retained
├── option_b (score=0.65) ✓ rank 2 — retained
├── option_c (score=0.50) ✓ rank 3 — retained
├── option_d (score=0.40) ✗ rank 4 — pruned (beamWidthExceeded)
└── option_e (score=0.20) ✗ rank 5 — pruned (beamWidthExceeded)
```

Ties in score are broken **lexicographically by node ID** to remain deterministic.

---

## Fallback Behavior

If pruning eliminates **all** child branches of the root, the engine does not fail. It falls back to the root node itself as the selected path.

```
result.runtimeState == 'fallback'
result.bestPath.nodeIds == ['root']
result.wasFallback == true
```

This is intentional: it is always safer to return the root state than to crash or return null.

---

## PruningConfig Reference

```dart
PruningConfig(
  minProbability: 0.05,  // [0.0, 1.0]  — minimum allowed probability
  minScore:       -1.0,  // [-1.0, 1.0] — minimum allowed score
  beamWidth:      3,     // >= 1        — siblings retained per level
  maxDepth:       4,     // [1, 12]     — tree search depth limit
  maxNodeLimit:   100,   // [1, 1000]   — total nodes evaluated at most
)

// Or use the defaults:
PruningConfig.defaultSettings()
// minProbability: 0.0, minScore: -1.0, beamWidth: 3, maxDepth: 4, maxNodeLimit: 100
```

---

## Inspecting Pruning Decisions

Enable debug mode to see which nodes were pruned and why:

```dart
final result = engine.evaluateSync(..., enableDebug: true);
final snapshot = engine.exportDebugSnapshot(result);

for (final entry in snapshot.nodeSnapshots.entries) {
  final reason = entry.value['pruningReason'];
  if (reason != null) {
    print('Pruned: ${entry.key} — reason: $reason');
  }
}
```

Pruning reasons:
| Value | Meaning |
|---|---|
| `probabilityBelowThreshold` | Node `probability` was too low |
| `scoreBelowThreshold` | Node computed score was too low |
| `beamWidthExceeded` | Too many siblings; node was ranked out |
| `maxDepthExceeded` | Node was deeper than `maxDepth` |
| `maxNodeLimitExceeded` | The evaluation node budget was exhausted |

---

## Full Example

See [`example/pruning_example.dart`](../../example/pruning_example.dart):

```bash
dart run example/pruning_example.dart
```
