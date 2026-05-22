# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## 0.1.1 (2026-05-22)

### Fixed
- Fixed formatting issue in `scoring_example.dart` that caused CI checks to fail.
- Shortened pubspec description to meet the pub.dev 60-180 character standard for SEO optimization.
- Removed redundant and pre-generation `documentation` URL field from `pubspec.yaml` to ensure pub.dev auto-generates documentation links correctly.

## 0.1.0 (2026-05-22)

Initial release of BranchIQ — a bounded, deterministic runtime decision intelligence engine for Dart and Flutter.

### Added

**Core Engine**
- `BranchIQEngine` — synchronous public evaluation interface with `evaluateSync()`, `explain()`, and `exportDebugSnapshot()`.
- `RuntimePipeline` — internal four-phase evaluation pipeline: validation, scoring, pruning, traversal.

**Data Models**
- `DecisionNode` — immutable node model with `probability`, `impact`, `cost`, `confidence`, and `score` fields.
- `DecisionTree` — immutable tree container with structural validation on construction.
- `EvaluationContext` — read-only telemetry context for passing runtime variables into evaluation.
- `EvaluationResult` — immutable result containing selected path, total utility, runtime state, and optional diagnostics.
- `BestPathResult` — ordered sequence of selected decision nodes.

**Configuration**
- `ScoringConfig` — weight configuration for probability (`wp`), impact (`wi`), and cost (`wc`). Weights must sum to `1.0`.
- `PruningConfig` — pruning thresholds including `minProbability`, `minScore`, `beamWidth`, `maxDepth`, and `maxNodeLimit`.
- `TraversalConfig` — traversal strategy selector (currently `priorityFirst`).

**Scoring System**
- Multi-attribute utility scoring using the formula: `score = (wp × p) + (wi × i) − (wc × normalizedCost)`.
- Depth-based confidence propagation: confidence decays automatically as nodes get deeper.
- Deterministic cost normalization against a configurable `costCeiling`.

**Pruning System**
- `probabilityBelowThreshold` — removes nodes with `probability < minProbability`.
- `scoreBelowThreshold` — removes nodes with computed score below `minScore`.
- `beamWidthExceeded` — retains only the top-N scoring siblings per level.
- Graceful fallback to root when all branches are pruned.

**Traversal System**
- Priority-first traversal: always selects the highest-scoring frontier node.
- Accumulated utility: reports the total sum of scores along the selected root-to-leaf path.
- Deterministic tie-breaking: equal-scoring nodes resolved by lexicographic node ID order.

**Safety & Hardening**
- Hard limits: max tree depth 12, max nodes 1000, max traversal iterations 1000, max children per node 10.
- Cycle detection via iterative DFS (no recursion).
- Orphan node detection and structural consistency validation.

**Diagnostics**
- `DebugSnapshot` — full JSON-serializable execution state including per-node scores, confidence, pruning reasons, and runtime traces.
- `BenchmarkSnapshot` — deterministic execution metrics (iteration counts, step counts, allocation estimates) with no wall-clock dependency.
- `engine.explain()` — human-readable trace of path selection reasoning.

**Examples**
- `example/minimal_example.dart` — minimal working evaluation.
- `example/scoring_example.dart` — weight sensitivity and confidence decay.
- `example/pruning_example.dart` — pruning rules and fallback.
- `example/traversal_example.dart` — path selection and tie-breaking.
- `example/debug_snapshot_example.dart` — debug snapshot inspection and JSON export.
- `example/benchmark_example.dart` — benchmark mode and deterministic replay.

**Documentation**
- `doc/guides/quickstart.md`
- `doc/guides/scoring_guide.md`
- `doc/guides/pruning_guide.md`
- `doc/guides/traversal_guide.md`
- `doc/guides/debugging_guide.md`

**Testing**
- 174 unit, integration, and regression tests passing.
- Stress regression tests validating 250+ consecutive identical evaluations.
- Model serialization regression tests (100+ repeated JSON roundtrips).

### Breaking Changes

None — this is the initial public release.

### Known Limitations

- `TraversalStrategy` currently supports only `priorityFirst`. Additional strategies planned for v0.2.0.
- `BranchIQEngine` is synchronous only. Async evaluation is not in scope for v0.1.0.
- Dynamic node expansion is not yet supported (tree structure is fixed at construction time).
