# BranchIQ v0.1.0: MVP Boundary Specification
**Version**: 0.1.0-mvp  
**Author**: Principal Systems Architect  
**Status**: Frozen for Development  

---

# 1. MVP Definition

## 1.1 Core Definition
The Minimum Viable Product (MVP) for BranchIQ (v0.1.0) is defined strictly as:

> **A synchronous, bounded, local decision tree engine written in pure Dart that can construct decision nodes, expand a limited decision tree, calculate weighted scores, prune weak branches, extract the best path, and export JSON debug snapshots.**

```
                     ┌─────────────────────────────┐
                     │       BranchIQ Engine       │
                     │   (Synchronous Evaluation)  │
                     └──────────────┬──────────────┘
                                    │
           ┌────────────────────────┼────────────────────────┐
           ▼                        ▼                        ▼
  ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
  │  Decision Nodes │      │   Scoring /     │      │   Pruning &     │
  │  (Pure Dart)    │      │  Normalization  │      │   Traversal     │
  └─────────────────┘      └─────────────────┘      └─────────────────┘
```

## 1.2 Out of Scope for MVP
To prevent scope creep and maintain low latency, the MVP does not include the following:
*   **Adaptive AI/ML Runtimes**: No reinforcement learning or dynamic weights training.
*   **Online/Bayesian Learning**: No on-device probability updates based on system logs.
*   **Isolate-Based Concurrent Engine**: The engine runs entirely on the caller's thread.
*   **Flutter UI Automation / Element Tree Binding**: The core engine has no knowledge of widgets, render objects, or UI cycles.
*   **DevTools Visualizer Extension**: Visual debugging is deferred to subsequent releases.
*   **Multi-Agent state coordination**: No multi-agent protocols or synchronized locks.

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 2. MVP Goals

The development of v0.1.0 is driven by these concrete, measurable goals:

*   **Model Validation**: Verify that a multi-attribute utility theory (MAUT) model can rank decision paths on-device.
*   **API Ergonomics**: Expose a clean, developer-friendly Dart API that requires less than 20 lines of setup code.
*   **Deterministic Output**: Ensure that given the same context vector $\mathbf{x}$ and configuration parameters, the engine returns the exact same execution path.
*   **Main Isolate Safety**: Guarantee execution times under **1 millisecond** for standard tree configurations, preventing frame drops on the main thread.
*   **Minimal Search Space**: Support small trees (depth $d \le 4$, branching factor $b \le 3$).
*   **Algebraic Scoring**: Evaluate paths using static weight configurations ($w_p, w_i, w_c$).
*   **Frontier Pruning**: Prevent resource waste by discarding branches early using simple score and probability thresholds.
*   **Path Back-propagation**: Reconstruct and return the chosen decision sequence cleanly.
*   **JSON Observability**: Export the evaluated tree state to JSON for offline troubleshooting.
*   **pub.dev Readiness**: Package the engine to have zero external dependencies, making it ready for open-source publication.

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 3. MVP Non-Goals

The following systems are explicitly excluded from v0.1.0. 

| Excluded System | Why Excluded | Risk If Built Too Early | Target Phase |
| :--- | :--- | :--- | :--- |
| **Bayesian Learning** | Requires statistic tracking and online estimation of transitions. | Introduces state mutation risks and API complexity. | Phase 2 |
| **On-device Reinforcement Learning** | Requires policy gradient calculations and local training loops. | Blocks the UI thread, leaks memory, and delays the core MVP release. | Phase 6 |
| **Local LLM Integration** | High resource requirements (RAM/CPU/Storage). | Unrunnable on standard mobile hardware. | Phase 6 |
| **Multi-agent Coordination** | Requires conflict resolution protocols and locks. | High API friction and concurrency bugs. | Phase 5 |
| **Adaptive UI Engine** | Requires direct manipulation of Flutter's Element Tree. | Couples the core library to specific Flutter rendering behaviors. | Phase 4 |
| **Predictive UX Engine** | Requires background tracing of user touch events. | Raises user privacy concerns and increases telemetry size. | Phase 3 |
| **Isolate Worker Pool** | Requires multi-isolate spawning and port management. | Serialization overhead can make small queries slower than sync execution. | Phase 2 |
| **DevTools Extension** | Requires integration with Dart VM service protocols. | Diverts engineering resources away from stabilizing the core engine. | Phase 3 |
| **Plugin Marketplace** | Requires package version checking and sandbox runtimes. | Massive security and architectural scope creep. | Phase 3 |
| **Persistent Transaction Log** | Requires platform-specific file system access (I/O). | Introduces database engine dependencies and disk latency. | Phase 3 |
| **Code Generation** | Requires complex setups with `build_runner` and `analyzer`. | High developer friction for initial adoption. | Phase 2 |
| **Object Pooling** | Reusing node memory blocks instead of GC allocation. | Premature optimization that can hide memory leak bugs. | Phase 2 |
| **Replay Engine** | Deterministic re-simulation of recorded events. | API changes during early versions will break replay compatibility. | Phase 2 |
| **Telemetry Upload** | Network transport layers for analytics telemetry. | Creates external HTTP/gRPC client dependencies. | Phase 3 |
| **Distributed Coordination** | Consistence protocols (CRDTs or Raft) for multiple devices. | Introduces heavy networking and synchronization code. | Phase 5 |

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 4. Core MVP Feature Set

