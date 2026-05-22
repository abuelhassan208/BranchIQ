# BranchIQ v0.1.0: API Specification
**Version**: 0.1.0-spec  
**Author**: Principal Dart API Architect  
**Status**: Frozen for Development  

---

# 1. API Design Philosophy

The design of the BranchIQ API is governed by a strict principle:

> **"Simple bounded reasoning over hidden automation."**

In runtime intelligence systems, complexity is the primary source of failure. When decision APIs hide execution states behind dynamic magic or auto-configured singletons, debugging becomes impossible. Mobile systems require explicit inputs, output determinism, and predictability.

To ensure stability, the BranchIQ API follows these four rules:
1.  **Minimality**: Expose only the classes needed to pass state, evaluate paths, and debug results.
2.  **Immutability**: All configuration and node classes are immutable. Tree modifications create new instances, preventing race conditions.
3.  **Explicit Configuration**: Weights and thresholds must be passed explicitly to the engine. There are no hidden default profiles.
4.  **Flutter Independence**: The API operates entirely on pure Dart types. This guarantees that decision trees can be tested in isolation using command-line test runners without needing a mobile emulator.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 2. Public API Surface

The public API of the BranchIQ core engine consists of these core classes:

```
                      ┌─────────────────────────┐
                      │     BranchIQEngine      │
                      └────────────┬────────────┘
                                   │ Orchestrates
         ┌─────────────────────────┼─────────────────────────┐
         ▼                         ▼                         ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  DecisionTree   │       │  ScoringConfig  │       │  PruningConfig  │
└────────┬────────┘       └─────────────────┘       └─────────────────┘
         │ Contains
         ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  DecisionNode   │       │TraversalConfig  │       │EvaluationContext│
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

| Class | Primary Responsibility | Lifecycle & Mutability | Prohibited Behavior |
| :--- | :--- | :--- | :--- |
| **`BranchIQEngine`** | Orchestrates tree expansion, scoring, pruning, and traversal. | Stateless, instantiated once. | Must not maintain evaluation state or modify application data. |
| **`DecisionTree`** | Encapsulates the flat registry of nodes. | Immutable container. | Must not allow cyclic parent-child references. |
| **`DecisionNode`** | Represents a single decision step. | Immutable data carrier. | Must not contain references to Flutter widgets or BuildContext. |
| **`EvaluationResult`**| Contains the final path and traces. | Read-only result object. | Must not execute actions or change state. |
| **`BestPathResult`** | Ordered sequence of optimal nodes. | Read-only path wrapper. | Must not trigger network requests or UI updates. |
| **`DebugSnapshot`** | Serialized evaluation state tree. | Transient JSON exporter. | Must not render user interfaces. |
| **`ScoringConfig`** | Holds weights ($w_p, w_i, w_c$). | Immutable configuration. | Must not change values during evaluation. |
| **`PruningConfig`** | Holds pruning thresholds. | Immutable configuration. | Must not self-adjust during execution. |
| **`TraversalConfig`**| Selects the search algorithm. | Immutable configuration. | Must not run stochastic algorithms. |
| **`EvaluationContext`**| Contains environment telemetry variables. | Immutable snapshot. | Must not hold live UI stream listeners. |
| **`NodeEvaluator`** | Custom evaluator interface. | Stateless callback class. | Must not run asynchronous tasks. |
| **`BranchExpander`** | Dynamic child generator interface. | Stateless generator class. | Must not perform disk or network I/O. |

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 3. BranchIQEngine Specification

The `BranchIQEngine` coordinates the decision execution pipeline. It does not contain domain-specific business logic or execute UI transitions.

## 3.1 Required Interface Method Signatures
```dart
abstract class BranchIQEngine {
  /// Evaluates a decision tree synchronously on the current thread.
  EvaluationResult evaluateSync({
    required DecisionTree tree,
    required EvaluationContext context,
    required ScoringConfig scoring,
    required PruningConfig pruning,
    required TraversalConfig traversal,
  });

