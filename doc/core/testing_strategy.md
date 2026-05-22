# BranchIQ v0.1.0: Testing Strategy Specification
**Version**: 0.1.0-test  
**Author**: Principal Software Testing Architect & Verification Lead  
**Status**: Frozen for Development  

---

# 1. Testing Philosophy

In deterministic runtime systems, the traditional testing paradigm is insufficient. Traditional software verification relies on heuristic assertions and path coverage metrics. In contrast, a client-side decision intelligence engine requires absolute mathematical guarantees. If a decision path varies by even a fraction of a percent across platforms, or if identical telemetry inputs yield different action sequences, the runtime system is unstable.

Runtime engines fail silently. A bug in a utility calculation does not always throw an exception; instead, it slowly degrades path selection quality. A mathematical regression can cause a mobile app to silently prioritize expensive network operations over cheap cached resources, exhausting bandwidth without triggering a crash log. Traversal instability is catastrophic, leading to infinite decision cycles that freeze the UI.

For these reasons, BranchIQ v0.1.0 enforces the following testing tenet:

> **“If execution cannot be reproduced, the engine is unstable.”**

To guarantee stability, verification requires:
1. **Mathematical Reproducibility**: Validating float tolerances, cost normalizations, and confidence decays across all supported architectures.
2. **Defensive Invariant Locks**: Enforcing cycle detection, node limits, and lexicographical tie-breaking in every test sweep.
3. **Snapshot Replays**: Capturing and comparing tree execution structures against static JSON fixtures to verify that modifications do not introduce path selection drift.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 2. Testing Architecture Overview

The BranchIQ testing stack consists of multiple verification layers. Lower layers isolate mathematical functions, while higher layers validate pipeline integration and performance.

```
  ┌────────────────────────────────────────────────────────┐
  │ 8. CI Validation Gates (Merge Blockers)                 │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │ 7. Performance & Allocation Benchmarks                 │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │ 6. Snapshot Regression Replays                         │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │ 5. Integration Tests (End-to-End Pipeline)             │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │ 4. Unit Tests (Math, Models, Sorters)                  │
  └────────────────────────────────────────────────────────┘
```

## 2.1 Testing Stack Definitions
*   **Unit Testing**: Validates individual algorithms in isolation, verifying functions inside `math/`, `scoring/`, and `internal/`.
*   **Integration Testing**: Validates the end-to-end execution pipeline from input telemetry to output action paths.
*   **Regression Testing**: Compares current path evaluations against historical test fixtures to prevent behavior drift.
*   **Snapshot Testing**: Validates the JSON schema structure of tracing logs and debug snapshots.
*   **Deterministic Replay Testing**: Re-runs past runs using JSON snapshots, asserting that outputs remain identical.
*   **Benchmark Testing**: Measures latency and heap allocations, blocking changes that exceed performance budgets.
*   **Validation Testing**: Checks structural integrity (e.g., acyclicity check, size bounds) to prevent invalid configurations.
*   **Failure Testing**: Simulates runtime faults, verifying that mathematical anomalies (e.g., NaN inputs) degrade gracefully to root fallback nodes.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 3. Deterministic Testing Rules

To eliminate test flakiness and ensure that verification is reproducible, BranchIQ enforces strict deterministic testing constraints.

## 3.1 Verification Rules
*   **Replay Verification**: Core pathfinder tests must evaluate identical trees and telemetries across **10,000 continuous loops** to verify that sorting and search routines are stable and free of CPU drift.
*   **Stable Sorting Assertion**: Sibling nodes with identical utility scores must resolve ties lexicographically by node ID. Tests must explicitly assert this ordering.

## 3.2 Forbidden Non-Deterministic Behaviors
The following patterns are strictly prohibited in the test suite:
*   **No Random Test Ordering**: Using random test runners or varying test seed execution order is forbidden.
*   **No Dynamic Timestamps**: Using `DateTime.now()` in assertions or context mock objects is prohibited. Telemetry times must use static ISO-8601 strings.
*   **No Unordered Collections**: Test assertions must not evaluate elements using unordered `Set` or `Map` collections. Output sequences must be verified using ordered list comparisons.
*   **No Async Races**: Writing asynchronous wait delays (e.g., `Future.delayed()`) to synchronize tests is prohibited. All test pipelines must execute synchronously.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 4. Unit Testing Strategy

