# BranchIQ Development Roadmap

This roadmap outlines the development phases for the BranchIQ package. Our priority is to deliver a robust, deterministic decision engine with minimal memory allocations and first-class debugging diagnostics.

## Phase v0.1 - Deterministic Core Engine (Completed)
* [x] Initialize package structure, linting rules, and GitHub actions CI pipeline.
* [x] Implement immutable models: `DecisionNode`, `DecisionTree`, and configuration wrappers.
* [x] Implement mathematical primitives: cost normalizers, confidence depth decay, and utility scoring (MAUT).
* [x] Implement cycle validation guards and state engine boundaries.
* [x] Implement beam search pruners and priority-first A* pathfinders.

## Phase v0.2 - Replay & Explainability Layer (Completed)
* [x] Design canonical serialization core for stable JSON, custom float formatting, negative zero normalization, and NaN/infinity validation.
* [x] Implement evidence-driven, offline Replay Infrastructure to restore execution context without engine re-evaluation.
* [x] Implement literal, hallucination-free Explainability and Path Comparison.
* [x] Implement offline multi-version Snapshot Diffing and chronological Trace Comparison.

## Phase v0.3 - Plugin Infrastructure Core (Completed)
* [x] Expose public `NodeEvaluator` interfaces for dynamic node parameter calculations.
* [x] Design lightweight `PluginRegistry` with ASCII validation, duplicate checks, and deterministic executor ordering.
* [x] Implement engine-owned field protection (restores structural identity and confidence metrics automatically) during evaluator execution.
* [x] Design and implement plugin provenance recording inside `DebugSnapshot`.
* [x] Support offline, plugin-independent Replay and Explainability by loading plugin provenance evidence.

## Phase v0.3.1 - Release Preparation / Beta Readiness (Completed)
* [x] Clean up project context, documentation, and guides.
* [x] Verify pub package publication with `dart pub publish --dry-run`.
* [x] Finalize beta release version 0.3.0-beta.3.

## Phase v0.4 - Advanced Traversal & Expanders (Planned)
* [ ] Expose public `BranchExpander` interfaces to allow dynamic runtime tree expansion (deferred from v0.3).
* [ ] Implement BFS, DFS, and deterministic A* traversal configurations.
* [ ] Design custom report exporters (deferred from v0.3).
* [ ] Design dynamic context bindings to fetch telemetry environment states (context resolvers for latency, signal, battery, etc.).

## Future Advanced Tooling
* [ ] Build CLI JSON snapshot analyzers to validate tree structures.
* [ ] Implement visual execution inspectors for debugging complex trees.
* [ ] Introduce compile-time analyzer plugins to warn about cycle vulnerabilities before deployment.