  /// Explains why a path was chosen, returning a human-readable trace log.
  String explain(EvaluationResult result);

  /// Exports the complete tree state (including pruned branches) to JSON.
  DebugSnapshot exportDebugSnapshot(EvaluationResult result);
}
```

## 3.2 Engine Guarantees
*   **Thread Safety**: Because all parameters are immutable, `evaluateSync` can be called safely from concurrent execution runtimes.
*   **Pure Orchestration**: The engine does not store state. Calling the method with the same inputs always returns the exact same `EvaluationResult`.
*   **Prohibited Actions**: The engine and its plugins are forbidden from:
    *   Reading or writing to local databases or shared preferences.
    *   Invoking Dart isolates inside the sync execution loop.
    *   Retrying queries automatically upon execution failure.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 4. DecisionNode Specification

`DecisionNode` is the basic structural element of a decision tree. Nodes are designed as lightweight structures containing dense fields to keep memory footprints low.

## 4.1 Required and Forbidden Fields

```
                              DecisionNode Fields
  ┌───────────────────────────────────┬───────────────────────────────────┐
  │         Allowed Fields            │         Forbidden Fields          │
  ├───────────────────────────────────┼───────────────────────────────────┤
  │ String id                         │ BuildContext                      │
  │ String? parentId                  │ Widget                            │
  │ List<String> childIds             │ StreamSubscription                │
  │ double probability                │ File                              │
  │ double impact                     │ PlatformChannel                   │
  │ double cost                       │ Function (Async callback)         │
  └───────────────────────────────────┴───────────────────────────────────┘
```

## 4.2 Immutable Contract
Nodes are defined as immutable classes. If a node parameter needs to change during expansion or scoring, the engine constructs a new node instance:

```dart
class DecisionNode {
  final String id;
  final String? parentId;
  final List<String> childIds;
  final double probability;
  final double impact;
  final double cost;
  final double confidence;
  final double score;
  final Map<String, dynamic> metadata;
  
  // Optional debugging metadata
  final List<String> tags;
  final int depth;
  final String? pruningReason;

  const DecisionNode({
    required this.id,
    this.parentId,
    required this.childIds,
    this.probability = 1.0,
    this.impact = 0.0,
    this.cost = 0.0,
    this.confidence = 1.0,
    this.score = 0.0,
    this.metadata = const {},
    this.tags = const [],
    this.depth = 0,
    this.pruningReason,
  });

  DecisionNode copyWith({
    double? probability,
    double? impact,
    double? cost,
    double? confidence,
    double? score,
    int? depth,
    String? pruningReason,
  }) {
    return DecisionNode(
      id: id,
      parentId: parentId,
      childIds: childIds,
      probability: probability ?? this.probability,
      impact: impact ?? this.impact,
      cost: cost ?? this.cost,
      confidence: confidence ?? this.confidence,
      score: score ?? this.score,
      metadata: metadata,
      tags: tags,
      depth: depth ?? this.depth,
      pruningReason: pruningReason ?? this.pruningReason,
    );
  }
}
```

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 5. DecisionTree Specification

`DecisionTree` represents a directed, acyclic hierarchy of nodes.

```
       Valid Tree Structure                   Invalid Tree (Cycle)
              [Root]                                 [Root]
             /      \                               /      \
        Node A      Node B                     Node A      Node B
          │                                      │           ▲
        Node C                                 Node C ───────┘
```

## 5.1 Validation Constraints
A tree is invalid and cannot be evaluated if it fails any of these rules:
1.  **Exactly One Root**: The tree must contain exactly one root node, whose `parentId` must be `null`.
2.  **Strict Acyclicity**: No node's child list can contain its own ancestor IDs.
3.  **Explicit Registration**: All IDs declared in child lists must exist in the tree's flat registry map.
4.  **No Orphans**: Every node must be reachable by traversing downwards from the root.

## 5.2 Tree Verification Methods
```dart
abstract class DecisionTree {
  /// The root node of the tree.
  DecisionNode get root;