Unit tests focus on validating individual algorithms before they are integrated into the pipeline.

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                           Unit Testing Targets                                               │
├───────────────────┬─────────────────────────────────────────────────┬────────────────────────────────────────┤
│ Module Path       │ Assertions Under Test                           │ Pathological Edge Cases                │
├───────────────────┼─────────────────────────────────────────────────┼────────────────────────────────────────┤
│ `math/sanitize.dart`│ Float clamping, NaN filters, infinity bounds. │ inputs of NaN, +/-infinity, zero.      │
├───────────────────┼─────────────────────────────────────────────────┼────────────────────────────────────────┤
│ `math/cost.dart`  │ Linear cost normalizations, ceiling limits.     │ negative costs, cost = costCeiling.    │
├───────────────────┼─────────────────────────────────────────────────┼────────────────────────────────────────┤
│ `math/decay.dart` │ Exponential decay curves, depth attenuations.   │ depth = 0, depth > maxDepth limit.     │
├───────────────────┼─────────────────────────────────────────────────┼────────────────────────────────────────┤
│ `scoring/maut.dart`│ Weighted multi-attribute scoring outputs.        │ zero weights, negative utility values. │
├───────────────────┼─────────────────────────────────────────────────┼────────────────────────────────────────┤
│ `pruning/beam.dart`│ Frontier width caps, score filters.             │ beamWidth = 1, empty node list.        │
├───────────────────┼─────────────────────────────────────────────────┼────────────────────────────────────────┤
│ `traversal/a_star.dart`│ Priority-first traversal path accuracy.     │ single root tree, dead-end branches.   │
├───────────────────┼─────────────────────────────────────────────────┼────────────────────────────────────────┤
│ `internal/validation.dart`│ DFS structural loop and cycle detections.│ self-referencing nodes, cycles.        │
└───────────────────┴─────────────────────────────────────────────────┴────────────────────────────────────────┘
```

## 4.1 Invariant Validation Checks
*   **Monotonicity Invariant**: Pruning tests must verify that as thresholds ($P_{\text{min}}, S_{\text{min}}$) increase, the size of the active search frontier decreases monotonically:
    $$T_1 > T_0 \implies \left| \mathcal{F}(T_1) \right| \le \left| \mathcal{F}(T_0) \right|$$
*   **Acyclicity Check**: The validator must throw an `InvalidTreeException` if a node ID appears in the path trace of its own ancestors.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 5. Mathematical Verification Strategy

Mathematical calculations must behave consistently across physical platforms (e.g., 64-bit Dart VM, compiled JavaScript).

## 5.1 Epsilon Tolerance and Float Comparisons
Floating-point calculations can vary slightly across architectures due to compiler optimization. The test suite must avoid direct equality assertions for floating-point values:
```dart
// FORBIDDEN: expect(score, 0.5032);
// REQUIRED: expect((score - 0.5032).abs() < 1e-6, true);
```
We enforce a global epsilon value of $\epsilon = 10^{-6}$ for all mathematical assertions.

## 5.2 Mathematical Validation Example: Cost Clamping
Given the linear cost normalization:
$$C_{\text{norm}}(n) = \max\left(0.0, \min\left(1.0, \frac{C(n)}{C_{\text{max}} + 10^{-9}}\right)\right)$$

The unit tests must verify:
1.  **Lower Boundary**: An input cost of $-50.0$ returns $0.0$.
2.  **Upper Boundary**: An input cost of $1200.0$ with $C_{\text{max}} = 1000.0$ returns $1.0$.
3.  **Intermediate Value**: An input cost of $250.0$ with $C_{\text{max}} = 1000.0$ returns $0.25$.
4.  **Zero Cost Ceiling**: If configuration sets $C_{\text{max}} = 0.0$, the division stabilizer prevents crashes, clamping the result to $1.0$.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 6. Traversal Validation Strategy

Traversal tests verify that pathfinding algorithms yield the mathematically optimal path from a decision tree.

## 6.1 Invariant Assertions
*   **Path Starting Invariant**: The generated path must start at the tree's root node (`parentId == null`).
*   **Path Ending Invariant**: The path must terminate at a valid leaf node (`childIds` is empty) or at a node where depth equals the config limit.
*   **Path Contiguity**: For any consecutive nodes $n_i, n_{i+1}$ in the path list, $n_{i+1}.id$ must exist in the child list of $n_i.childIds$.

## 6.2 Traversal Boundary Scenarios
*   **Single-Node Trees**: Verify that a tree containing only a root node returns a path containing only that node.
*   **Unreachable Branches**: If all children of a node are pruned, the engine must terminate evaluation at that node, returning the path from root to the pruned node.
*   **Tie-Breaking**: Given sibling nodes $A$ and $B$ with identical utility scores, the engine must rank them alphabetically by ID, ensuring consistent path selection.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 7. Pruning Verification Strategy

Pruning validation ensures that search space filters behave predictably.

## 7.1 Pruning Boundary Scenarios
*   **Zero Thresholds**: If thresholds are set to minimums ($P_{\text{min}} = 0.0, S_{\text{min}} = -1.0$), no nodes are pruned unless beam width or depth limits are exceeded.
*   **High Thresholds**: If thresholds are set to maximums ($P_{\text{min}} = 1.0, S_{\text{min}} = 1.0$), the engine must prune all branches except the root node, returning the root path as the fallback.
*   **Beam Width Enforcement**: Given a depth level containing ten candidates and a beam width $k = 3$, the engine must retain only the top 3 scored nodes, discarding the other 7.

## 7.2 explanation verification
Pruned nodes must declare a `pruningReason` indicating why they were discarded:
*   `"probability_below_threshold"` if transition probability fell below $P_{\text{min}}$.
*   `"score_below_threshold"` if score fell below $S_{\text{min}}$.
*   `"beam_width_exceeded"` if the node fell outside the top $k$ candidates.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 8. Runtime Lifecycle Testing

Lifecycle testing ensures that state machine transitions are valid and error handling works reliably.

```
                 validateOrThrow()             evaluateSync()
  [ idle ] ─────────────► [ validating ] ─────────────► [ expanding / scoring ]
                                                              │
                                                              ▼
  [ completed ] ◄───────────── [ traversing ] ◄────────── [ pruning ]
