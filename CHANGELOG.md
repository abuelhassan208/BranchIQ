# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## 0.3.0-beta.3 (2026-05-30)

### Fixed

- Fixed a compilation-blocking bug in the README.md plugin example, replacing incorrect `.metadata['key']` call with the correct `.get<T>('key')` method.
- Updated outdated installation package version references across `README.md` and `doc/guides/quickstart.md` to point to `0.3.0-beta.3`.

### Changed

- Expanded public API documentation for the `plugins` parameter of `BranchIQEngine.evaluateSync` to clarify usage.
- Synchronized `ROADMAP.md` milestones to reflect completion of the `0.3.0-beta.2` release pipeline.

---

## 0.3.0-beta.2 (2026-05-30)

### Added

**CI/CD Release Pipeline**
- Configured a new GitHub Actions CI workflow (`ci.yml`) to validate formatting, static analysis, unit/regression tests, documentation building, and dry-run publishing on every push and pull request.
- Implemented dynamic example auto-discovery and validation inside CI to run all examples under `example/` automatically.
- Integrated automated pub.dev deployment via Trusted Publishing (OIDC) triggered exclusively on release tags (`v*`).
- Added tag-to-pubspec version safety validation to prevent publishing mismatched releases.
- Configured a manual deployment approval gate using the `pub-release` GitHub Environment to prevent accidental automated publishing on tag push.

---

## 0.3.0-beta.1 (2026-05-30)

### Added

**Plugin Infrastructure Core**
- Added public `NodeEvaluator` interface for custom synchronous scoring modification.
- Added public `PluginRegistry` for registering and ordering evaluators.
- Added internal `PluginRegistryValidator` validating evaluator IDs for uniqueness, non-emptiness, and ASCII-only stability.
- Added optional `PluginRegistry` parameter to `BranchIQEngine.evaluateSync()`.
- Implemented synchronous evaluator execution sequence in deterministic registry order during the scoring phase.
- Added automatic engine-owned field protection (`id`, `parentId`, `childIds`, `depth`, `confidence`) which are restored by the engine after evaluator execution.
- Added plugin provenance evidence collection written into `DebugSnapshot.pluginProvenance`.
- Supported offline, plugin-independent Replay and Explainability by loading plugin provenance evidence directly from serialized snapshots without executing plugin classes.

### Changed
- Updated Explainability Markdown/JSON reports to display recorded plugin provenance evidence.
- Ensured snapshot diffing remains stable and deterministic when processing snapshots with plugin provenance.

---

## 0.2.0 (2026-05-23)

### Added

**Replay Infrastructure**
- Fully reconstructed offline execution context from saved evidence without rerunning evaluation logic (`ReplayLoader`, `ReplaySession`, `ReplayInspector`).
- Replay inspector functions to examine selected paths, trace lines, pruned nodes, and individual node lookup.
- Deterministic schema integrity checks to prevent corrupt and malformed snapshot load failures (`ReplayCorruptException`).

**Explainability Layer**
- Bounded, literal, evidence-based explainability reporting without LLM hallucinations or heuristics (`BranchIQExplainer`, `ExplanationReport`, `NodeExplanation`).
- Interactive selected vs. rejected pathway comparison diagnostics with score delta, confidence delta, and pruning discrepancy checks (`DecisionComparison`).
- Deterministic, platform-invariant Markdown and JSON explainability report generation.

**Snapshot Diffing**
- Synchronous and offline comparisons between historical executions (`SnapshotDiffer`, `SnapshotDiff`).
- Comprehensive change metrics tracking newly added, modified, removed, pruned, and unpruned nodes, as well as utility deltas (`NodeMetricDiff`).
- Precise chronological trace diffing (`TraceDiff`).

**Canonical Serialization**
- Custom floating-point formatting to exactly 4 decimal places with strict dot separators, normalization of negative zero (`-0.0` to `0.0000`), infinity handling, and NaN rejection (`CanonicalFloatFormatter`).
- Compact, platform-independent, and byte-identical JSON and Markdown serialization encoders (`CanonicalJsonEncoder`, `CanonicalMarkdownWriter`, `CanonicalizationValidator`).

## 0.1.2 (2026-05-22)

### Added
- Added standard `example/example.dart` to satisfy pub.dev package example conventions, securing the missing 10 points.

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

- `TraversalStrategy` currently supports only `priorityFirst`. Additional strategies deferred to a future release.
- `BranchIQEngine` is synchronous only. Async evaluation is not in scope.
- Dynamic node expansion is not yet supported (tree structure is fixed at construction time).