Only the features listed in this section are authorized for implementation in v0.1.0.

```
                    ┌────────────────────────────────┐
                    │      Allowed MVP Features      │
                    └───────────────┬────────────────┘
                                    │
    ┌──────────────────────┬────────┴─────────────┬──────────────────────┐
    ▼                      ▼                      ▼                      ▼
┌──────────────┐       ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│ DecisionNode │       │ DecisionTree │       │  Evaluation  │       │ Pruning      │
│ (Properties) │       │ (Structure)  │       │  & Scoring   │       │ (Thresholds) │
└──────────────┘       └──────────────┘       └──────────────┘       └──────────────┘
```

## 4.1 DecisionNode Model
*   **Allowed Properties**:
    *   `String id`
    *   `String? parentId`
    *   `List<String> childIds`
    *   `double probability` ($P \in [0.0, 1.0]$)
    *   `double impact` ($I \in [-1.0, 1.0]$)
    *   `double cost` ($C \in [0.0, \infty)$)
    *   `double confidence` ($K \in [0.0, 1.0]$)
    *   `double score` (Computed aggregate)
    *   `Map<String, dynamic> metadata` (For holding custom payload data)
*   **Prohibited**: State delta accumulation equations, rollback actions, state histories.

## 4.2 DecisionTree Container
*   **Allowed Structure**:
    *   Single root node reference.
    *   Flat node registry (`Map<String, DecisionNode>`).
    *   Child lookup helper functions.
    *   Execution depth counter.
*   **Prohibited**: Cyclic graph support (must be a strict tree), cross-isolate serialization wrappers.

## 4.3 Scoring Engine
*   **Allowed Functionality**:
    *   Multi-attribute utility formula:
        $$S(n) = K(n) \cdot \left[ w_p \cdot P(n) + w_i \cdot I(n) - w_c \cdot C_{\text{norm}}(n) \right]$$
    *   Linear cost mapping:
        $$C_{\text{norm}}(n) = \min\left(1.0, \frac{C(n)}{C_{\text{max}} + \epsilon}\right)$$
    *   Infinity check logic.
*   **Prohibited**: Softmax-based temperature scaling (softmax must not run by default), machine-learned weights, parameter drift updates.

## 4.4 Pruning Engine
*   **Allowed Functionality**:
    *   Hard probability pruning: Discard if $P(n) < P_{\text{threshold}}$.
    *   Hard score pruning: Discard if $S(n) < S_{\text{threshold}}$.
    *   Beam width capping: Select only the top $k$ nodes at each depth level during expansion.
    *   Hard ceiling checks (`maxNodes` and `maxDepth`).
*   **Prohibited**: Entropy early-termination equations, learned pruning rules.

## 4.5 Best Path Extraction
*   **Allowed Functionality**:
    *   A simple greedy priority-first search (A*) to extract the optimal path.
    *   Deterministic backtracking from the terminal node to the root.
*   **Prohibited**: Monte Carlo Tree Search (MCTS) rollouts, stochastic path selectors.

## 4.6 Debug Output
*   **Allowed Functionality**:
    *   Method `toJson()` on the evaluated tree to output a structured log.
    *   Human-readable console logger output explaining pruning decisions (e.g., `"Node A pruned: probability 0.12 below threshold"`).
*   **Prohibited**: DevTools integration packages, UI inspectors.

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 5. Runtime Constraints

To protect the main isolate's event loop, the engine enforces these default constraints during a decision cycle:

| Parameter | MVP Default Value | Architectural Purpose |
| :--- | :--- | :--- |
| `maxDepth` | `4` | Prevents deep recursive call-stacks that block the CPU. |
| `maxBranchingFactor` | `3` | Caps node generation at each level. |
| `maxNodes` | `100` | Limits memory usage and prevents garbage collection spikes. |
| `beamWidth` | `3` | Limits the search frontier size. |
| `timeoutMs` | `16ms` | Guarantees execution completes within a single 60Hz frame budget. |

*   **No Isolates**: All logic runs synchronously on the caller's thread, avoiding isolate serialization delays.
*   **No Network Operations**: Remote API calls are prohibited during a decision cycle.
*   **No Local Database Storage**: The engine does not write to the file system.
*   **Zero Flutter Imports**: The core package has no dependency on the Flutter framework, making it testable in any Dart environment.

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 6. Architecture Constraints

The following architectural boundaries are frozen for the v0.1.0 development cycle:

```
                  ┌─────────────────────────────────────┐
                  │       Core Engine Core Rules        │
                  └──────────────────┬──────────────────┘
                                     │
         ┌───────────────────┬───────┴───────────┬───────────────────┐
         ▼                   ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ Pure Dart Core  │ │  No Reflection  │ │ No Code Gen     │ │ Determinism     │
│ (Flutter Free)  │ │ (dart:mirrors)  │ │ (No build_runner)│ │ (Safe Runtimes) │
└─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘
```