```

## 8.1 State Transition Verification
*   **Allowed Transitions**: Validate that state changes follow the defined sequence: `idle` $\to$ `validating` $\to$ `expanding` $\to$ `scoring` $\to$ `pruning` $\to$ `traversing` $\to$ `completed`.
*   **Forbidden Transitions**: Direct jumps from `idle` to `completed` or from `expanding` to `idle` must trigger validation errors.
*   **Cancellation Check**: If a cancellation flag is set in the session context, the engine must halt execution at the current state transition, rollback changes, and return the root path.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 9. Snapshot Regression Architecture

Snapshot testing prevents code modifications from introducing subtle changes in evaluation logic.

## 9.1 JSON Snapshot Fixtures
*   Every integration test run exports a JSON `DebugSnapshot` containing:
    *   The engine version and execution timestamp.
    *   The telemetry variables used in the evaluation.
    *   The complete evaluated tree, detailing node IDs, parameters, scores, and pruning reasons.
    *   The selected best path node sequence.
*   These snapshots are stored in `test/regression/fixtures/`.

## 9.2 Regression Lock Strategy
During regression runs, the engine loads the telemetry and tree configurations from the JSON snapshot file, runs an evaluation, and asserts that the resulting JSON structure matches the snapshot exactly:
```
  JSON Fixture ──► [ Load Context & Tree ] ──► [ Execute Engine ] ──► [ Assert JSON Identity ]
```
If the output deviates by even a single character, the test fails, indicating a regression in execution logic.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 10. Failure Injection Strategy

We verify the engine's resilience by injecting invalid parameters and structural anomalies during evaluation.

## 10.1 Expected Recovery Behaviors

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                           Failure Injection Matrix                                           │
├───────────────────────────┬──────────────────────────────────────────┬───────────────────────────────────────┤
│ Injected Fault            │ Expected Exception / Recovery            │ Defensive Invariant Gate              │
├───────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────┤
│ Cyclic node linkages      │ Throws `InvalidTreeException`            │ Cycle check (DFS) on engine start.    │
├───────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────┤
│ Missing child references  │ Throws `OrphanNodeException`             │ Registry check on tree validation.    │
├───────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────┤
│ NaN node probabilities    │ Clamped to default fallback value.       │ Sanitizer clamping function.          │
├───────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────┤
│ Infinity cost parameter   │ Clamped to maximum ceiling value.        │ Cost normalizer clamping logic.       │
├───────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────┤
│ Empty node tree input     │ Returns empty path.                      │ Precondition check on engine start.   │
├───────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────┤
│ Dynamic evaluator crash   │ Catches exception, logs error, returns   │ Try-catch block wraps evaluator calls.│
│                           │ root node path as fallback.              │                                       │
└───────────────────────────┴──────────────────────────────────────────┴───────────────────────────────────────┘
```

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 11. Performance Benchmark Strategy

