# BranchIQ Project Context

**Document Type:** Project Memory / Context Transfer  
**Purpose:** Preserve the full architectural, product, mathematical, implementation, and roadmap context of BranchIQ so future conversations or contributors can continue without losing decisions.  
**Status:** Living context document  
**Current Project Stage:** BranchIQ v0.1 published/ready + v0.2 fully implemented and stabilized  

---

# 1. What BranchIQ Is

BranchIQ is a **bounded deterministic runtime decision intelligence engine** for Dart and Flutter applications.

It is not positioned as an AI model, LLM, neural runtime, autonomous agent framework, or AGI system. It is a deterministic decision infrastructure package that allows applications to evaluate structured decision trees using explicit, inspectable, mathematical inputs.

The core idea is:

> A Flutter/Dart application should be able to score, prune, traverse, explain, replay, and compare runtime decisions deterministically without hidden magic.

BranchIQ exists to solve a common application architecture problem:

- decision logic scattered across services, repositories, view models, and UI layers;
- hardcoded nested `if/else` decision trees;
- difficult-to-reproduce runtime behavior;
- unclear why a specific path was chosen;
- lack of deterministic replay for debugging;
- poor explainability for client-side decisions.

BranchIQ centralizes runtime decision-making into a structured, bounded, deterministic engine.

---

# 2. Original Product Vision

The original long-term vision evolved from a decision-tree algorithm into a full **Cognitive Runtime Infrastructure Layer for Flutter/Dart**.

The initial concept was an **Exponential Decision Tree Engine** using:

- decision nodes;
- probability;
- impact;
- cost;
- confidence;
- scoring;
- pruning;
- best-path extraction;
- bounded runtime execution.

The deeper vision became:

> Build a runtime intelligence layer for Flutter applications that can reason deterministically, explain decisions, replay decisions, compare outcomes, and eventually support plugins, visualization, adaptive context, and local AI integrations without compromising deterministic core guarantees.

The product identity selected was:

# BranchIQ

The name was chosen because it clearly communicates:

- branching decisions;
- intelligence/decision quality;
- developer-friendly package branding;
- pub.dev suitability;
- future ecosystem expansion.

---

# 3. What BranchIQ Is Not

BranchIQ must not be marketed or architected as:

- AGI;
- consciousness;
- neural intelligence;
- an LLM replacement;
- an AI agent framework;
- an autonomous decision system;
- a black-box learning system;
- a Flutter widget package in the core library;
- a probabilistic storytelling engine.

BranchIQ is:

> deterministic, bounded, explainable, replayable decision infrastructure.

This distinction is critical for trust, pub.dev adoption, and long-term architectural stability.

---

# 4. Core Architectural Philosophy

BranchIQ is governed by several strict architectural principles.

## 4.1 Determinism First

Given identical input trees, node values, configuration, and context, BranchIQ must produce identical output.

This applies to:

- scoring;
- pruning;
- traversal;
- replay;
- explanation reports;
- markdown output;
- JSON output;
- snapshot diffing;
- regression tests.

Forbidden sources of nondeterminism include:

- random numbers;
- timestamps in decision logic;
- unordered map iteration;
- async races;
- hidden mutable global state;
- environment-dependent formatting;
- locale-sensitive number formatting.

## 4.2 Bounded Execution

The engine must never expand or traverse unbounded decision spaces.

The runtime must enforce limits such as:

- maximum tree depth;
- maximum node count;
- maximum traversal iterations;
- maximum children per node;
- beam width;
- pruning thresholds.

The goal is mobile-safe runtime decision evaluation.

## 4.3 Explainability Without Fabrication

BranchIQ explanations must only describe what actually happened.

They must never:

- infer business intent;
- hallucinate reasoning;
- generate AI-style explanations;
- speculate about why a user/app wanted a path;
- create unstated logic.

Allowed explanation style:

> Selected path utility exceeded rejected path utility by 0.4200.

Forbidden explanation style:

> The engine believed this was smarter.

## 4.4 Replay as Forensic Evidence

Replay must never rerun the engine.

Replay is snapshot-driven only.

This means replay must not:

- rescore nodes;
- rerun pruning;
- rerun traversal;
- call `BranchIQEngine.evaluateSync()`;
- depend on current engine version behavior.