*   **Pure Dart Core**: The core library contains only standard Dart package imports. It can run in command-line tools, backend servers, or Flutter apps.
*   **No Reflection**: The library does not use `dart:mirrors` (which is disabled in Flutter's ahead-of-time compilation).
*   **No Code Generation**: All classes are instantiated directly using standard constructor parameters, without relying on `build_runner`.
*   **No Native Platform Channels**: The package contains no platform-specific Java, Swift, C++, or Kotlin code.
*   **Pure Algebraic Scoring**: Node metrics are evaluated using basic arithmetic operations, without external ML runtime dependencies.
*   **Strict Determinism**: Node scoring and traversal are structured as pure functions. Passing the same parameters always yields the exact same decision path.

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 7. API Boundary

## 7.1 Class Responsibilities & Boundaries

```
                      ┌─────────────────────────┐
                      │    BranchIQEngine       │
                      │  (Entry Point / Evalu)  │
                      └────────────┬────────────┘
                                   │ Accepts
         ┌─────────────────────────┼─────────────────────────┐
         ▼                         ▼                         ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  DecisionTree   │       │  ScoringConfig  │       │  PruningConfig  │
│  (Data model)   │       │  (Weights config)│       │  (Thresholds)   │
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

### 7.1.1 BranchIQEngine
*   **Responsibility**: The primary entry point. Coordinates tree expansion, scoring, pruning, and path extraction.
*   **Input**: `DecisionTree`, `ScoringConfig`, `PruningConfig`, `Map<String, dynamic> context`.
*   **Output**: `EvaluationResult`.
*   **Must Not**: Spawn background threads, write logs to files, or execute the side-effects of chosen actions.

### 7.1.2 DecisionNode
*   **Responsibility**: Immutable data model representing a single decision step.
*   **Input**: Node ID, parent ID, children IDs, and evaluation parameters ($P, I, C, K$).
*   **Output**: Property values and metadata accessors.
*   **Must Not**: Perform scoring logic or maintain parent-child object pointers directly.

### 7.1.3 DecisionTree
*   **Responsibility**: A container that holds a flat map of nodes.
*   **Input**: A list or map of `DecisionNode` instances.
*   **Output**: Quick lookup operations for nodes.
*   **Must Not**: Perform state delta checks or hold mutable execution parameters.

### 7.1.4 ScoringConfig
*   **Responsibility**: Defines and validates scoring weights.
*   **Input**: Weights $w_p, w_i, w_c$ and a maximum cost ceiling $C_{\text{max}}$.
*   **Output**: Normalized weight parameters.
*   **Must Not**: Change values dynamically mid-path evaluation.

### 7.1.5 PruningConfig
*   **Responsibility**: Defines search thresholds.
*   **Input**: Minimum probability, minimum score, and beam width parameter $k$.
*   **Output**: Immutable configuration values.
*   **Must Not**: Self-adjust based on execution history.

### 7.1.6 EvaluationResult
*   **Responsibility**: Encapsulates the results of a decision cycle.
*   **Input**: Best path, performance metrics, and a debug snapshot.
*   **Output**: Selected actions and duration metrics.
*   **Must Not**: Execute the application action handlers directly.

### 7.1.7 DebugSnapshot
*   **Responsibility**: Serializes the evaluation log.
*   **Input**: Full tree state (including pruned and discarded nodes).
*   **Output**: JSON format string.
*   **Must Not**: Render user interfaces or write files to disk.

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 8. MVP Execution Flow

The MVP decision cycle executes as a synchronous pipeline:

```
  ┌────────────────────────────────────────────────────────┐
  │                 Input: Root Node & Context             │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │        Generate Child Nodes (Expansion Step)           │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │          Score Nodes (MAUT Utility Scoring)            │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │         Prune Nodes (Thresholds & Beam Capping)        │
  └───────────────────────────┬────────────────────────────┘
                              ▼
        ┌────────────────────────────────────────────┐
        │ Depth / Node Limit Reached?                │ NO
        └─────────────────────┬──────────────────────┘
                              │ YES
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │          Extract Best Path via Priority Traversal      │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │          Return Result & Export Debug Snapshot         │
  └────────────────────────────────────────────────────────┘
```

## 8.2 Execution Safety
*   If an evaluation step fails (e.g., a node lacks child configurations or triggers a mathematical exception), the pipeline stops immediately.
*   The engine catches the error, logs the failure, and returns a baseline `EvaluationResult` containing only the root action, avoiding application crashes.

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 9. Failure Cases & Guardrails

The engine uses these sanitization policies to handle edge cases and invalid parameters without throwing exceptions:

| Failure Case | Engine Policy | Action / Sanitization |
| :--- | :--- | :--- |
| **Probability $P \notin [0.0, 1.0]$** | Sanitize | Clamp values: $P < 0.0 \implies 0.0$, $P > 1.0 \implies 1.0$. Log a warning. |
| **Cost $C < 0.0$** | Sanitize | Clamp to $0.0$. Log a warning. |
| **Score $S = \text{NaN}$** | Sanitize | Replace with baseline score $-1.0$. |
| **Score $S = \infty$** | Sanitize | Replace with maximum score $1.0$ (or $-1.0$ for negative infinity). |
| **Missing children configuration** | Handle | Treat the node as a leaf. Halt further expansion of this branch. |
| **Empty Tree Input** | Guard | Return an empty `EvaluationResult` immediately. |
| **Pruning all active branches** | Guard | Fall back to the root node action path. |
| **Exceeding `maxDepth` limit** | Guard | Halt expansion. Evaluate and select the best path from the generated nodes. |
| **Exceeding `maxNodes` limit** | Guard | Halt expansion. Evaluate and select the best path from the generated nodes. |
| **Weights do not sum to $1.0$** | **Throw** | Throw an `ArgumentError` on configuration init. Invalid setups must fail fast. |

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 10. MVP Success Criteria

We evaluate the success of the v0.1.0 MVP using these criteria:

*   **Successful Evaluation**: The engine parses a 3-level decision tree and selects the optimal path.
*   **Deterministic Output**: Running the same test vector 1,000 times yields the exact same path.
*   **Explainable Choices**: The debug logs explain why node options were pruned.
*   **Zero-Dependency Core**: The core engine runs cleanly on any standard Dart runtime.
*   **High Performance**: Unit tests confirm average evaluation times of less than **0.5 milliseconds** for a 20-node tree on desktop and mobile platforms.
*   **Clean API**: Developers can initialize the engine and run a query in less than 20 lines of code.

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 11. MVP Failure Criteria

The MVP release will be considered a failure if it meets any of the following conditions:

*   **Excessive API Setup**: Integrating the engine requires writing complex boilerplate classes.
*   **UI Thread Blocking**: Evaluating a 50-node tree takes longer than 8ms, causing UI stutter.
*   **Flutter Coupling**: The core engine requires importing Flutter framework libraries, preventing it from running in plain Dart environments.
*   **External Dependencies**: The package requires external packages (e.g., path providers, ML runtimes) to run basic queries.
*   **Black-Box Decisions**: The engine cannot log the specific reason why a path was chosen or pruned.
*   **Memory Leaks**: Running repetitive evaluations triggers memory leaks.

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 12. Deferred Systems Roadmap

Excluded features are mapped to future development phases:

| Phase | Theme | Included Systems / Features |
| :--- | :--- | :--- |
| **Phase 1** | **MVP Core Engine** | Bounded synchronous tree generation, MAUT scoring, linear cost normalization, threshold/beam pruning, deterministic $A^*$ traversal, JSON debug logs. |
| **Phase 2** | **Adaptive Context & Performance** | Persistent background isolate pools, telemetry collectors, node pooling/allocators, code-generator builders (`build_runner`), and dynamic threshold calibration. |
| **Phase 3** | **Observability & Tools** | DevTools companion visualizer package, JSON replay engine, and remote telemetry upload layers. |
| **Phase 4** | **Adaptive UI Layouts** | Flutter framework extensions, widget lifecycle observers, and dynamic layout configuration selectors. |
| **Phase 5** | **Multi-Agent Runtime** | Multi-agent coordination protocols, state locks, and distributed node synchronization. |
| **Phase 6** | **On-Device AI Integration** | Local LLM orchestrators, local policy gradient optimization, and reinforcement learning modules. |

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 13. Relationship to core_engine_spec.md

The documentation architecture of BranchIQ is structured hierarchically:

```
               [ core_engine_spec.md ]
             (Long-Term Vision / Specs)
                        │
                        ▼
               [ mvp_boundary.md ]
             (Strict Implementation Filter)
                        │
                        ▼
               [ Concrete Codebase ]
               (Dart / Flutter MVP)
```

*   `core_engine_spec.md` represents the long-term architectural goals of the package.
*   `mvp_boundary.md` acts as a filter during the development of v0.1.0. 
*   **Conflict Rule**: If a design pattern or algorithm in the specification document contradicts a rule in this boundary document, the boundary document wins for v0.1.0.
*   We avoid adding features to the MVP simply to support future systems. We only add clean APIs that can be extended in future phases.

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# 14. Final MVP Lock

Development of BranchIQ v0.1.0 is strictly limited to proving the core objective:

> **A bounded decision tree can be scored, pruned, traversed, explained, and returned safely and synchronously in Dart.**

No additional features, dependencies, or platforms are permitted for the initial release.

---

## Section Checklist
- [x] Scope is clearly defined
- [x] Overengineering risk addressed
- [x] MVP constraints stated
- [x] Future systems separated
- [x] Implementation impact explained

---

# MVP Boundary Audit

This audit evaluates the v0.1.0 MVP boundary specification's quality and completeness.

## Subsystem Assessment Scores (1-10)

| Subsystem / Dimension | Score | Assessment Rationale |
| :--- | :--- | :--- |
| **Scope Clarity** | **10/10** | Explicitly defines allowed vs. prohibited systems for every module. |
| **Implementation Realism** | **10/10** | Limits the engine to synchronous execution on the main isolate, avoiding complex concurrency code. |
| **Overengineering Resistance**| **10/10** | Blocks code generation, database storage, and machine learning components from the initial release. |
| **pub.dev Readiness** | **9/10** | Designed with zero dependencies, making publication and reuse straightforward. |
| **API Simplicity** | **9/10** | Defines clear, decoupled roles for core classes. |
| **Runtime Safety** | **10/10** | Enforces limits on depth, branching, and nodes, with sanitization for math errors. |
| **Testability** | **10/10** | Eliminates Flutter framework dependencies to allow fast, pure Dart unit tests. |
| **Future Extensibility** | **9/10** | Reserves complex features for later phases without adding temporary boilerplate code. |

---

## Audit Findings

### 1. Strongest MVP Decision
Keeping the core engine written in **pure Dart with no Flutter framework dependencies**. This makes it easy to write unit tests, run benchmarks, and reuse the library across different platforms.

### 2. Riskiest MVP Decision
Enforcing a synchronous execution model on the main thread. If developers load large contexts or configure deep search spaces, the engine could block the UI thread and drop frames. This is mitigated by hard-coded default limits (`maxDepth = 4`, `maxNodes = 100`).

### 3. Features Most Likely to Accidentally Creep In
*   Softmax scoring normalization.
*   Basic JSON serialization helper models.
*   Platform-specific logging systems.

### 4. Systems That Must Be Actively Blocked
*   Isolates or multi-threaded background workers.
*   Local database persistence.
*   Dynamic reinforcement learning weight adjustments.

### 5. Recommended Next Planning Document
`docs/core/api_specification.md` to define the concrete signatures, classes, and types for the public API.