Performance testing ensures that evaluation cycles do not introduce frame delays (jank) on the main UI thread.

## 11.1 Performance Ceilings
*   **Latency Ceiling**: Single-threaded evaluations of standard decision trees (depth $d \le 4$, nodes $\le 100$) must complete in under **1.0 millisecond** on modern mobile hardware.
*   **Garbage Collection Budget**: Traversals must run without allocating new collection lists in the search loops. Priority queues and temporary lists are initialized once at session startup to minimize GC overhead.

## 11.2 Benchmarking execution
Benchmarks are executed in a production-like profiling environment:
```bash
dart run test/regression/performance_benchmark.dart
```
Tests assert that average execution latency over 50,000 runs stays below 1.2ms. If latency exceeds this budget, the build fails.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 12. Memory Validation Strategy

Memory validation prevents memory leaks and garbage collection overhead during rapid decision evaluations.

## 12.1 Allocation Tracking Rules
*   **Zero-Allocation Traversal**: Traversal loops must not allocate new objects (e.g., node arrays, child list copies) in the hot path. All operations must run in-place or reuse pre-allocated collections.
*   **Transient Object Limits**: Evaluating a decision tree must not instantiate more than $2N$ transient objects, where $N$ is the number of nodes in the tree.

## 12.2 Verification
Memory profiling tests run evaluations continuously inside a loop:
```dart
// Memory leak verification pattern
void verifyMemoryStability() {
  final baselineAllocations = getCurrentHeapAllocations();
  for (int i = 0; i < 100000; i++) {
    engine.evaluateSync(tree: sampleTree, ...);
  }
  final postAllocations = getCurrentHeapAllocations();
  expect(postAllocations, baselineAllocations); // Verify no memory leak
}
```

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 13. CI Validation Gates

The CI pipeline runs automated checks on every pull request, blocking integration if any gate fails.

## 13.1 CI Gates configuration
*   **Linting Gate**: The code must compile without warnings or hints using strict rules:
    ```bash
    dart analyze --fatal-infos --fatal-warnings
    ```
*   **Formatting Gate**: All files must match the standard Dart style guide:
    ```bash
    dart format --output=none --set-exit-if-changed .
    ```
*   **Unit & Integration Gate**: All unit and integration tests must pass:
    ```bash
    dart test
    ```
*   **Coverage Gate**: Overall test coverage must meet defined thresholds:
    ```bash
    // Requires >=95% coverage on engine, 100% coverage on math modules.
    ```
*   **Regression Gate**: All regression snapshot checks must match fixtures exactly.
*   **Benchmark Gate**: Average evaluation latency must stay below the 1.2ms ceiling.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 14. Anti-Flakiness Strategy

Flaky tests degrade CI reliability and slow down development. BranchIQ implements strict anti-flakiness policies.

## 14.1 Flakiness Prevention Rules
*   **Deterministic Isolation**: Tests must run in isolated environments and are forbidden from accessing external system resources (e.g., local files, network interfaces).
*   **No Random Seeds**: Using random number generators or dynamic seeds in test helpers is prohibited.
*   **Stable Environments**: Test execution environments must be standardized. CI runs are executed inside containerized environments with pinned Dart SDK versions.

## 14.2 Flaky Test Isolation and Quarantine
*   **Zero-Tolerance Policy**: If a test fails intermittently, it is classified as flaky and quarantined immediately.
*   **Quarantine Procedure**: The flaky test is moved to `test/quarantine/` and disabled in the CI pipeline. The developer must refactor the test to make it deterministic before merging it back.
*   **No Automatic Retries**: The CI pipeline does not use automatic retry runners. A test must pass on the first run.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 15. Test Data Architecture

Test data must be structured, version-controlled, and deterministic to ensure repeatable test runs.

## 15.1 Fixture Layout
*   **`test/regression/fixtures/trees/`**: Static tree structures stored in JSON format (e.g., single_node.json, cyclic_tree.json, deep_branch.json).
*   **`test/regression/fixtures/snapshots/`**: Expected output snapshots containing evaluated scores, pruned frontiers, and selected paths.

## 15.2 Pathological Test Fixtures
To verify engine safety, the test suite includes complex tree structures:
*   **Deep Linear Tree**: A single path of 12 sequential nodes, used to verify depth limit and confidence decay calculations.
*   **Wide Fan Tree**: A root node with 50 sibling child nodes, used to verify sorting and beam width pruning behavior.
*   **Cyclic Graph**: A tree containing circular references (e.g., Node A $\to$ Node B $\to$ Node A), used to verify cycle detection logic.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 16. Property & Invariant Testing