Replay reconstructs the previous decision from saved evidence.

This is a major architectural decision because it prevents:

- scoring drift;
- floating-point divergence;
- future runtime behavior changing historical analysis;
- replay inconsistency.

## 4.5 Public API Minimalism

The public API must remain small, stable, and intentional.

Internal systems should not leak prematurely.

Examples of internal systems that should not be exported unless intentionally stabilized:

- math utilities;
- pruning internals;
- traversal internals;
- runtime pipeline internals;
- canonicalization utilities;
- internal guards;
- internal serializers.

Public APIs should expose developer-facing concepts only.

---

# 5. Mathematical Foundation

BranchIQ v0.1 is based on deterministic utility evaluation.

Each decision node conceptually contains:

```text
n = (P, I, C, K, M)
```

Where:

- `P` = probability;
- `I` = impact;
- `C` = cost;
- `K` = confidence;
- `M` = metadata/context.

## 5.1 Score Equation

The official core scoring equation is:

```text
S(n) = K(n) * [ wp * P(n) + wi * I(n) - wc * C_norm(n) ]
```

Where:

- `S(n)` is node score;
- `K(n)` is confidence;
- `wp` is probability weight;
- `wi` is impact weight;
- `wc` is cost weight;
- `C_norm(n)` is normalized cost.

Weights must satisfy:

```text
wp + wi + wc = 1
```

## 5.2 Cost Normalization

Cost is normalized linearly:

```text
C_norm(n) = min(1, C(n) / (C_max + ε))
```

Cost is bounded to avoid domination of score and prevent division instability.

## 5.3 Numeric Safety

BranchIQ must handle:

- NaN;
- infinity;
- negative zero;
- invalid probability values;
- invalid confidence values;
- invalid cost ceilings.

The engine uses deterministic sanitization and validation behavior.

## 5.4 Confidence

Confidence is bounded:

```text
K ∈ [0, 1]
```

Confidence supports deterministic decay with depth.

Confidence must not become adaptive learning in v0.1/v0.2.

## 5.5 Complexity

Naive tree expansion grows as:

```text
O(b^d)
```

Beam-bounded traversal reduces practical complexity to:

```text
O(d * k * b)
```

Where:

- `b` = branching factor;
- `d` = depth;
- `k` = beam width.

---

# 6. The Ten Long-Term Revolutionary Additions Originally Discussed

At the beginning, ten major future additions were considered. BranchIQ v0.1 implemented the core foundation that makes these possible, but not all of them.

## 6.1 Self-Learning Decision Memory

Goal:

- remember previous decisions;
- learn from outcomes;
- adjust future probabilities or weights.

Status:

- not implemented;
- deferred because it introduces adaptive behavior and threatens determinism;
- possible future phase after replay/explainability/plugin stability.

## 6.2 Adaptive UI Engine

Goal:

- use decision output to adapt Flutter UI flows;
- show/hide UI components;
- choose onboarding or navigation paths.

Status:

- not implemented;
- deferred because it introduces Flutter widget dependency and UI orchestration complexity;
- likely future separate package.

## 6.3 Multi-Agent Branching System

Goal:

- treat branches as agent-like evaluators;
- allow competing decision agents.

Status:

- not implemented;
- deferred as high complexity;
- should not enter core package early.

## 6.4 Bayesian Reality Updating

Goal:

- update probabilities based on real outcomes;
- support Bayesian probability updates.

Status:

- not implemented;
- mathematically discussed;
- deferred to avoid adaptive mutation in MVP.

## 6.5 Real-Time Context Awareness

Goal:

- use battery, connectivity, app state, latency, and context signals.

Status:

- partially prepared through `EvaluationContext`;
- not fully adaptive yet;
- likely v0.3/v0.4 candidate after plugin/context APIs.

## 6.6 Predictive UX Engine

Goal:

- predict next user action;
- preload or optimize flows.

Status:

- not implemented;
- deferred because it requires behavioral modeling and may become nondeterministic.

## 6.7 Async Parallel Tree Expansion

Goal:

- use isolates for larger trees;
- parallel branch evaluation.

Status:

- deliberately excluded from v0.1/v0.2;
- synchronous engine preserved for determinism and simplicity.

## 6.8 Visual Cognitive Debugger

Goal:

- visualize decision trees;
- show pruning, scores, selected paths.

Status:

- not implemented;
- raw debug snapshots, replay, explainability, and diffing are being built first;
- visual tooling should come later, possibly separate package.

## 6.9 Plugin-Based Decision Modules

Goal:

- extension modules for scoring, pruning, traversal, workflows.

Status:

- not implemented;
- architecture prepared;
- likely future v0.3 after explainability/replay/diffing is stable.

## 6.10 On-Device AI Hybrid Reasoning

Goal:

- combine deterministic engine with local AI/LLM reasoning.

Status:

- not implemented;
- explicitly deferred;
- must never compromise deterministic core.

---

# 7. Completion Percentage of Original Vision

Current estimated completion:

| Scope | Completion |
|---|---:|
| Core Engine | ~95–100% |
| v0.1 MVP | ~100% |
| v0.2 Replay, Explainability & Diffing | ~95–100% |
| Original Full Vision | ~80–85% |
| Ecosystem Vision | ~50–55% |
| Future Research Ideas | ~15–20% |

Important interpretation:

BranchIQ has not implemented every future idea. However, it has implemented the hard foundation that makes those future ideas possible.

The project is no longer a prototype. It is a functioning deterministic decision runtime with replay and explainability infrastructure underway.

---

# 8. Documentation and Planning Artifacts Created

The project produced a large set of architecture and planning documents.

## 8.1 Core Planning Documents

- `core_engine_spec.md`
- `mvp_boundary.md`
- `api_specification.md`
- `mathematical_model.md`
- `runtime_execution_model.md`
- `package_architecture.md`
- `implementation_plan.md`
- `testing_strategy.md`
- `developer_experience_strategy.md`

These established:

- architecture vision;
- MVP limits;
- API boundaries;
- mathematical source of truth;
- runtime lifecycle;
- package structure;
- implementation sequencing;
- testing philosophy;
- developer experience strategy.

## 8.2 Public Package Documents

- `README.md`
- `CHANGELOG.md`
- `CONTRIBUTING.md`
- `ROADMAP.md`
- `LICENSE`

## 8.3 Guides

Guides were moved from `docs/` to `doc/` for pub.dev conventions.

Existing guides include:

- `doc/guides/quickstart.md`
- `doc/guides/scoring_guide.md`
- `doc/guides/pruning_guide.md`
- `doc/guides/traversal_guide.md`
- `doc/guides/debugging_guide.md`
- `doc/guides/replay_guide.md`
- `doc/guides/explainability_guide.md`
- `doc/guides/snapshot_diff_guide.md`

## 8.4 RFCs

### RFC-0001 — Explainability & Replay Layer

Purpose:

- define v0.2 explainability and replay architecture;
- introduce `ExplanationReport`, `NodeExplanation`, `DecisionComparison`, `ReplaySession`, `ReplayLoader`, `ReplayInspector`, `SnapshotDiff`;
- enforce evidence-based explanations;
- forbid AI-generated reasoning.

### RFC-0002 — Snapshot Canonicalization & Deterministic Serialization

Purpose:

- define canonical serialization rules;
- stable key ordering;
- canonical floating-point formatting;
- deterministic markdown;
- snapshot identity/hashing concepts;
- replay-safe schema evolution;
- validation rules.

---

# 9. Repository and Release Status

BranchIQ repository was initialized on GitHub:

```text
https://github.com/abuelhassan208/BranchIQ
```

The package was prepared for pub.dev.

Important release steps completed:

- `dart format --output=none --set-exit-if-changed .`
- `dart analyze`
- `dart test`
- `dart doc`
- `dart pub publish --dry-run`

The dry run returned:

```text
Package has 0 warnings.
```

A `v0.1.0` git tag was created and pushed:

```bash
git tag v0.1.0
git push origin v0.1.0
```

Publishing reached OAuth authorization stage.

The package publishing itself was blocked only by Google OAuth authorization flow, not by package quality issues.

---

# 10. v0.1 Implementation Summary

BranchIQ v0.1 implemented the deterministic core runtime.

## 10.1 Repository Infrastructure

Implemented:

- `pubspec.yaml`
- `analysis_options.yaml`
- `.gitignore`
- GitHub Actions CI workflow
- public export boundary in `lib/branchiq.dart`
- package skeleton
- tests structure
- examples structure
- docs structure