  /// Flat lookup map of node registry.
  Map<String, DecisionNode> get nodes;

  /// Returns true if the tree has no cycles and contains no orphans.
  bool isValid();

  /// Throws an exception detailing structural violations.
  void validateOrThrow();
}
```

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 6. Evaluation Pipeline Contracts

The decision evaluation pipeline runs as a series of pure functional transformations:

```
  Input Event ──► [ Expansion ] ──► [ Scoring ] ──► [ Pruning ] ──► [ Traversal ] ──► Best Path
```

| Pipeline Step | Input Parameters | Output Parameters | Invariants & Guardrails |
| :--- | :--- | :--- | :--- |
| **1. Expansion** | `DecisionNode parent`, `BranchExpander` | `List<DecisionNode> children` | Child nodes must declare `parentId == parent.id`. Depth parameter increases by 1. |
| **2. Scoring** | `DecisionNode`, `ScoringConfig` | `DecisionNode` (with computed score) | Computed score is clamped to the range $[-1.0, 1.0]$. |
| **3. Pruning** | `List<DecisionNode>`, `PruningConfig` | `List<DecisionNode>` (filtered list) | Pruned nodes are marked with a `pruningReason` and discarded. |
| **4. Traversal** | `DecisionTree`, `TraversalConfig` | `List<DecisionNode>` (best path) | The path must begin at the root node and end at a leaf or depth-limit node. |

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 7. ScoringConfig Specification

`ScoringConfig` defines the parameter weights used by the evaluation engine.

```dart
class ScoringConfig {
  final double wp; // Weight for probability
  final double wi; // Weight for impact
  final double wc; // Weight for cost
  final double costCeiling; // C_max

  ScoringConfig({
    required this.wp,
    required this.wi,
    required this.wc,
    required this.costCeiling,
  }) {
    if (wp < 0.0 || wi < 0.0 || wc < 0.0) {
      throw ArgumentError('Weights must be non-negative.');
    }
    final total = wp + wi + wc;
    if ((total - 1.0).abs() > 1e-6) {
      throw ArgumentError('Weights must sum to 1.0.');
    }
    if (costCeiling <= 0.0) {
      throw ArgumentError('costCeiling must be positive.');
    }
  }
}
```

## 7.1 Configuration Restrictions
*   All weights must be bounded: $w_p, w_i, w_c \in [0.0, 1.0]$.
*   Weight parameters are validated on instantiation. If validation fails, the config constructor throws an `ArgumentError` to prevent calculations with invalid configurations.
*   Once created, weights are immutable.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 8. PruningConfig Specification

`PruningConfig` defines the search space filters used during the evaluation cycle.

```dart
class PruningConfig {
  final double minProbability;
  final double minScore;
  final int beamWidth;
  final int maxDepth;
  final int maxNodeLimit;

  PruningConfig({
    required this.minProbability,
    required this.minScore,
    required this.beamWidth,
    required this.maxDepth,
    required this.maxNodeLimit,
  }) {
    assert(minProbability >= 0.0 && minProbability <= 1.0);
    assert(minScore >= -1.0 && minScore <= 1.0);
    assert(beamWidth >= 1);
    assert(maxDepth >= 1 && maxDepth <= 12);
    assert(maxNodeLimit >= 1 && maxNodeLimit <= 1000);
  }
}
```

## 8.1 Safe Fallbacks
If pruning filters out all active branches, the engine halts evaluation, logs the failure, and returns the root node's action path as a safe default fallback.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 9. TraversalConfig Specification

`TraversalConfig` defines the algorithms used to find the optimal path.

```dart
enum TraversalStrategy {
  priorityFirst, // Modified A* search
}

class TraversalConfig {
  final TraversalStrategy strategy;

