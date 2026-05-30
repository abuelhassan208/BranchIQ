# roadmap.md

**Document Type:** Long-Term Development Roadmap
**Purpose:** Define the strategic evolution path of BranchIQ from deterministic runtime engine to full replayable decision diagnostics ecosystem.
**Status:** Living roadmap
**Current Active Version:** v0.2 development
**Current Active Phase:** v0.2 Release Stabilization & Pub Publish

---

# 1. Roadmap Philosophy

BranchIQ development follows a strict layered architecture roadmap.

The roadmap intentionally prioritizes:

1. deterministic foundations first;
2. replay correctness second;
3. explainability third;
4. ecosystem expansion later.

This order is critical because every future system depends on deterministic infrastructure stability.

---

# 2. Long-Term Product Direction

BranchIQ is evolving through several architectural maturity stages.

| Stage            | Identity                                 |
| ---------------- | ---------------------------------------- |
| Early Concept    | Decision tree algorithm                  |
| v0.1             | Deterministic runtime engine             |
| v0.2             | Replay & explainability infrastructure   |
| v0.3+            | Extensible diagnostics ecosystem         |
| Long-Term Vision | Deterministic cognitive runtime platform |

The project intentionally avoids becoming:

* an LLM wrapper;
* autonomous AI;
* black-box adaptive engine;
* uncontrolled learning system.

The core identity remains:

> deterministic, bounded, replayable, explainable decision infrastructure.

---

# 3. Completed Milestones

## v0.1 — Deterministic Runtime Engine

### Status

```text id="vhhm3l"
Completed
```

### Major Deliverables

Implemented:

* mathematical scoring engine;
* pruning system;
* traversal system;
* runtime orchestration;
* debug snapshots;
* benchmark infrastructure;
* deterministic runtime constraints;
* public package APIs;
* examples and guides;
* pub.dev release hardening.

### Important Outcomes

v0.1 established:

* deterministic runtime execution;
* stable runtime boundaries;
* immutable decision models;
* replay-ready snapshot structures.

---

# 4. v0.2 — Replay & Explainability Infrastructure

## Status

```text id="83mt3m"
In Progress
```

## Strategic Goal

Transform BranchIQ from:

```text id="o2f8m9"
runtime decision engine
```

into:

```text id="u8j8px"
deterministic replayable diagnostics platform
```

---

# 5. v0.2 Completed Phases

---

## Phase A — Canonical Serialization Core

### Status

```text id="6m3q4w"
Completed
```

### Implemented Systems

```text id="vvr7t4"
CanonicalFloatFormatter
CanonicalJsonEncoder
CanonicalMarkdownWriter
CanonicalizationValidator
```

### Purpose

Provides:

* byte-identical JSON;
* stable markdown;
* canonical float formatting;
* replay-safe serialization;
* deterministic regression infrastructure.

### Important Architectural Decision

Canonicalization utilities remain internal.

They are infrastructure, not public APIs.

---

## Phase B — Replay Core

### Status

```text id="d64m0t"
Completed
```

### Implemented Public APIs

```dart id="n6j3q4"
ReplayLoader
ReplaySession
ReplayInspector
ReplayCorruptException
```

### Purpose

Provides:

* snapshot reconstruction;
* offline replay;
* forensic inspection;
* deterministic replay validation.

### Most Important Architectural Rule

Replay must never rerun the engine.

Replay reconstructs evidence only.

---

## Phase C — Explainability Core

### Status

```text id="4a40je"
Completed
```

### Implemented Public APIs

```dart id="i2rw7u"
BranchIQExplainer
ExplanationReport
NodeExplanation
DecisionComparison
```

### Purpose

Provides:

* deterministic explanation reports;
* evidence-based diagnostics;
* markdown explanations;
* JSON explanations;
* path comparison reports.

### Most Important Architectural Rule

Explainability must never hallucinate reasoning.

All explanations must remain evidence-based.

---

# 6. v0.2 Current Active Phase

## Phase D — Snapshot Diffing Core

