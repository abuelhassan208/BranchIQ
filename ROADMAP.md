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

## Phase v0.3 - Adaptive Context Systems & Plugins (Planned)
* [ ] Design dynamic context bindings to fetch telemetry environment states.
* [ ] Introduce custom context resolvers for network latency, cellular signal strength, and device battery metrics.
* [ ] Expose public `NodeEvaluator` interfaces for dynamic node parameter calculations.
* [ ] Expose public `BranchExpander` interfaces to allow dynamic runtime tree expansion.

## Future Advanced Tooling
* [ ] Build CLI JSON snapshot analyzers to validate tree structures.
* [ ] Implement visual execution inspectors for debugging complex trees.
* [ ] Introduce compile-time analyzer plugins to warn about cycle vulnerabilities before deployment.
