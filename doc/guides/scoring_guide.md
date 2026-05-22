# Scoring Guide

This guide explains how BranchIQ scores each node in your decision tree and how to tune that scoring to match your priorities.

---

## The Scoring Formula

Each node is assigned a **score** based on three metrics:

| Metric | Field | Range | Meaning |
|---|---|---|---|
| Probability | `probability` | `[0.0, 1.0]` | How likely this outcome is to occur |
| Impact | `impact` | `[-1.0, 1.0]` | How much value this path generates (negative = harm) |
| Cost | `cost` | `>= 0.0` | Resource or effort required (normalized against `costCeiling`) |

The score formula is:

```
score = (wp × probability) + (wi × impact) - (wc × normalizedCost)
```

Where:
- `wp` = probability weight
- `wi` = impact weight
- `wc` = cost penalty weight
- `normalizedCost` = `cost / costCeiling` (clamped to `[0.0, 1.0]`)

> [!IMPORTANT]
> The weights `wp`, `wi`, and `wc` must sum exactly to `1.0`. This ensures score values remain on a predictable `[-1.0, 1.0]` scale.

---

## Configuring ScoringConfig

```dart
// Balanced: equal weight on all three metrics
final balanced = ScoringConfig.balanced(costCeiling: 1000.0);

// Custom: prioritize impact, penalize cost heavily
final qualityFirst = ScoringConfig(
  wp: 0.2,           // 20% probability weight
  wi: 0.7,           // 70% impact weight
  wc: 0.1,           // 10% cost penalty
  costCeiling: 500.0,
);

// Custom: minimize cost above all else
final budgetFirst = ScoringConfig(
  wp: 0.2,
  wi: 0.1,
  wc: 0.7,           // 70% cost penalty
  costCeiling: 500.0,
);
```

---

## Cost Normalization

Raw costs are divided by `costCeiling` before being applied to the formula. This keeps costs on the same `[0.0, 1.0]` scale as the other metrics.

```
normalizedCost = cost / costCeiling
```

**Example:**
- `cost = 80.0`, `costCeiling = 100.0`
- `normalizedCost = 0.80`

If your costs are measured in hundreds or thousands (e.g. dollars, milliseconds), set `costCeiling` to a realistic upper bound:

```dart
ScoringConfig.balanced(costCeiling: 10000.0) // costs measured up to $10,000
```

> [!TIP]
> If all your nodes have the same cost, set `wc = 0.0` and redistribute the weight between `wp` and `wi`. Weights must still sum to 1.0.

---

## Confidence & Depth Decay

Confidence measures how reliable the scoring information is at a given depth. It **decays** automatically as nodes get deeper in the tree — deeper outcomes are less certain.

This means:
- Root: `confidence = 1.0` (full certainty)
- Depth 1: confidence decays slightly
- Depth 2: confidence decays further

Confidence directly reduces the final score of deep nodes, preventing the engine from over-committing to far-future outcomes that are inherently less predictable.

You can observe this in action:

```dart
final snapshot = engine.exportDebugSnapshot(result);

final depth1Node = snapshot.nodeSnapshots['my_node']!;
print('Confidence at depth 1: ${depth1Node['confidence']}'); // e.g. 0.8144
```

---

## Score Examples

Given `ScoringConfig.balanced()` with `costCeiling = 100.0`:

| Node | probability | impact | cost | normalizedCost | Score |
|---|---|---|---|---|---|
| accept | 0.9 | 0.8 | 50.0 | 0.50 | `(0.33×0.9) + (0.33×0.8) - (0.33×0.5)` ≈ 0.66 |
| decline | 0.1 | -0.2 | 10.0 | 0.10 | `(0.33×0.1) + (0.33×-0.2) - (0.33×0.1)` ≈ -0.07 |

> [!NOTE]
> Negative scores are valid and indicate an outcome that creates more cost or harm than value. The engine filters these with `PruningConfig.minScore`.

---

## Practical Weight Recommendations

| Use Case | `wp` | `wi` | `wc` |
|---|---|---|---|
| Maximize value regardless of cost | 0.1 | 0.8 | 0.1 |
| Stay within budget | 0.2 | 0.1 | 0.7 |
| Balanced evaluation | 0.33 | 0.33 | 0.33 |
| Prefer reliable/safe outcomes | 0.7 | 0.2 | 0.1 |

---

## Full Example

See [`example/scoring_example.dart`](../../example/scoring_example.dart):

```bash
dart run example/scoring_example.dart
```