### Status

```text id="gtx9x4"
Completed
```

### Strategic Goal

Enable deterministic comparison between:

* two runtime evaluations;
* two replay sessions;
* two snapshots;
* two selected paths.

### Planned Public APIs

```dart id="4g7dc0"
SnapshotDiffer
SnapshotDiff
NodeMetricDiff
TraceDiff
```

### Planned Features

* selected path comparison;
* utility delta analysis;
* pruning delta analysis;
* trace delta analysis;
* node metric deltas;
* deterministic markdown diff reports;
* deterministic JSON diff reports.

### Important Constraints

Snapshot diffing:

* must not rerun engine execution;
* must not rerun traversal;
* must not infer causality;
* must remain deterministic.

---

# 7. Planned v0.2 Finalization

## v0.2 Release Stabilization & Pub Publish

### Status

```text id="qkgj9z"
In Progress
```

### Planned Tasks

* stabilize replay APIs;
* stabilize explainability APIs;
* stabilize diffing APIs;
* finalize documentation;
* finalize examples;
* increase regression coverage;
* validate cross-platform consistency;
* release benchmark verification;
* finalize CHANGELOG;
* create migration notes if needed.

### Release Goal

Deliver:

> stable deterministic replay & diagnostics release.

---

# 8. Planned v0.3 — Plugin Infrastructure

## Status

```text id="qq1vdz"
Research / Deferred
```

## Strategic Goal

Allow controlled extension of BranchIQ without compromising deterministic guarantees.

---

## Planned Systems

### Plugin Evaluators

Potential support for:

* custom scoring modules;
* custom utility calculators;
* domain-specific evaluators.

---

### Plugin Traversal Strategies

Potential support for:

* configurable traversal packs;
* bounded heuristic traversal;
* custom deterministic ordering.

---

### Plugin Exporters

Potential support for:

* custom report exporters;
* custom markdown styles;
* external integrations.

---

## Important Constraints

Plugin systems must:

* remain deterministic;
* remain bounded;
* preserve replay safety;
* preserve canonical serialization;
* preserve regression reproducibility.

---

# 9. Planned v0.4 — Advanced Traversal Packs

## Status

```text id="2pc8ta"
Research / Deferred
```

## Strategic Goal

Expand traversal capabilities while preserving deterministic guarantees.

---

## Candidate Algorithms

Potential future traversal support:

* BFS;
* DFS;
* deterministic A*;
* bounded heuristic traversal;
* configurable frontier strategies.

---

## Explicitly Deferred

The following remain deferred:

* stochastic traversal;
* nondeterministic heuristics;
* probabilistic Monte Carlo systems;
* unrestricted MCTS.

---

# 10. Planned v0.5 — Visual Diagnostics Ecosystem

## Status

```text id="1jz1k0"
Deferred
```

## Strategic Goal

Provide visual tooling around replay, explainability, and diffing.

---

## Important Architectural Decision

Visual systems should likely exist in a separate package:

```text id="hv1evi"
branchiq_flutter_inspector
```

This avoids:

* Flutter dependency pollution in core package;
* rendering concerns inside deterministic engine;
* unnecessary runtime bloat.

---

## Potential Features

Possible future visual systems:

* tree visualization;
* selected path highlighting;
* pruning visualization;
* replay timeline;
* node score heatmaps;
* traversal animation;
* diff visualization.

---

# 11. Planned v0.6 — Context-Aware Runtime

## Status

```text id="s5n1gx"
Research / Deferred
```

## Strategic Goal

Allow controlled environment-aware runtime decisions.

---

## Potential Features

Possible future context systems:

* battery-awareness;
* network-awareness;
* device-performance-awareness;
* app-state-aware evaluation;
* environmental weighting adapters.

---

## Important Constraints

Adaptive context must:

* remain bounded;
* remain replayable;
* remain serializable;
* remain deterministic where possible.

---

# 12. Deferred High-Risk Systems

The following systems were discussed early but intentionally deferred.

---

## Self-Learning Runtime