  const TraversalConfig({
    this.strategy = TraversalStrategy.priorityFirst,
  });
}
```

## 9.1 Tie-Breaking Rules
To ensure output determinism, when two nodes have the exact same score during traversal:
*   The engine sorts the nodes alphabetically by their unique ID strings (`node.id.compareTo(other.id)`).
*   Random tie-breaking is prohibited.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 10. EvaluationContext Specification

`EvaluationContext` is a read-only container that holds application and environmental telemetry parameters:

```dart
class EvaluationContext {
  final Map<String, dynamic> _variables;

  const EvaluationContext(this._variables);

  /// Retrieves a system telemetry value.
  T? get<T>(String key) {
    final value = _variables[key];
    if (value is T) return value;
    return null;
  }
}
```

## 10.1 Variable Restrictions
*   **Allowed Variables**: Immutable telemetry metrics (e.g., `"networkLatency"`, `"batteryLevel"`, `"isLowPowerMode"`).
*   **Forbidden Variables**: Mutable class references, UI widgets, stream listeners, or instances of `BuildContext`.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 11. Extension Point Contracts

To support customization without modifying core code, BranchIQ exposes two interfaces:

## 11.1 NodeEvaluator Interface
Responsible for calculating scores for dynamic decision paths:

```dart
abstract class NodeEvaluator {
  /// Evaluates node parameters using the current context.
  DecisionNode evaluateNode(DecisionNode node, EvaluationContext context);
}
```

*   **Restrictions**: Evaluators must be stateless, and are forbidden from accessing UI widgets or performing disk I/O.

## 11.2 BranchExpander Interface
Responsible for generating child nodes during the expansion phase:

```dart
abstract class BranchExpander {
  /// Generates child nodes for a parent decision node.
  List<DecisionNode> expandBranch(DecisionNode parent, EvaluationContext context);
}
```

*   **Restrictions**: Generators must construct child nodes as acyclic extensions of the parent, and are forbidden from making network requests.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 12. Error Handling Contracts

BranchIQ handles errors predictably using these rules:

```
  ┌────────────────────────────────────────────────────────┐
  │                      Error Handling                    │
  └───────────────────────────┬────────────────────────────┘
                              ▼
        ┌────────────────────────────────────────────┐
        │ Is it a configuration/validation error?    │
        └─────────────────────┬──────────────────────┘
                              │
                    ┌─────────┴─────────┐
                YES │                   │ NO (Operational)
                    ▼                   ▼
          ┌───────────────────┐       ┌───────────────────┐
          │   Fail Fast       │       │ Graceful Degrade  │
          │   (Throw Error)   │       │ (Log & Fallback)  │
          └───────────────────┘       └───────────────────┘
