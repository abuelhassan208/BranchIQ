# BranchIQ v0.1.0: Runtime Execution Model
**Version**: 0.1.0-runtime  
**Author**: Principal Runtime Systems Architect  
**Status**: Frozen for Development  

---

# 1. Runtime Philosophy

The core execution architecture of BranchIQ v0.1.0 is guided by a single rule:

> **"Deterministic bounded execution over opaque autonomous behavior."**

Mobile clients cannot tolerate non-deterministic runtime behaviors. If a decision engine blocks the UI thread or behaves unpredictably due to asynchronous race conditions, it damages the user experience. 

To prevent this, BranchIQ implements a **synchronous, single-threaded execution model**. Every decision cycle runs as a pure function of its inputs (context vector $\mathbf{x}$, configurations, and tree topology), ensuring execution times remain under **1.0 millisecond** on standard mobile hardware.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 2. Runtime Execution Overview

A decision evaluation cycle is executed as a synchronous, pipeline-based orchestration:

```
  ┌────────────────────────────────────────────────────────┐
  │                 Input: Root & Context                  │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │              1. Tree Validation Check                  │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │              2. Bounded Node Expansion                 │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │              3. Multi-Attribute Scoring                │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │              4. Pruning Filtering Steps                │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │              5. Priority-First Traversal               │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │              6. Best Path Extraction                   │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │              7. Output Result & Trace Export           │
  └────────────────────────────────────────────────────────┘
```

The `BranchIQEngine` manages this flow by executing these steps sequentially on the caller's thread, preventing asynchronous execution issues.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 3. Runtime State Machine

## 3.1 State Definitions
The engine transitions through a sequence of formal runtime states during execution:

```
  ┌────────┐      evaluate()      ┌────────────┐     Valid      ┌────────────┐
  │  Idle  ├─────────────────────>│ Validating ├───────────────>│ Expanding  │
  └▲───────┘                      └─────┬──────┘                └─────┬──────┘
   │                                    │                             │
   │ Failure / Fallback                 │ Invalid Tree                │ Depth Reached
   │                                    ▼                             ▼
   │                              ┌────────────┐                ┌────────────┐
   └──────────────────────────────┤   Failed   │<───────────────┤ Traversing │
                                  └────────────┘  Exception     └─────┬──────┘
                                                                      │ Path Found
                                                                      ▼
                                                                ┌────────────┐
                                                                │ Completed  │
                                                                └─────┬──────┘
                                                                      │
                                                                      ▼
                                                                   [ Idle ]
```

| State | Description | Allowed Target States |
| :--- | :--- | :--- |
| **`Idle`** | Engine is initialized and waiting for a query. | `Validating` |
| **`Validating`** | Verifying tree structure and weights logic. | `Expanding`, `Failed` |
| **`Expanding`** | Expanding child nodes to target depth. | `Traversing`, `Failed`, `Cancelled` |
| **`Traversing`** | Extracting the optimal path from frontier. | `Completed`, `Failed` |
| **`Completed`** | Path extracted. Exporting results logs. | `Idle` |
| **`Failed`** | Error caught. Loading fallback paths. | `Idle` |
| **`Cancelled`** | Cancellation token triggered. Halting run. | `Idle` |

## 3.2 State Invariants
*   The engine must not enter `Expanding` unless `Validating` completes successfully.
*   An engine transition to `Failed` must yield a valid, safe fallback path rather than throwing an exception.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 4. Evaluation Session Lifecycle

An evaluation session is a single run of the decision engine.

*   **Isolation Guarantee**: Sessions do not share memory or cache execution data. If two sessions run concurrently, their variables remain separate.
*   **Immutability Policy**: Input configurations (weights, thresholds) and context maps are captured as read-only snapshots at session startup. Changes to external variables that occur mid-session do not affect execution.
*   **Session Data Boundary**: Node maps and evaluation statistics are allocated locally inside the session scope and are released for garbage collection immediately after the session returns.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 5. Node Lifecycle

Decision nodes transition through these states during an evaluation session:

```
  ┌───────────┐      Expand      ┌────────────┐     Calculate     ┌────────────┐
  │  Created  ├─────────────────>│  Expanded  ├──────────────────>│   Scored   │
  └───────────┘                  └────────────┘                   └─────┬──────┘
                                                                        │
                                   ┌────────────────────────────────────┴────────────────────────────────────┐
                                   │ Aggregate Score < Threshold                                             │ Top k / Traversable
                                   ▼                                                                         ▼
                            ┌────────────┐                                                            ┌────────────┐
                            │   Pruned   │                                                            │ Traversable│
                            └────────────┘                                                            └─────┬──────┘
                                                                                                            │
                                                                           ┌────────────────────────────────┴────────────────────────────────┐
                                                                           │ Path Selected                                                   │ Discarded
                                                                           ▼                                                                 ▼
                                                                    ┌────────────┐                                                    ┌────────────┐
                                                                    │  Selected  │                                                    │ Discarded  │
                                                                    └────────────┘                                                    └────────────┘
```

