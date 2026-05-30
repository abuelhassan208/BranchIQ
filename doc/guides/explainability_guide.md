# BranchIQ Explainability Guide

This guide introduces **deterministic, evidence-based explainability** (Phase C) in BranchIQ. It demonstrates how to leverage structured diagnostic execution snapshots (`DebugSnapshot`) via a `ReplaySession` to reconstruct, query, and compare decision pathways offline.

---

## 💡 Explainability Philosophy & Core Guarantees

In modern decision intelligence systems, understanding *why* a particular path was chosen is as critical as the choice itself. However, many systems rely on probabilistic explanations, generative AI reasoning, or heuristic storytelling which can introduce hallucinations, inconsistencies, and platform discrepancies.

BranchIQ guarantees:
1.  **Purely Evidence-Based**: Explanations are derived exclusively from verified, static metrics (scores, contributions, pruning flags, search traces) computed during original engine evaluations.
2.  **Fully Offline & Non-Invasive**: Replay explainability never reruns search traversals, never performs dynamic node scoring, and does not alter snapshot state.
3.  **Strictly Deterministic**: Given a `ReplaySession`, the resulting `ExplanationReport` and `DecisionComparison` will yield 100% byte-identical markdown and JSON outputs on every platform, CPU architecture, and environment.

> [!WARNING]
> **BranchIQ does NOT generate AI reasoning.** It is not powered by large language models, adaptive networks, or speculative heuristics. All explanation summaries are hard deterministic evaluations of real mathematical criteria.

---

## 🚀 Quick Start: Generating an Explanation Report

The entire explainability cycle is synchronous, pure Dart, and has zero external dependencies.

```dart
import 'package:branchiq/branchiq.dart';

void main() {
  // 1. Load an existing ReplaySession (from JSON or a file snapshot)
  final session = ReplayLoader.loadCanonicalJson(snapshotJsonString);

  // 2. Compute the explanation report offline
  final report = BranchIQExplainer.explain(session);

  // 3. Inspect report metrics
  print('Root Node:        ${report.rootId}');
  print('Selected Path:    ${report.selectedPath.join(" → ")}');
  print('Selected Utility: ${report.selectedUtility.toStringAsFixed(4)}');

  // 4. Export to a deterministic, beautifully formatted markdown document
  final markdown = report.toMarkdown();
  print(markdown);
}
```

---

## 📊 Explanation Report Anatomy

An `ExplanationReport` contains several structured sections to guarantee absolute transparency of the decision tree evaluation:

### 1. Selected Path
The exact sequential path chosen by the traversal engine, from the root node to the final decision leaf node.

### 2. Utility Summary
Displays the root identifier, final cumulative decision path utility, and the snapshot schema version.

### 3. Traversal Analysis
Key settings and results of the traversal search strategy, sorted alphabetically.

### 4. Pruning Analysis
Lexicographically lists all node IDs that were pruned during evaluation, alongside specific pruning parameters.

### 5. Node Explanations
A comprehensive, aligned table detailing:
*   `Node ID`: Lexicographically sorted unique node identifiers.
*   `Score`: The normalized decision score of the node.
*   `Status`: Pruning outcome (`pruned` or `retained`).
*   `Selected`: Whether the node lies on the winning path.
*   `Terminal`: Leaf node indicator.
*   `Rank`: 1-based traversal ordering.
*   `Pruning Reason`: Log explanation if pruned.

### 6. Runtime Traces
Chronological traces documenting each pipeline step taken (validation, scoring, pruning, traversal, completion).

---

## 🆚 Decision Path Comparison

Callers can compare the chosen decision path against any alternative (rejected) path. This is useful for auditing, forensic logging, and validating edge-cases.

```dart
final comparison = BranchIQExplainer.comparePaths(
  session: session,
  selectedPath: ['root', 'approve', 'auto'],
  rejectedPath: ['root', 'defer'],
);

// Export comparative report as stable markdown
final comparisonMarkdown = comparison.toMarkdown();
print(comparisonMarkdown);
```

### Metrics Analyzed:
*   **Exact Utility Delta**: Selected utility vs. alternative utility.
*   **Path Length Delta**: Difference in traversed steps.
*   **Pruning Analysis**: Identifies exactly which nodes along the alternative path were pruned, including pruning reasons.

---

## ⚠️ Limitations & Scope Boundary

*   **Static Scope**: Explainability can only analyze properties and paths present in the provided `DebugSnapshot`. If a sub-branch was completely pruned out prior to scoring and traversal, its downstream child nodes will not have entries in the snapshot and cannot be analyzed.
*   **Immutable Operations**: All exports and collections are wrapped in unmodifiable representations. Any attempt to modify lists or maps will throw an `UnsupportedError`.
