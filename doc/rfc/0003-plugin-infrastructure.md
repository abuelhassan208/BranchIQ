# RFC-0003: Deterministic Plugin Infrastructure (Revised)

* **RFC Number**: RFC-0003
* **Title**: Deterministic Plugin Infrastructure
* **Status**: Proposed
* **Author**: `<Principal Systems Architect>`
* **Target Version**: v0.3
* **Created Date**: `2026-05-30`

---

## 1. Problem Statement

The BranchIQ core evaluation pipeline (Validation → Scoring → Pruning → Traversal) is statically compiled and closed to runtime interceptors. To support dynamic enterprise environments, we need a mechanism to resolve node metrics (such as probability, impact, and cost) on the fly based on contextual parameters (e.g., cell network latency, client telemetry, device variables). 

This RFC proposes a deterministic extension model for **Node Evaluators** to dynamically adjust node scoring parameters prior to evaluation, while preserving absolute determinism, replay-safety, evidence-based explainability, and canonical serialization stability.

---

## 2. Goals

1. **Focused Scoring Extensibility**: Provide clean, abstract interfaces for injecting custom node scoring resolution algorithms (Node Evaluators) in v0.3.
2. **Strict Determinism Preservation**: Ensure that all evaluator plugins behave as pure, platform-independent functions. Given identical context and tree inputs, they must yield byte-identical score adjustments.
3. **Replay Isolation**: Maintain complete isolation of the replay layer. Replaying a snapshot must never execute plugins; evaluations must be reconstructed purely from evidence recorded in the snapshot.
4. **Canonical Serialization Stability**: Define how custom evaluation variables and modifications enter snapshots without breaking sorting and precision requirements.
5. **No Overhead for Core**: Guarantee that configurations not using plugins experience no plugin execution overhead when no plugins are registered.

---

## 3. Explicit Non-Goals

The following specifications are explicitly excluded from this RFC and deferred to future phases:
1. **Dynamic Tree Expansion in Phase A**: Dynamically generating children or altering tree hierarchies during traversal (Deferred).
2. **Custom Traversal Strategies**: Support for custom pathfinders or traversal algorithms.
3. **Exporter Execution During Runtime Evaluation**: Invoking report exporters during evaluation phases. Exporters must be executed post-evaluation and remain separate from runtime scoring/traversal to ensure they do not affect evaluation determinism.
4. **Plugin State Persistence**: Storing mutable internal plugin states, caching parameters across evaluation boundaries, or stateful lifecycle trackers.
5. **Async or I/O Plugins**: Supplying any async execution loop (`Future`/`Stream`) or permitting file/network socket communication inside plugins.

---

## 4. Plugin Categories (v0.3 Core)

### 4.1 Active: Node Evaluators
Interceptors executed during the **Scoring Phase** before final scoring arithmetic. They query variables in the `EvaluationContext` and return updated node parameters:
* **Example Use Case**: Updating a node's cost score based on current network bandwidth data passed via the context.

### 4.2 Deferred: Branch Expanders
Dynamic node-expansion logic during traversal is out of scope for v0.3. Branch expansion is deferred to a future specification (v0.4+) under a strict, isolated preprocessing model.

### 4.3 Deferred: Report Exporters
Result formatting tools that run after execution is complete do not participate in or affect the runtime evaluation pipeline. They do not belong in the runtime engine registry and are deferred to post-evaluation helper packages.

---

## 5. Deterministic and Execution Constraints

To prevent plugins from introducing non-deterministic entropy, the following execution contracts are enforced:

### 5.1 Strict Execution Ordering
* **Registry Order Execution**: Registered `NodeEvaluator` plugins must execute sequentially in the exact index order they are defined in the `PluginRegistry` list.
* **Duplicate ID Rejection**: Every plugin must declare a unique identifier. The engine will validate registry inputs during initialization and throw an exception if duplicate IDs are detected.
* **Stable Identifiers**: Plugin IDs must be stable, ASCII-only strings. Non-ASCII characters are forbidden to prevent locale collation discrepancies.

### 5.2 Failure Policy
* **Deterministic Failures**: If any registered plugin throws an exception during evaluation, the engine must capture it, abort execution immediately, transition the pipeline to the `failed` state, and propagate the error details in `EvaluationResult.errorMessage`.
* **No Fallback-to-Root**: The engine will not apply fallback-to-root behaviors or suppress errors when a plugin fails, unless explicitly configured in a future RFC.

### 5.3 Metric Ownership and Immutability Safeguards
* **Engine-Owned Metrics & Identity**: The engine reserves sole ownership of structural node identity and propagation parameters. Evaluators MUST NOT modify:
  * `id` (identifier)
  * `parentId` (parent identifier)
  * `childIds` (child identifiers)
  * `depth` (node depth level)
  * `confidence` (engine-propagated decayed confidence value)
* **Evaluator-Allowed Fields**: Evaluators are strictly limited to adjusting scoring coordinates and diagnostic/metadata fields:
  * `probability`
  * `impact`
  * `cost`
  * `metadata`
  * `tags`