## 10.2 Public Core APIs

Public API includes stable concepts such as:

- `BranchIQEngine`
- `DecisionNode`
- `DecisionTree`
- `EvaluationContext`
- `EvaluationResult`
- `BestPathResult`
- `DebugSnapshot`
- `ScoringConfig`
- `PruningConfig`
- `TraversalConfig`
- `TraversalStrategy`

Internal systems are intentionally hidden unless later stabilized.

## 10.3 Mathematical Core

Implemented internally under `lib/src/math/`:

- numeric safety;
- cost normalization;
- confidence propagation;
- score calculation;
- deterministic ordering.

Math utilities were deliberately kept internal and not exported from `branchiq.dart`.

## 10.4 Core Models

Hardened:

- `DecisionNode`
- `DecisionTree`
- `EvaluationContext`
- `EvaluationResult`
- config models;
- debug snapshots;
- tree validation.

Features:

- immutability;
- stable JSON;
- validation;
- cycle detection;
- orphan detection;
- deterministic serialization.

## 10.5 Pruning Core

Implemented internally:

- probability pruning;
- score pruning;
- beam-width pruning;
- pruning reasons;
- pruning pipeline;
- root preservation;
- fallback detection.

Pruning internals remain hidden from public API.

## 10.6 Traversal Core

Implemented internally:

- traversal result;
- path candidate;
- path backtracking;
- priority traverser;
- traversal pipeline.

Traversal rules:

- deterministic priority-first traversal;
- accumulated utility;
- score tie-breaking;
- lexicographic node ID ordering;
- pruned branch skipping;
- root fallback.

## 10.7 Runtime Orchestration

Implemented:

- `BranchIQEngine.evaluateSync()`;
- runtime pipeline;
- evaluation session;
- runtime state;
- trace generation;
- debug snapshots;
- explanation text via engine-level `explain()`;
- debug snapshot export.

Runtime is synchronous and deterministic.

## 10.8 Runtime Safety and Performance Hardening

Implemented:

- runtime limits;
- runtime guards;
- execution budget;
- allocation tracker;
- benchmark snapshot;
- benchmark runner.

Protected against:

- deep pathological trees;
- wide pathological trees;
- traversal overrun;
- excessive node counts;
- excessive child counts.

## 10.9 Examples and Guides

Implemented examples:

- `minimal_example.dart`
- `scoring_example.dart`
- `pruning_example.dart`
- `traversal_example.dart`
- `debug_snapshot_example.dart`
- `benchmark_example.dart`

Later examples added:

- `replay_example.dart`
- `explainability_example.dart`
- `snapshot_diff_example.dart`

## 10.10 Pub.dev Hardening

Completed:

- README final polish;
- CHANGELOG;
- CONTRIBUTING;
- doc folder convention;
- Dartdoc;
- publish dry-run;
- GitHub CI formatting issues resolved.

---

# 11. v0.2 Implementation Summary So Far

BranchIQ v0.2 focuses on:

> Explainability & Replay Layer

## 11.1 Phase A — Canonical Serialization Core

Implemented internally under `lib/src/canonicalization/`:

- `canonical_float_formatter.dart`
- `canonical_json_encoder.dart`
- `canonical_markdown_writer.dart`
- `canonicalization_validator.dart`
- `canonicalization_exceptions.dart`

Features:

- fixed 4-decimal float formatting;
- negative zero normalization;
- infinity representation;
- NaN rejection;
- lexicographic key ordering;
- null omission;
- compact canonical JSON;
- deterministic markdown primitives;
- canonical validation.

Public API changes:

- none.

Important decision:

Canonicalization utilities remain internal.

## 11.2 Phase B — Replay Core

Implemented under `lib/src/replay/` and exported publicly:

- `ReplayLoader`
- `ReplaySession`
- `ReplayInspector`
- `ReplayCorruptException`

Replay behavior:

- load `DebugSnapshot`;
- load JSON;
- load canonical JSON;
- reconstruct immutable replay session;
- inspect selected path;
- inspect pruned nodes;
- inspect runtime traces;
- inspect node snapshots;
- validate snapshot integrity;
- reject corrupt snapshots deterministically.

Replay must never run the engine.

## 11.3 Phase C — Explainability Core