### Status

```text id="zw0p6q"
Deferred
```

### Reason

Threatens:

* determinism;
* replay stability;
* reproducibility.

---

## AI / LLM Integration

### Status

```text id="5onhvh"
Deferred
```

### Reason

Would require:

* separate architecture;
* separate guarantees;
* strong isolation from deterministic core.

---

## Autonomous Agents

### Status

```text id="e4hvv3"
Deferred
```

### Reason

Outside current project scope.

---

## Async Runtime Engine

### Status

```text id="5klkg0"
Deferred
```

### Reason

Would introduce:

* synchronization complexity;
* replay instability risks;
* concurrency nondeterminism.

---

## Distributed Runtime

### Status

```text id="3lmz7v"
Deferred
```

### Reason

Not aligned with current mobile/runtime focus.

---

# 13. Potential v1.0 Vision

## Long-Term Stable Identity

Potential v1.0 positioning:

> Deterministic runtime decision infrastructure for Dart and Flutter.

---

## v1.0 Requirements

Potential v1.0 readiness criteria:

* stable replay APIs;
* stable explainability APIs;
* stable diffing APIs;
* mature regression infrastructure;
* mature documentation ecosystem;
* stable serialization contracts;
* strong pub.dev adoption;
* plugin boundary stabilization.

---

# 14. Current Priority Order

The current recommended implementation order is:

```text id="wr1yx8"
1. v0.2 Release Stabilization & Pub Publish
2. Plugin Infrastructure RFCs (v0.3)
3. Advanced Traversal RFCs (v0.4)
4. Visual Diagnostics Ecosystem (v0.5)
5. Context Runtime Research (v0.6)
```

---

# 15. Current Architectural Priorities

The project currently prioritizes:

| Priority                   | Importance |
| -------------------------- | ---------- |
| Determinism                | Critical   |
| Replay Safety              | Critical   |
| Canonical Serialization    | Critical   |
| Explainability Integrity   | Critical   |
| Public API Stability       | Critical   |
| Bounded Runtime            | Critical   |
| Cross-Platform Consistency | High       |
| Visual Tooling             | Medium     |
| Plugin Ecosystem           | Medium     |
| Adaptive Runtime           | Low        |
| AI Integration             | Very Low   |

---

# 16. Current Non-Negotiable Rules

The following rules must continue across future phases.

## Replay Rule

Replay never reruns engine logic.

---

## Explainability Rule

Explainability never invents reasoning.

---

## Serialization Rule

Equivalent runtime states must produce byte-identical serialized outputs.

---

## API Rule

Internal infrastructure must not leak prematurely into public API.

---

## Runtime Rule

Core runtime remains synchronous and bounded unless a future RFC explicitly changes this.

---

# 17. Current Success Metrics

The project currently measures success through:

* deterministic reproducibility;
* replay correctness;
* stable regression outputs;
* stable canonical serialization;
* pub.dev readiness;
* architectural consistency;
* low public API entropy;
* forensic-grade diagnostics quality.

---

# 18. Long-Term Ecosystem Direction

The ecosystem may eventually include:

```text id="r7m93x"
branchiq
branchiq_flutter_inspector
branchiq_devtools
branchiq_plugins
branchiq_exporters
branchiq_visualizer
```

However:

* only the core package currently exists;
* ecosystem expansion is intentionally delayed until replay/explainability infrastructure stabilizes.

---

# 19. Immediate Next Milestone

The immediate next milestone is:

```text id="6u5fgz"
Complete v0.2 Release Stabilization & Pub Publish
```

while preserving:

* replay guarantees;
* canonical serialization guarantees;
* deterministic explainability guarantees;
* stable regression behavior.

---

# 20. Final Roadmap Principle

BranchIQ evolves in layers.

The project intentionally builds:

```text id="vjlwm4"
deterministic runtime
→ replay infrastructure
→ explainability
→ diffing
→ ecosystem expansion
```

rather than attempting advanced adaptive systems before the deterministic foundations are fully stable.