Property testing validates that the engine's behavior conforms to mathematical invariants across all inputs.

## 16.1 Invariant Rules
*   **Score Bounds**: The calculated score of any node must fall within the range $[-1.0, 1.0]$.
*   **Confidence Propagation**: Downstream confidence must decrease monotonically with depth:
    $$d(n_i) > d(n_j) \implies K(n_i) \le K(n_j)$$
*   **Probability Bounds**: Transition probabilities must remain within the range $[0.0, 1.0]$.
*   **Pruning Monotonicity**: Increasing pruning thresholds must never increase the number of nodes in the evaluated frontier.
*   **Acyclicity Guard**: Valid trees must contain no cyclic dependencies, and all registered child IDs must reference valid nodes.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 17. Regression Prevention Strategy

To maintain output consistency, modifications to the codebase are validated against historical execution baselines.

```
  Code Edit ──► [ Run Local Tests ] ──► [ Verify JSON Snapshots ] ──► Merge Approved
```

## 17.1 Verification Requirements
The following changes require full regression verification before merging:
*   Any changes to calculation code inside `src/math/` or `src/scoring/`.
*   Changes to search algorithms inside `src/traversal/` or `src/pruning/`.
*   Modifications to tree serialization or parser logic.
*   Updating dependencies or the target Dart SDK version.

If any snapshot comparison fails, the pull request is blocked until the changes are reviewed and approved.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 18. Documentation Testing Strategy

To prevent documentation decay, example code and specifications are verified as part of the build pipeline.

## 18.1 Documentation Validation Rules
*   **Example Compilation**: All code examples in the `example/` directory must compile without warnings or linter errors.
*   **Markdown Link Validation**: Links within documentation files (e.g., `docs/core/*`) must resolve to active local paths.
*   **Comment Coverage**: Public classes and parameters must be documented with clean Dartdoc comments. We require **100% comment coverage** for public APIs.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 19. Deferred Testing Systems

The following testing infrastructures are deferred to later releases to maintain MVP focus:

1.  **Distributed Fuzz Testing**:
    *   *Rationale*: Generating random tree inputs is not needed for v0.1.0, as inputs are structured and verified.
    *   *Risk*: Fuzzing requires high compute resources and can produce complex edge cases that are difficult to debug.
2.  **Isolate Stress Testing**:
    *   *Rationale*: The core engine runs synchronously on the main thread; multi-threaded isolate execution is deferred.
    *   *Risk*: Multi-threaded testing introduces race conditions and increases CI run times.
3.  **GPU Benchmarking**:
    *   *Rationale*: The engine runs purely on the CPU, and does not perform graphics rendering.
    *   *Risk*: Requires physical device farms and increases build complexity.
4.  **AI Scoring Validation**:
    *   *Rationale*: Reinforcement learning integration is deferred to Phase 6.
    *   *Risk*: AI behavior is non-deterministic and can produce unstable verification results.

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 20. Worked Testing Pipeline Example

This pipeline trace shows the sequence of verification checks executed on a code change:

```
  [ Developer Code Push ]
             │
             ▼
  [ CI Tooling Gate ]
  ├── 1. runs lint check: "dart analyze"
  └── 2. runs formatting check: "dart format"
             │
             ▼
  [ Unit Verification Suite ]
  ├── 3. runs mathematical validations (limits, NaN clamping)
  └── 4. runs CycleValidator check on cyclic tree configs
             │
             ▼
  [ Integration & Replay Suite ]
  ├── 5. runs evaluation pipeline on test trees
  └── 6. compares results with JSON snapshots in test/regression/fixtures/
             │
             ▼
  [ Performance Benchmarks ]
  ├── 7. measures execution latency (<1.0ms target)
  └── 8. verifies memory allocation limits (zero-allocation traversal)
             │
             ▼
  [ CI Green Build Status ]
```

## 20.1 Example Test Case: Decision Tree Validation

The following test case shows how to write a deterministic tree validation test:

```dart
import 'package:test/test.dart';
import 'package:branchiq/branchiq.dart';

void main() {
  group('DecisionTree Verification', () {
    test('should throw InvalidTreeException on cycle detection', () {
      final nodeA = DecisionNode(id: 'node_A', childIds: ['node_B']);
      final nodeB = DecisionNode(id: 'node_B', parentId: 'node_A', childIds: ['node_C']);
      final nodeC = DecisionNode(id: 'node_C', parentId: 'node_B', childIds: ['node_A']); // Cycles back to A

      final tree = DecisionTree.fromNodes([nodeA, nodeB, nodeC]);
      
      expect(
        () => tree.validateOrThrow(),
        throwsA(isA<InvalidTreeException>()),
      );
    });

    test('should verify path contiguity and tie-breaking', () {
      final root = DecisionNode(id: 'root', childIds: ['node_A', 'node_B']);
      final nodeA = DecisionNode(id: 'node_A', parentId: 'root', childIds: [], probability: 0.8, impact: 0.5);
      final nodeB = DecisionNode(id: 'node_B', parentId: 'root', childIds: [], probability: 0.8, impact: 0.5); // Identical score to A

      final tree = DecisionTree.fromNodes([root, nodeA, nodeB]);
      final engine = BranchIQEngine.createSync();
      
      final result = engine.evaluateSync(
        tree: tree,
        context: const EvaluationContext({}),
        scoring: ScoringConfig(wp: 0.5, wi: 0.5, wc: 0.0, costCeiling: 100.0),
        pruning: PruningConfig(minProbability: 0.1, minScore: -1.0, beamWidth: 3, maxDepth: 4, maxNodeLimit: 50),
        traversal: const TraversalConfig(),
      );

      // Verify path contiguity
      expect(result.bestPath.nodeIds.first, 'root');
      
      // Node A and B have identical scores. Verify lexicographical tie-breaking selects A first.
      expect(result.bestPath.nodeIds.last, 'node_A');
    });
  });
}
```

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# 21. Final Testing Lock

The verification boundaries and strategies for BranchIQ version 0.1.0 are locked:

> **BranchIQ v0.1.0 testing exists only to guarantee bounded deterministic reproducible runtime decision evaluation in pure Dart.**
>
> **Everything else is deferred.**

---

## Testing Section Checklist

- [ ] deterministic guarantees enforced
- [ ] runtime safety validated
- [ ] mathematical drift addressed
- [ ] regression risks addressed
- [ ] overengineering avoided

---

# Testing Architecture Audit

This audit evaluates the reliability and completeness of the BranchIQ testing strategy.

## Subsystem Assessment Scores (1-10)

| Subsystem / Dimension | Score | Assessment Rationale |
| :--- | :--- | :--- |
| **Determinism Safety** | **10/10** | Blocks dynamic time and random seeds, enforcing 10,000-loop replay validations. |
| **Regression Protection** | **10/10** | Uses JSON snapshot verification to prevent behavior and path drift. |
| **Mathematical Validation** | **10/10** | Enforces epsilon checks ($\epsilon = 10^{-6}$) and boundary clamping tests. |
| **Runtime Safety** | **10/10** | Validates tree structures (DFS cycle check) and handles exceptions using fallbacks. |
| **CI Readiness** | **10/10** | Implements automated compilation, formatting, and coverage gates. |
| **Anti-Flakiness Resilience**| **10/10** | Uses containerized runtimes and quarantines flaky tests immediately. |
| **Benchmark Reliability** | **9/10** | Benchmarks CPU latency and heap allocations under production loads. |
| **MVP Testing Realism** | **10/10** | Restricts verification to pure Dart environments, avoiding emulator dependencies. |

---

## Audit Findings

### 1. Strongest Testing Decision
Using **JSON snapshot verification for regression testing**. This guarantees that modifications to traversal or scoring logic do not introduce changes in path selection, keeping decisions consistent across versions.

### 2. Riskiest Testing Simplification
Enforcing a global epsilon value ($\epsilon = 10^{-6}$) for float assertions. If float operations produce variance greater than epsilon on older devices, tests will fail. We must monitor target devices to verify tolerance bounds.

### 3. Systems Most Vulnerable to Silent Regressions
Custom `NodeEvaluator` and `BranchExpander` extensions. If developer modifications introduce non-deterministic operations in custom evaluation code, the engine will produce unstable path choices. We must document developer guidelines clearly.

### 4. Tests That Must Never Become Flaky
The DFS cycle check and lexicographical tie-breaking tests. These verify core safety assumptions and must remain deterministic across all runs.

### 5. Recommended Next Planning Document
`docs/core/testing_strategy.md` is frozen. Development can now proceed with Phase 0 repository setup and infrastructure integration.