Implemented under `lib/src/explainability/` and exported publicly:

- `BranchIQExplainer`
- `ExplanationReport`
- `NodeExplanation`
- `DecisionComparison`

Also implemented internally:

- explanation markdown exporter;
- explanation JSON exporter;
- explanation exceptions.

Explainability behavior:

- uses replay sessions;
- produces deterministic reports;
- exports canonical JSON;
- exports markdown;
- compares selected/rejected paths;
- explains only snapshot evidence.

It must not infer or hallucinate.

## 11.4 Phase D — Snapshot Diffing Core

Fully implemented, tested, and exported.

It implements:

- `SnapshotDiffer`
- `SnapshotDiff`
- `NodeMetricDiff`
- `TraceDiff`
- `SnapshotDiffException`
- `SnapshotDiffCorruptException`
- deterministic markdown diff export;
- deterministic JSON diff export.

---

# 12. Current Test Status Across Development

Test count increased over time as follows:

- after repository skeleton: 5 tests;
- after math core: 27 tests;
- after model hardening: 75 tests;
- after pruning: 94 tests;
- after traversal: 113 tests;
- after runtime orchestration: 134 tests;
- after runtime hardening: 174 tests;
- after canonical serialization: 202 tests;
- after replay core: 240 tests;
- after explainability core: 255 tests;
- after snapshot diffing core: 271 tests.

Current reported state:

```text
dart analyze: 0 issues
dart test: 271 tests passing
example/explainability_example.dart: runs successfully
example/snapshot_diff_example.dart: runs successfully
```

---

# 13. Current Public API State

## 13.1 v0.1 Public APIs

- `BranchIQEngine`
- `DecisionNode`
- `DecisionTree`
- `EvaluationContext`
- `EvaluationResult`
- `BestPathResult`
- `DebugSnapshot`
- `ScoringConfig`
- `PruningConfig`
- `TraversalConfig`
- `TraversalStrategy`

## 13.2 v0.2 Public APIs Added

Replay:

- `ReplayLoader`
- `ReplaySession`
- `ReplayInspector`
- `ReplayCorruptException`

Explainability:

- `BranchIQExplainer`
- `ExplanationReport`
- `NodeExplanation`
- `DecisionComparison`
- `ExplanationException`
- `ExplanationCorruptException`

Snapshot Diffing:

- `SnapshotDiffer`
- `SnapshotDiff`
- `NodeMetricDiff`
- `TraceDiff`
- `SnapshotDiffException`
- `SnapshotDiffCorruptException`

## 13.3 Planned Public APIs for Next Phase

Ecosystem Plugins (v0.3):

- `NodeEvaluator`
- `BranchExpander`

## 13.4 Must Remain Internal

- math utilities;
- pruning internals;
- traversal internals;
- runtime pipeline internals;
- canonicalization utilities;
- markdown writer internals;
- JSON encoder internals;
- explanation builders;
- diff builders;
- runtime guards;
- allocation tracker.

---

# 14. Current Phase and Next Exact Step

Current completed phase:

```text
v0.2 Phase D — Snapshot Diffing Core
```

Next planned phase:

```text
v0.2 Release Stabilization & v0.3 Planning
```

The next steps involve stabilizing APIs, dry-running releases, and drafting RFCs for v0.3 Plugin Systems.

---

# 15. Snapshot Diffing Scope

**Status:** Completed.

Snapshot diffing compares two previous runtime evaluations using snapshots/replay only.

It compares:

- selected paths;
- path changes;
- utility totals;
- node metric deltas;
- added nodes;
- removed nodes;
- modified nodes;
- newly pruned nodes;
- newly unpruned nodes;
- pruning reason changes;
- runtime trace changes;
- scoring summary changes;
- traversal summary changes.

It must not:

- rerun engine;
- rerun scoring;
- rerun pruning;
- rerun traversal;
- infer business meaning;
- claim causality beyond snapshot evidence;
- use AI reasoning;
- use async;
- use isolates.

---

# 16. Development Workflow Pattern Used in This Project

The project has followed a strict step-by-step workflow:

1. Write planning/RFC document.
2. Review architectural correctness.
3. Identify missing foundation pieces.
4. Write implementation prompt.
5. Implement one bounded subsystem only.
6. Run:
   - `dart format .`
   - `dart analyze`
   - `dart test`
   - relevant example script.