* **Automatic Enforcement**: If a plugin attempts to alter any engine-owned fields (e.g. overrides `confidence` or modifies child links), the engine will ignore those alterations, restoring the original engine-propagated confidence and structural properties before final utility scoring occurs.

---

## 6. Replay Requirements

Replay infrastructure operates strictly on static evidence. Replaying a snapshot must **never** execute plugins.

```
[ Evaluation Session ] ──(NodeEvaluators run)──> [ DebugSnapshot ]
                                                       │
                                                       ▼ (JSON Storage)
                                                       │
[ Replay Session ] <──(Reads static snapshot only)─────┘ (No plugin classes required)
```

1. **Baking Modified Coordinates**: Any adjustments made by a `NodeEvaluator` to a node's metrics (`probability`, `impact`, `cost`, `confidence`, `score`) must be written directly into the exported `DebugSnapshot.nodeSnapshots` collection.
2. **Plugin Decoupling**: The `ReplayLoader` and `ReplaySession` must not import, require, or reference any custom plugin classes to reconstruct the decision flow.

---

## 7. Explainability Requirements

Explainability reports must remain strictly evidence-based and drawn exclusively from snapshot contents.

1. **Reasoning Integrity**: Plugins cannot override the standard explanation layout or inject generated text.
2. **Evidence Logging**: Custom telemetry variables or decision criteria added by plugins must be logged in the node's `metadata` map during the evaluation phase. The `BranchIQExplainer` reads this metadata to report literal evidence without interpreting the code semantics.

---

## 8. Serialization Requirements

Plugin adjustments must integrate seamlessly with `RFC-0002` canonical rules:

1. **Complete Metric Serialization**: All modified coordinates must be serialized in `nodeSnapshots` with exact 4-decimal formatting.
2. **Metadata Key Sorting**: Custom metadata keys generated by plugins must be sorted alphabetically, and empty collections must be represented correctly (e.g. `{}`).

---

## 9. Public API Proposal

We propose the following clean interfaces for v0.3:

```dart
/// Represents a plugin that dynamically evaluates node variables prior to scoring.
abstract class NodeEvaluator {
  /// The unique, stable ASCII-only identifier of this evaluator.
  String get id;

  /// Modifies and returns a copy of [node] based on variables in [context].
  DecisionNode evaluate(DecisionNode node, EvaluationContext context);
}

/// A container registry for registering plugins active during evaluation.
class PluginRegistry {
  /// The ordered sequence of NodeEvaluators.
  final List<NodeEvaluator> evaluators;

  /// Creates a [PluginRegistry] instance.
  PluginRegistry({
    List<NodeEvaluator> evaluators = const [],
  }) : evaluators = List<NodeEvaluator>.unmodifiable(evaluators);
}
```

### Registry Integration in Engine
The public `BranchIQEngine.evaluateSync` method is updated to accept the registry:

```dart
  EvaluationResult evaluateSync({
    required DecisionTree tree,
    ScoringConfig? scoringConfig,
    PruningConfig? pruningConfig,
    TraversalConfig? traversalConfig,
    EvaluationContext? context,
    PluginRegistry? plugins, // <-- Registered plugins
    bool enableDebug = false,
    bool enableBenchmark = false,
  });
```

---

## 10. Validation Strategy

1. **Registry Verification**: The engine must perform initialization checks to ensure:
   * No duplicate plugin IDs exist.
   * All plugin IDs contain only ASCII characters.
2. **Deterministic Golden Verification**: Run evaluations utilizing evaluators multiple times under stress conditions, asserting that the generated snapshots remain byte-identical.
3. **Replay Equivalence Test**: Assert that snapshots produced from plugin-driven evaluations load successfully into `ReplayLoader` and produce identical paths and scores without supplying the registry to the loader.

---

## 11. Risks & Mitigations

| Risk | Severity | Mitigation |
| :--- | :--- | :--- |
| **Order-Dependent Side Effects**: Evaluators executing in different orders could yield divergent scores. | Medium | Enforce strict, sequential evaluation based on registry indexing order. |
| **Non-ASCII ID Collisions**: Unicode IDs could result in sorting or formatting differences across locales. | Low | Enforce strict ASCII-only string checks on all plugin IDs during engine verification. |
| **Performance Degradation**: Running heavy operations inside evaluators could slow down evaluations. | Medium | Restrict plugins to synchronous execution and document best practices. Core evaluations with no registered plugins bypass evaluator loops completely. |

---

## 12. Rollout Plan

The plugin infrastructure rollout is divided into four sequential phases:

```
┌─────────────────────────────────┐
│   Phase A: API & Registry Setup │
│   - Define NodeEvaluator &      │
│     PluginRegistry interfaces   │
│   - Integrate registry parameter│
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│   Phase B: Scoring Integration  │
│   - Integrate evaluators into   │
│     Scoring phase execution loop│
│   - Add duplicate ID validation │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│   Phase C: Snapshot Evidence    │
│   - Verify custom metrics write │
│     correctly into snapshots    │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│   Phase D: Verification & Audits│
│   - Replay equivalence testing  │
│   - Golden integration checks   │
└─────────────────────────────────┘
```