```

## 12.1 Explicit Exceptions
*   **`InvalidTreeException`**: Thrown if validation checks detect structural loops or orphan nodes.
*   **`InvalidConfigException`**: Thrown if weight parameters do not sum to $1.0$ or threshold bounds are violated.

## 12.2 Degradation Policies
*   **Configuration Errors**: Throw exceptions immediately during initialization to detect setup errors early.
*   **Operational Errors**: Handled gracefully. If an evaluation cycle encounters an error (e.g., dynamic expansion throws an exception), the engine catches the error, logs a warning, and returns the root node's action path as a safe default fallback.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 13. Serialization Contracts

The telemetry and logging systems require the complete decision tree state to be serializable.

## 13.1 Serialization Rules
*   **Allowed Data**: Node properties ($P, I, C, K$, scores), parent-child relationships, metadata maps, and configuration parameters.
*   **Forbidden Data**: Memory pointers, system classes, database configurations, and active transaction logs.

## 13.2 Serialized JSON Format Output
```json
{
  "engine_version": "0.1.0",
  "evaluated_at": "2026-05-22T11:27:49.000Z",
  "root_id": "root",
  "nodes": {
    "root": {
      "id": "root",
      "parent_id": null,
      "child_ids": ["node_1", "node_2"],
      "probability": 1.0,
      "impact": 0.0,
      "cost": 0.0,
      "confidence": 1.0,
      "score": 0.0
    }
  }
}
```

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 14. Determinism Guarantees

To ensure debugging reproducibility, the evaluation cycle is strictly deterministic.

```
Input (Context, Config) ──► [ Deterministic Sort ] ──► [ Pure Evaluation ] ──► Bounded Output Path
```

## 14.1 Determinism Rules
*   **Lexicographical Tie-Breaking**: When sibling nodes have the exact same score, the engine sorts them alphabetically by their unique ID strings.
*   **No Randomization**: Using random number generators (`dart:math.Random`) inside scoring engines or traversals is prohibited.
*   **No Dynamic Timestamps**: Evaluators must read timestamps from the `EvaluationContext` snapshot instead of querying the system time directly (`DateTime.now()`).
*   **Single-Threaded Execution**: Sync evaluations run sequentially on a single thread to avoid race conditions.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 15. Performance Contracts

To prevent main-thread latency spikes, core engine execution must adhere to strict performance ceilings:

*   **Synchronous Latency Ceiling**: Single-threaded evaluations of standard decision trees (depth $d \le 4$, nodes $\le 100$) must complete in under **1.0 millisecond** on modern mobile hardware.
*   **Heap Allocation Limits**: The engine avoids allocating new collection objects during traversal by reusing a single priority queue allocation.
*   **Call Stack Limits**: Tree traversals are written using iterative loops rather than deep recursive calls, preventing stack overflows.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 16. API Stability Rules

BranchIQ v0.1.0 establishes these package version boundaries:

*   **Semantic Versioning**: Minor signature changes will trigger a minor release (`0.1.0` $\to$ `0.2.0`). Major breaking changes will trigger a major release (`1.0.0`).
*   **Frozen Public APIs**: The interfaces of `BranchIQEngine`, `DecisionTree`, `DecisionNode`, and the configuration classes are frozen for the `v0.1.0` release cycle.
*   **Experimental Features**: Softmax stabilization options and dynamic context providers are marked as experimental and may change in subsequent releases.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 17. Example API Lifecycle

This pseudocode illustrates how a developer initializes and runs an evaluation cycle using the BranchIQ API:

```dart
void main() {
  // 1. Define nodes
  const root = DecisionNode(
    id: 'root',
    childIds: ['fetch_cache', 'fetch_network'],
  );
  const cacheNode = DecisionNode(
    id: 'fetch_cache',
    parentId: 'root',
    childIds: [],
    probability: 0.95,
    impact: 0.8,
    cost: 10.0, // latency ms
  );
  const netNode = DecisionNode(
    id: 'fetch_network',
    parentId: 'root',
    childIds: [],
    probability: 0.80,
    impact: 1.0,
    cost: 350.0, // latency ms
  );

  // 2. Build tree
  final tree = DecisionTree.fromNodes([root, cacheNode, netNode]);

  // 3. Configure scoring weights
  final scoring = ScoringConfig(
    wp: 0.4,
    wi: 0.4,
    wc: 0.2,
    costCeiling: 1000.0,
  );

  // 4. Configure pruning thresholds
  final pruning = PruningConfig(
    minProbability: 0.5,
    minScore: -0.8,
    beamWidth: 3,
    maxDepth: 3,
    maxNodeLimit: 50,
  );

  // 5. Initialize context
  final context = EvaluationContext({
    'networkLatency': 150.0,
    'batteryLevel': 0.85,
  });

  // 6. Run evaluation
  final engine = BranchIQEngine.createSync();
  final result = engine.evaluateSync(
    tree: tree,
    context: context,
    scoring: scoring,
    pruning: pruning,
    traversal: const TraversalConfig(),
  );

  // 7. Inspect results
  print('Selected path: ${result.bestPath.nodeIds}');
  print('Explain decision: ${engine.explain(result)}');
}
```

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 18. Forbidden API Patterns

To prevent design regression, the package codebase must not use these patterns:

*   **Global Singletons**: Avoid shared engine singletons (`BranchIQEngine.instance`). Global states introduce side-effects and make testing difficult. Engines must be instantiated locally by caller classes.
*   **Hidden State Mutation**: The engine must not modify decision tree data structures or context maps during evaluation.
*   **Asynchronous Scoring Loops**: The scoring phase must remain synchronous. Async updates introduce race conditions and latency issues.
*   **Widget-Bound APIs**: Core classes must not import Flutter UI frameworks or depend on widget lifecycle events.
*   **Automatic Plugin Registration**: Avoid automatic setup scripts. Extender plugins must be registered explicitly in configuration files.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 19. Future API Evolution Philosophy

To ensure smooth future updates, the v0.1.0 API is designed with these extensibility points:

*   **Parameter Extensibility**: Node properties are stored inside a generic metadata map (`Map<String, dynamic> metadata`). This allows future models (such as machine-learned scoring engines) to add parameter fields without changing the core `DecisionNode` schema.
*   **Decoupled Worker Interfaces**: The engine exposes pure synchronous interfaces. This ensures that future asynchronous isolate worker pools can be implemented as wrapper decorators without altering the underlying core engine logic.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# 20. Final API Lock

The development of the BranchIQ v0.1.0 API surface is locked to this core objective:

> **BranchIQ v0.1.0 APIs exist only to support bounded deterministic decision evaluation in pure Dart.**

All additional classes, methods, and integrations are deferred.

---

## API Section Checklist
- [x] responsibilities clearly defined
- [x] forbidden behaviors defined
- [x] deterministic guarantees explained
- [x] extensibility impact considered
- [x] overengineering avoided

---

# API Architecture Audit

This audit evaluates the quality and completeness of the BranchIQ API specification.

## Subsystem Assessment Scores (1-10)

| Subsystem / Dimension | Score | Assessment Rationale |
| :--- | :--- | :--- |
| **API Clarity** | **10/10** | Exposes clear interfaces with explicit parameters, avoiding complex dynamic setups. |
| **Extensibility Safety** | **9/10** | Exposes base interfaces like `NodeEvaluator` and generic metadata maps, enabling future updates. |
| **Deterministic Safety** | **10/10** | Enforces alphabetical tie-breaking and blocks external random sources inside evaluation loops. |
| **pub.dev Usability** | **10/10** | Written in pure Dart with zero external package dependencies. |
| **Runtime Safety** | **10/10** | Validates configuration parameters early, using safe fallback nodes during runtime errors. |
| **Flutter Compatibility** | **10/10** | Avoids runtime reflection via codegen and works cleanly across desktop, web, and mobile runtimes. |
| **Testing Friendliness** | **10/10** | Uses pure functional architectures, allowing developers to test trees in simple console scripts. |
| **Future-Proofing** | **9/10** | Separates synchronous evaluation from future isolate integrations, keeping core interfaces small. |

---

## Audit Findings

### 1. Strongest API Decision
Using **immutable configurations and stateless engine orchestration**. This prevents threading race conditions and ensures that execution output is reproducible.

### 2. Riskiest API Decision
Using a generic map (`Map<String, dynamic> metadata`) inside `DecisionNode` to hold custom parameters. While flexible, this map is not type-safe and can cause runtime casting errors if parameters are set incorrectly.

### 3. APIs Most Likely to Become Unstable
*   `EvaluationContext`: Custom properties might require complex structure validation in future updates.
*   `BranchExpander`: Dynamic branch generation signatures might require updates when parallel evaluations are introduced.

### 4. APIs That Must Remain Frozen
*   `BranchIQEngine.evaluateSync()` signature.
*   `DecisionNode` core fields.
*   `ScoringConfig` weight validation logic.

### 5. Recommended Next Planning Document
`docs/core/implementation_plan.md` to define the execution tasks for building the v0.1.0 codebase.