7. Report:
   - files changed;
   - implementation summary;
   - test results;
   - public API changes;
   - architecture deviations.
8. Only then move to the next phase.

This workflow should continue.

---

# 17. Important Architectural Corrections Made During Development

## 17.1 Math Utilities Remain Internal

Originally considered exporting math utilities, but this was rejected.

Reason:

- prevents public API pollution;
- avoids locking unstable internals;
- keeps scoring internals flexible.

## 17.2 Canonicalization Utilities Remain Internal

RFC-0002 initially suggested public export of `CanonicalSnapshotHasher` and `CanonicalizationValidator`.

This was corrected.

Reason:

- hashing contracts may evolve;
- schema evolution is still young;
- canonicalization is infrastructure, not user-facing API.

## 17.3 Replay Must Not Rerun Engine

This is one of the most important architectural decisions.

Replay reconstructs evidence only.

## 17.4 Explainability Must Not Invent Reasoning

Explanations must be evidence-based, not AI-style interpretation.

## 17.5 Flutter UI Must Remain Deferred

No Flutter widget system should enter the core package at this stage.

---

# 18. Pub.dev and GitHub Notes

Repository:

```text
https://github.com/abuelhassan208/BranchIQ
```

Package name:

```text
branchiq
```

v0.1 dry-run status:

```text
Package has 0 warnings.
```

A GitHub Actions formatting failure occurred because `example/scoring_example.dart` differed under CI formatting.

Resolution:

- manually wrapped long lines;
- ran strict format;
- committed:

```text
style: stabilize scoring example formatting
```

Important release links in `pubspec.yaml` should use the actual GitHub repository:

```yaml
repository: https://github.com/abuelhassan208/BranchIQ
homepage: https://github.com/abuelhassan208/BranchIQ
issue_tracker: https://github.com/abuelhassan208/BranchIQ/issues
documentation: https://github.com/abuelhassan208/BranchIQ/tree/main/doc
```

---

# 19. Future Roadmap After v0.2

Suggested future sequence:

```text
v0.2 Snapshot Diffing completion
v0.2 release hardening
v0.3 Plugin APIs
v0.4 Advanced traversal packs
v0.5 Flutter visual inspector / separate UI package
v0.6 Adaptive context runtime
v1.0 stable ecosystem release
```

## 19.1 v0.3 Plugin APIs

Likely goals:

- custom evaluators;
- custom branch expanders;
- custom report exporters;
- extension safety rules;
- plugin boundary validation.

## 19.2 v0.4 Advanced Traversal

Possible algorithms:

- BFS;
- DFS;
- A* variants;
- configurable traversal strategies;
- heuristic packs.

MCTS remains deferred due to nondeterministic/stochastic risk.

## 19.3 v0.5 Visual Inspector

Likely separate package to avoid core dependency bloat:

```text
branchiq_flutter_inspector
```

Features:

- tree visualization;
- selected path highlighting;
- pruning visualization;
- score heatmaps;
- replay timeline.

## 19.4 v0.6 Adaptive Context Runtime

Possible features:

- context adapters;
- environmental signal mapping;
- safe deterministic context transforms;
- no uncontrolled learning initially.

---

# 20. Assistant Continuation Instructions

When continuing this project in a new conversation, the assistant must preserve the following rules:

1. Do not jump ahead to implementation without confirming the current phase.
2. Keep public API minimal.
3. Keep all deterministic guarantees intact.
4. Do not introduce async, isolates, AI systems, adaptive learning, Flutter widgets, or plugins unless the phase explicitly requires them.
5. Distinguish clearly between:
   - planning documents;
   - RFCs;
   - implementation prompts;
   - release hardening.
6. Continue using step-by-step phase prompts.
7. After each result, analyze what was done and provide the next prompt only.
8. Never allow explanation systems to hallucinate reasoning.
9. Never allow replay systems to rerun engine logic.
10. Keep canonicalization internal unless a future RFC explicitly stabilizes it.

---

# 21. One-Sentence Project Summary

BranchIQ is a deterministic, bounded, replayable, explainable runtime decision engine for Dart and Flutter, evolving from a decision-tree scoring package into a forensic-grade decision diagnostics platform.