*   **Created**: Node allocated in memory.
*   **Expanded**: Node's child IDs are registered.
*   **Scored**: Local score and confidence calculations are completed.
*   **Pruned**: Node failed threshold checks. Expansion is halted.
*   **Traversable**: Node retained in the active search frontier.
*   **Selected**: Node included in the final selected execution path.
*   **Discarded**: Node evaluated but not chosen.

### Immutability Rule
Once a node transitions to `Scored`, its parameter values ($P, I, C, K$, and score) are frozen and cannot be mutated.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 6. Branch Expansion Lifecycle

Dynamic node generation occurs during the expansion phase:
1.  Let the current evaluation node be $parent$.
2.  The engine passes the $parent$ node parameters and the static `EvaluationContext` to the registered `BranchExpander`.
3.  The expander returns a list of candidate child nodes.
4.  **Registration Check**: Sibling nodes are assigned incremented depth parameters:
    $$\text{depth}(child) = \text{depth}(parent) + 1$$
5.  **Hard Capping**: If the new depth exceeds `maxDepth` or the total node count exceeds `maxNodeLimit`, the expansion step is rejected, and the frontier is marked as terminal.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 7. Scoring Lifecycle

Scoring calculates local utility metrics:
*   **Timing**: Scoring occurs immediately after child nodes are expanded and registered.
*   **No Overwrites**: Once a node's aggregate score is calculated:
    $$S(n) = K(n) \cdot \left[ w_p \cdot P(n) + w_i \cdot I(n) - w_c \cdot C_{\text{norm}}(n) \right]$$
    the value is cached. The engine does not recalculate or overwrite scores during a session.
*   **Prohibited Rescoring**: Incremental re-scoring or parameter updates during traversal are prohibited in v0.1.0.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 8. Pruning Lifecycle

Pruning filters out low-scoring branches to restrict the search frontier size:

```
  Scored Nodes ──► [ Probability Threshold ] ──► [ Score Threshold ] ──► [ Beam Capping ]
```

1.  **Probability Threshold**: Discard nodes if $P(n) < P_{\text{min}}$.
2.  **Score Threshold**: Discard nodes if $S(n) < S_{\text{min}}$.
3.  **Beam Capping**: Sort the remaining candidates and keep only the top $k$ nodes.
4.  **Logging**: Pruning decisions are recorded in the session's trace buffer with explicit reasons (e.g., `"Pruned: low_probability"`).
5.  **Fallback Policy**: If all candidate branches are pruned, the engine falls back to the root node's action path.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 9. Traversal Lifecycle

Traversal extracts the optimal path from the evaluated tree:
*   **Search Invariant**: The engine uses a deterministic priority queue sorted in descending order of node score.
*   **Tie-Breaking**: Sibling nodes with identical scores are sorted alphabetically by their unique ID strings.
*   **Stop Conditions**: Traversal stops when:
    *   The priority queue becomes empty.
    *   A terminal leaf node is reached.
    *   The path depth reaches the `maxDepth` limit.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 10. Result Generation Lifecycle

Once traversal completes, the engine packages the execution data:
1.  **Path Reconstruction**: The engine backtracks from the highest-scoring leaf node to build the final `BestPathResult`.
2.  **Snapshot Export**: The engine compiles evaluated nodes and pruning traces into an immutable `DebugSnapshot` JSON payload.
3.  **Encapsulation**: The path, execution metrics (duration, node counts), and debug traces are returned inside an immutable `EvaluationResult` wrapper.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 11. Runtime Ordering Guarantees

To ensure output reproducibility, all collection iterations and node sorting steps are strictly ordered:

*   **Stable Sorting**: Frontier nodes are sorted using stable sort algorithms.
*   **Lexicographical Tie-Breaking**: Sibling node ordering uses alphabetical string comparison of node IDs:
    $$\text{id}(n_1).compareTo(\text{id}(n_2))$$
*   **Prohibited**: Using unordered maps (`Map`), hash sets (`Set`), or random index selectors inside scoring and traversal code is prohibited.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 12. Runtime Boundary Enforcement

The engine enforces runtime limits at each phase of execution:

| Boundary | Threshold Limit | Checking Phase | Violation Behavior |
| :--- | :--- | :--- | :--- |
| **`maxDepth`** | `4` | Node expansion | Halt expansion of branch. Mark node as terminal. |
| **`maxNodeLimit`** | `100` | Node registration | Stop expansion. Run traversal on current nodes. |
| **`beamWidth`** | `3` | Frontier pruning | Discard all candidates ranked lower than index $k-1$. |
| **`timeoutMs`** | `16ms` | Sibling evaluation | Abort execution. Return the default root fallback. |

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 13. Failure Propagation Model

The engine isolates errors using a bounded validation and recovery pipeline:

```
  Expander Error ──► [ Catch & Log Warning ] ──► [ Mark Node Terminal ] ──► Traverser
```

## 13.1 Fail-Fast Boundaries
*   **Validation Errors**: The engine throws `ArgumentError` or `StateError` immediately during setup if configurations (such as scoring weights) are invalid, ensuring configuration errors are caught during development.

## 13.2 Graceful Degradation Boundaries
*   **Operational Errors**: Handled without throwing exceptions. If dynamic node expansion or user-defined scoring evaluators throw errors, the engine catches the error, logs a warning, marks the node as terminal, and extracts the best path from the remaining valid nodes.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 14. Cancellation Model

To support early termination of long queries, the engine supports cancellation tokens:

```dart
class ExecutionCancellationToken {
  bool _cancelled = false;
  void cancel() => _cancelled = true;
  bool get isCancelled => _cancelled;
}
```

*   **Checking**: The engine checks the token state before starting each depth expansion level.
*   **Termination Behavior**: If a cancellation is requested, the engine halts expansion, transitions to the `Cancelled` state, and returns an empty `EvaluationResult` containing only the root action, avoiding partial state leaks.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 15. Debugging & Observability Lifecycle

During execution, the session records tracing information in an internal buffer:
*   **Pruning Records**: Logs why branches were discarded (e.g., `[Prune] id: net_timeout, reason: score_threshold`).
*   **Score Calculations**: Logs parameter values and computed scores (e.g., `[Score] id: cache_load, utility: 0.85`).
*   **Path Selection Trace**: Logs traversal steps.

This tracing data is exported inside the final `DebugSnapshot` object and is disabled by default in release builds to avoid logging overhead.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 16. Runtime Safety Guarantees

To ensure execution stability, the engine enforces these safety invariants:
*   **Recursion Guards**: Tree traversal uses iterative loops rather than recursive calls, preventing stack overflows.
*   **Cycle Detection**: The engine checks state hashes along the active path. If a cycle is detected, the branch is pruned.
*   **Math Sanitization**: Floating-point outputs are clamped to prevent `NaN` or infinity errors.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 17. Memory Lifecycle Model

*   **Minimizing Heap Allocations**: The engine avoids allocating new helper objects during traversal by reusing a single pre-allocated priority queue.
*   **Node Lifecycle Scope**: Decision tree nodes are allocated during expansion and are garbage collected immediately after the evaluation result is returned.
*   **Prohibited Allocation Patterns**: Allocating temporary maps or list collections inside scoring loops is prohibited.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 18. Deterministic Execution Guarantees

To guarantee that calculations are reproducible during testing:
*   **No Randomization**: Using random number generators (`dart:math.Random`) inside scoring engines is prohibited.
*   **No Dynamic System Clocks**: Time parameters must be read from the `EvaluationContext` snapshot rather than calling system timers (`DateTime.now()`).
*   **Ordered Map Iterations**: Collection checks use ordered list arrays instead of unordered map iteration.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 19. Runtime Constraints of MVP

The v0.1.0 MVP enforces these strict execution limitations:
*   **Synchronous Only**: All logic runs synchronously on the caller's thread, avoiding background isolate overhead.
*   **No Streaming Input**: Incremental or stream-based context updates are prohibited.
*   **Immutable Configuration**: Weights and thresholds are frozen at session startup and cannot be adjusted mid-run.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 20. Deferred Runtime Systems

The following systems are excluded from v0.1.0 and deferred to later phases:

*   **Isolate Worker Pools (Phase 2)**: Offloading evaluations to background isolates. Deferred to keep early versions simple.
*   **Incremental Re-evaluation (Phase 2)**: Re-evaluating only the branches affected by a context change instead of running a full search cycle.
*   **Speculative Traversal (Phase 6)**: Speculatively expanding paths ahead of events.
*   **Multi-Agent Coordination (Phase 5)**: Coordinating execution between multiple local engines.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 21. Worked Runtime Example

This example traces the runtime execution of a 3-level decision tree query:

```
                       [Root (depth 0)]
                        /            \
           [Node A (depth 1)]    [Node B (depth 1)]
             /            \
   [Node C (depth 2)]   [Node D (depth 2)]
```

## 21.1 Execution Trace
1.  **Trigger**: The client calls `evaluateSync` passing a 3-level tree layout.
2.  **Validating**: The engine validates tree structure, verifying that the root node has no parent and that the tree contains no loops.
3.  **Expansion (Depth 1)**: Sibling nodes `Node A` and `Node B` are expanded and registered.
4.  **Scoring (Depth 1)**: Sibling nodes are scored:
    $$S(\text{Node A}) = 0.85$$
    $$S(\text{Node B}) = 0.45$$
5.  **Pruning (Depth 1)**: The scoring configuration defines a minimum score threshold $S_{\text{min}} = 0.50$. Since $S(\text{Node B}) < 0.50$, it is pruned:
    $$\text{Node B is Pruned} \implies \text{Expansion of B is blocked}$$
6.  **Expansion (Depth 2)**: Children of `Node A` (`Node C` and `Node D`) are expanded.
7.  **Scoring (Depth 2)**: Sibling nodes are scored:
    $$S(\text{Node C}) = 0.92$$
    $$S(\text{Node D}) = 0.78$$
8.  **Pruning (Depth 2)**: Sibling nodes are filtered using a beam width constraint $k = 1$. The engine sorts the candidates and retains only the top node:
    $$\text{Sorted Candidates} = (\text{Node C}, \text{Node D})$$
    $$\text{Node D is Pruned} \implies \text{Active frontier} = \{ \text{Node C} \}$$
9.  **Traversal**: The priority queue extracts the highest-scoring traversable leaf node (`Node C`).
10. **Reconstruction**: The engine backtracks from `Node C` using parent references to build the final decision path:
    $$P^* = (\text{Root}, \text{Node A}, \text{Node C})$$
11. **Complete**: The path and debug logs are returned inside the final `EvaluationResult`.

---

## Runtime Section Checklist
- [x] lifecycle clearly defined
- [x] runtime boundaries enforced
- [x] deterministic guarantees explained
- [x] failure handling defined
- [x] overengineering avoided

---

# 22. Final Runtime Lock

The execution model of BranchIQ v0.1.0 is locked to this core objective:

> **BranchIQ v0.1.0 runtime execution exists only to support bounded deterministic synchronous decision evaluation in pure Dart runtimes.**

All additional runtime behaviors, configurations, and interfaces are deferred.

---

# Runtime Architecture Audit

This audit evaluates the quality and completeness of the BranchIQ runtime execution model.

## Subsystem Assessment Scores (1-10)

| Subsystem / Dimension | Score | Assessment Rationale |
| :--- | :--- | :--- |
| **Runtime Clarity** | **10/10** | Execution phases and state transitions are explicitly defined, avoiding complex concurrent code. |
| **Deterministic Safety**| **10/10** | Blocks random seeds, system clock queries, and unordered map iterations during evaluation. |
| **Execution Boundedness**| **10/10** | Enforces hard constraints on depth, branching, and nodes, preventing infinite loops. |
| **Mobile Suitability** | **10/10** | Runs synchronously on the main thread, avoiding isolate thread-spawning latency. |
| **Observability** | **9/10** | Includes tracing buffers to export pruning reasons inside debug snapshot objects. |
| **Runtime Safety** | **10/10** | Traverses trees iteratively rather than recursively to prevent stack overflows. |
| **Extensibility Safety**| **9/10** | Wraps dynamic operations in interfaces, protecting core execution code. |
| **Failure Resilience** | **10/10** | Catches dynamic exceptions during scoring and returns fallback paths rather than crashing. |

---

## Audit Findings

### 1. Strongest Runtime Decision
Using **iterative traversal loops combined with state-hash ancestor checks**. This prevents stack overflows and infinite loop cycles when evaluating user-defined trees.

### 2. Riskiest Runtime Simplification
Running evaluations synchronously on the main thread. While simple, if users define custom expanders that perform slow, CPU-heavy math, it can block the event loop and drop frames. This is mitigated by hard-coded default limits (`maxNodes = 100`, `timeoutMs = 16ms`).

### 3. Deferred Runtime Systems Most Likely Needed Later
**Isolate Worker Pools**. Essential to offload evaluations to background isolates if search trees grow larger in subsequent releases.

### 4. Runtime Areas Most Vulnerable to Instability
Custom expander call exceptions. If user-defined expansion plugins crash, the engine must isolate the failure and recover gracefully.

### 5. Recommended Next Planning Document
`docs/core/implementation_plan.md` to define the developer task list for building the v0.1.0 codebase.
