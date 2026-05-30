# Traversal Guide

After scoring and pruning, BranchIQ **traverses** the remaining tree to find the single best root-to-leaf path. This guide explains how path selection works and why it is always reproducible.

---

## What Traversal Does

Traversal answers one question: **which sequence of decisions leads to the best outcome?**

Given a scored and pruned tree, the traversal engine:
1. Starts at the root node
2. At each level, selects the highest-scoring child
3. Continues until it reaches a leaf (a node with no children)
4. Returns the full path as the selected decision sequence

---

## Tree Structure Recap

```
root (score=0.33)
├── strategy_a (score=0.51)
│   ├── a_deep (score=0.62)   ← Leaf: highest total utility path
│   └── a_wide (score=0.45)
└── strategy_b (score=0.44)
    ├── b_fast (score=0.40)
    └── b_thorough (score=0.55)
```

With quality-biased scoring, the traversal follows:

```
root → strategy_a → a_deep
```

Total utility = `score(root) + score(strategy_a) + score(a_deep)` = accumulated path score.

---

## Deterministic Path Selection

BranchIQ always produces the same path for the same tree and configuration. There is no randomness anywhere in the traversal process.

The selection process is deterministic because:
- **Scores are computed from fixed inputs** (probability, impact, cost, weights)
- **Sorting is stable** — when scores are equal, nodes are sorted lexicographically by ID
- **No external state** is read during traversal (no clocks, no random seeds)

---

## Accumulated Utility

The `totalUtility` reported in the result is the **sum of scores along the selected path**, including the root node.

```
totalUtility = score(root) + score(node_1) + score(node_2) + ...
```

This accumulated value reflects the total quality of the entire path, not just the terminal leaf.

> [!NOTE]
> `totalUtility` can exceed `1.0` because it accumulates individual node scores along a multi-hop path. A path of 3 high-scoring nodes may have a `totalUtility` around `1.5`–`2.0`.

---

## Tie-Breaking

If two sibling nodes have identical scores, BranchIQ resolves the tie by their **node IDs, sorted lexicographically in ascending order**.

```dart
// Both nodes have identical probability, impact, and cost:
final optionAlpha = DecisionNode(id: 'option_alpha', ...);
final optionZeta  = DecisionNode(id: 'option_zeta', ...);

// Result: "option_alpha" is always selected
// "option_alpha" < "option_zeta" lexicographically
```

This guarantee means:
- The same tree produces the same result every time
- You can predict which node wins a tie without running the engine

---

## Traversal Strategy

Currently, BranchIQ uses **Priority-First traversal** — a greedy, best-first search that always expands the highest-scoring frontier node.

```dart
const traversalConfig = TraversalConfig(
  strategy: TraversalStrategy.priorityFirst,
);
```

This is the only available strategy in v0.3.0. Additional strategies may be added in future releases.

---

## Terminal Nodes

A terminal node (leaf) is any node with an empty `childIds` list. The traversal always ends at a leaf.

```dart
final leaf = DecisionNode(
  id: 'my_leaf',
  parentId: 'parent',
  childIds: [], // <-- This makes it a terminal node
  depth: 2,
);
```

If the entire tree consists of only a root node with no children, the path is simply `['root']` and `totalUtility` equals the root's score.

---

## Traversal Budget

To protect against pathological inputs, traversal is bounded by:

| Limit | Default | Description |
|---|---|---|
| `maxDepth` | 12 levels | Maximum tree depth allowed |
| `maxNodeLimit` | 1000 nodes | Maximum tree size allowed |
| `beamWidth` | 3 siblings | Maximum siblings explored per level |

These limits are enforced before traversal begins (during validation) and prevent runaway graph exploration.

---

## Full Example

See [`example/traversal_example.dart`](../../example/traversal_example.dart):

```bash
dart run example/traversal_example.dart
```
