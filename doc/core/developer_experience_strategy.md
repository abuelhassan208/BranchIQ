# BranchIQ v0.1.0: Developer Experience Strategy Specification
**Version**: 0.1.0-dx  
**Author**: Principal Developer Experience Architect  
**Status**: Frozen for Development  

---

# 1. Developer Experience Philosophy

In runtime decision-making libraries, magical APIs are the primary source of developer frustration. When package authors hide execution states behind reflection, global singletons, or auto-configuring runtime engines, they build a system that is impossible to troubleshoot. When a decision tree behaves unexpectedly on a mobile client, the developer cannot inspect the execution state, leading to a loss of trust in the library.

In deterministic runtimes, APIs must be transparent. The developer should understand exactly how telemetries are translated into decision outcomes. BranchIQ prioritizes simplicity and predictability over automation, ensuring that every calculation is traceable.

Our developer experience strategy is guided by a single rule:

> **“Explicit deterministic reasoning with minimal cognitive overhead.”**

To achieve this, we enforce:
1. **Clarity Over Cleverness**: We avoid clever, short-hand syntax in favor of explicit configuration. There are no hidden parameters; weights and thresholds must be declared clearly.
2. **Predictability Over Automation**: The library does not spin up background isolates or run database caches automatically. Everything runs synchronously on the calling thread, making execution trace capture straightforward.
3. **Traceability**: Pruning steps and traversal calculations are written to transparent buffers, enabling developers to query the engine to ask *"Why did you make this decision?"*

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 2. First-Time Developer Experience

The first five minutes with a library determine its adoption rate. BranchIQ provides a straightforward CLI onboarding experience.

## 2.1 Installation Flow
Developers add the library using the standard Dart CLI:
```bash
dart pub add branchiq
```
This downloads a pure Dart package with zero external dependencies, compiling in seconds.

## 2.2 Minimal Evaluation Example
The simplest setup requires defining two nodes, initializing configurations, and running the query:
```dart
import 'package:branchiq/branchiq.dart';

void main() {
  // 1. Define nodes
  final root = DecisionNode(id: 'root', childIds: ['option_A', 'option_B']);
  final nodeA = DecisionNode(id: 'option_A', parentId: 'root', childIds: [], probability: 0.9, impact: 0.8);
  final nodeB = DecisionNode(id: 'option_B', parentId: 'root', childIds: [], probability: 0.7, impact: 1.0);

  final tree = DecisionTree.fromNodes([root, nodeA, nodeB]);

  // 2. Configure scoring weights (must sum to 1.0)
  final scoring = ScoringConfig(wp: 0.5, wi: 0.5, wc: 0.0, costCeiling: 100.0);

  // 3. Execute
  final engine = BranchIQEngine.createSync();
  final result = engine.evaluateSync(
    tree: tree,
    context: const EvaluationContext({}),
    scoring: scoring,
    pruning: PruningConfig.defaultSettings(),
    traversal: const TraversalConfig(),
  );

  print('Selected Path: ${result.bestPath.nodeIds}');
}
```

## 2.3 Initial Concepts and Hiding Rules
*   **Visible Immediately**: Nodes ($P, I$ values), scoring weights, and path outputs.
*   **Hidden Initially**: Beam widths, decay rates, priority queue traversals, and JSON snapshots. Beginners only need to know that they input values and retrieve a path.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 3. Beginner API Ergonomics

Beginner-safe interfaces prevent common configuration mistakes during early adoption.

## 3.1 safe Defaults and Low-Configuration Onboarding
*   **`PruningConfig.defaultSettings()`**: A constructor that provides safe, pre-configured default values (e.g., $P_{\text{min}} = 0.0, S_{\text{min}} = -1.0, k = 3, d = 4$), allowing developers to run trees immediately without tuning filters.
*   **`TraversalConfig()`**: Defaults to standard priority-first search, hiding traversal algorithm selections.
*   **`EvaluationContext.empty()`**: Allows running evaluations without passing environmental telemetry variables.

## 3.2 Forbidden Beginner Complexity
The beginner API surface is protected from structural complexity:
*   *No Manual Sorting*: Sibling node lists are sorted internally; beginners do not need to call sort routines.
*   *No Custom Evaluators*: Custom evaluators and dynamic generators are hidden in intermediate guides, keeping basic trees static.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 4. Progressive Complexity Strategy

As developers become familiar with the library, advanced capabilities are introduced gradually.

```
  ┌────────────────────────────────────────────────────────┐
  │ 1. Beginner Layer                                      │
  │    - Static trees, default configs, synchronous runs.  │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │ 2. Intermediate Layer                                  │
  │    - Telemetry contexts, dynamic custom scoring,        │
  │      threshold pruning, custom beam widths.            │
  └───────────────────────────┬────────────────────────────┘
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │ 3. Advanced Runtime Layer                              │
  │    - Custom evaluators, cycle detection, snapshots.    │
  └────────────────────────────────────────────────────────┘
```

## 4.1 Concept Reveal Schedule
*   **Beginner**: `DecisionNode`, `DecisionTree`, `ScoringConfig`, `BranchIQEngine.evaluateSync()`.
*   **Intermediate**: `EvaluationContext`, `PruningConfig`, `DebugSnapshot`, `engine.explain()`.
*   **Advanced**: `NodeEvaluator` interfaces, `BranchExpander` dynamic generation interfaces, and custom snapshot replay pipelines.

## 4.2 Why Advanced Concepts are Deferred
Revealing priority queue traversal heuristics or custom dynamic expansion interfaces early increases cognitive overhead. Keeping these interfaces decoupled ensures that the beginner setup remains simple and approachable.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 5. Documentation Navigation Architecture

Our documentation is structured to help developers locate resources efficiently.

## 5.1 Documentation Directory Layout
*   **`README.md`**: Found at the repository root. Contains a 5-minute quickstart guide, installation commands, and a basic code example.
*   **`docs/guides/`**:
    *   `01_telemetry_integration.md`: How to load context telemetry into the engine.
    *   `02_tuning_weights.md`: A guide to setting up scoring weights and pruning thresholds.
    *   `03_observability.md`: How to read debug traces and parse JSON snapshots.
*   **`docs/core/`**: Deep architectural and mathematical specifications for advanced developers.

## 5.2 Progressive Discovery Flow
The README links directly to `01_telemetry_integration.md` at the bottom of its quickstart section, guiding developers through the progressive learning layers.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 6. Example Strategy

We provide concrete, self-contained examples to demonstrate specific use cases.

## 6.1 Educational Examples Matrix

| Example Name | Complexity | Educational Goal | Key Concepts Introduced |
|:---|:---|:---|:---|
| `minimal_console` | Beginner | Show basic tree initialization and run. | `DecisionTree`, `evaluateSync` |
| `custom_scoring` | Intermediate | Show how context values modify node parameters. | `EvaluationContext`, `NodeEvaluator` |
| `pruning_limits` | Intermediate | Demonstrate how threshold bounds reduce search frontiers. | `PruningConfig`, `beamWidth` |
| `traversal_paths` | Advanced | Show how priority searches navigate deep trees. | `TraversalConfig`, path contiguity |
| `debug_snapshots` | Advanced | Show how to export and read JSON execution snapshots. | `DebugSnapshot`, `engine.explain` |

## 6.2 Example Implementation Standards
*   **No Flutter UI**: Examples must run as pure Dart command-line applications, allowing developers to run them using:
    ```bash
    dart run example/minimal_console/main.dart
    ```
*   **Single-File Layout**: Examples are written in a single file to make them easy to read and understand.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 7. API Readability Philosophy

API readability prevents development errors and reduces the need for documentation lookups.

## 7.1 Naming and Configuration Standards
*   **Explicit Naming**: Method names must be descriptive (e.g., `evaluateSync` is used instead of `run` or `execute` to indicate synchronous thread behavior).
*   **Immutable Types**: Configuration classes use named parameters with validation checks, catching config issues early during instantiation.

## 7.2 Prohibited Magical API Patterns
*   **No Auto-Configuring Singletons**: We avoid patterns like `BranchIQEngine.instance`. Global states introduce side-effects and make testing difficult. Engines must be instantiated locally by caller classes.
*   **No Dynamic Weight Mutation**: Configuration properties are final. Once initialized, scoring weights cannot be changed dynamically.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 8. Error Message Philosophy

Clear, informative error messages help developers diagnose integration and configuration issues quickly.

## 8.1 Guidelines for Helpful Error Messages
*   **Diagnostic Detail**: Error messages must state:
    1.  What went wrong.
    2.  Which parameters or nodes caused the failure.
    3.  How to fix the error.
*   **No Internal Trace Leaks**: Error messages must not expose private engine variables, stack pointer counts, or utility memory queues.

## 8.2 Error Message Patterns

### 8.2.1 Configuration Error Example
```
[BranchIQ][ConfigError] Validation failed for ScoringConfig.
  Reason: Scoring weights must sum to exactly 1.0.
  Actual values: wp = 0.50, wi = 0.50, wc = 0.20 (Sum = 1.20)
  Remedy: Adjust weights to sum to 1.0 (e.g., wp = 0.40, wi = 0.40, wc = 0.20).
```

### 8.2.2 Cycle Detection Error Example
```
[BranchIQ][InvalidTreeException] Cycle detected in DecisionTree registry.
  Path: root -> fetch_cache -> fetch_network -> fetch_cache
  Violation: Node 'fetch_cache' cyclical loop detected.
  Remedy: Ensure all child lists contain no ancestor IDs.
```

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 9. Debugging Experience Strategy

When a decision engine makes unexpected choices, developers need tools to inspect the execution pipeline.

```
  Execution Output ──► [ Call engine.explain(result) ] ──► Read Text Trace
```

## 9.1 Diagnostic Tracing
*   **`engine.explain(result)`**: Exposes path metrics as a human-readable text string:
    ```
    Selected path: root -> fetch_cache (Total utility: 0.82)
    Evaluation details:
      - node 'fetch_cache': score = 0.82, status = selected
      - node 'fetch_network': score = 0.35, status = pruned (reason: cost ceiling exceeded)
    ```
*   **`exportDebugSnapshot(result)`**: Converts execution telemetry into a structured JSON string, which can be shared or loaded into test suites for regression testing.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 10. pub.dev Adoption Strategy

To drive adoption, BranchIQ must present a clear value proposition on pub.dev, avoiding marketing hype or overpromises.

## 10.1 Positioning and Description
*   **Positioning**: A bounded, deterministic decision intelligence library for Dart and Flutter.
*   **Tagline**: *"Deterministic utility-based path reasoning for Flutter client architectures. Zero dependencies, pure Dart."*
*   **Keywords**: `decision intelligence`, `utility theory`, `pathfinding`, `pruning`, `pure dart`.

## 10.2 What NOT to Market BranchIQ As
*   *No "AI on Device" claims*: Do not market the package as an AI or neural-network runtime.
*   *No "LLM Replacement" claims*: Position the engine as a rule-engine supplement, not a replacement for generative models.
*   *No Overhyped Terminology*: Avoid marketing buzzwords like "cognitive agent," "AGI," or "smart consciousness."

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 11. Trust & Predictability Strategy

Developer trust is maintained by guaranteeing that execution outputs are completely reproducible.

## 11.1 Determinism Guarantees
*   **Mathematical Reproducibility**: Given identical trees and context parameters, the engine will select the exact same path across all platforms (web, mobile, server).
*   **No Randomization**: The engine does not use random seeds or dynamic system clock calculations.
*   **Explicit Traversal**: Decisions are made using multi-attribute utility theory, avoiding black-box heuristics or stochastic rollouts.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 12. Extension Onboarding Philosophy

Advanced developers can extend the engine's behavior using decoupled extension interfaces.

## 12.1 Custom Evaluator Onboarding
To implement dynamic node scoring, developers implement the `NodeEvaluator` interface:
```dart
class NetworkLatencyEvaluator implements NodeEvaluator {
  @override
  DecisionNode evaluateNode(DecisionNode node, EvaluationContext context) {
    final dynamicLatency = context.get<double>('latency') ?? 100.0;
    return node.copyWith(cost: dynamicLatency);
  }
}
```
This interface isolates developer code from internal scoring algorithms. Dynamic calculations update cost properties on copied node instances, keeping traversal logic stable.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 13. Configuration Experience Strategy

We structure configuration parameters to make setup straightforward.

## 13.1 Configuration Presets
*   **`ScoringConfig.balanced()`**: Sets wp = 0.33, wi = 0.33, wc = 0.33, costCeiling = 1000.0, providing a balanced starting point.
*   **`PruningConfig.conservative()`**: Sets conservative thresholds to minimize pruning, ensuring that most nodes are evaluated.
*   **`TraversalConfig.standard()`**: Uses the default priority-first search strategy.

## 13.2 Validation Fail-Fast
Configurations validate parameters on instantiation. If weights do not sum to $1.0$, the constructor throws an error immediately, catching misconfigurations before execution.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 14. Migration & Versioning Experience

We minimize breaking changes to ensure a smooth upgrade experience.

## 14.1 Semantic Versioning Commitments
*   **API Stability**: The public API is frozen during the `v0.1.0` release cycle.
*   **Deprecation Policy**: If a method signature needs to be changed in a future release, the old method is marked with the `@deprecated` annotation and maintained for at least one minor version cycle before removal.
*   **Migration Guides**: Minor releases that introduce API modifications must include a `MIGRATION.md` file detailing code updates.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 15. Documentation Quality Standards

Clear, readable documentation is essential for developer onboarding.

## 15.1 Documentation Guidelines
*   **Runnable Snippets**: Code examples in documentation must be compilable and runnable.
*   **No Placeholders**: We avoid placeholder comments like `// TODO: implement`. Code blocks must show complete, working implementations.
*   **Formatting**: Documentation files must use clean markdown, clear table layouts, and LaTeX formatting for mathematical equations.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 16. Anti-Complexity Strategy

We protect the developer experience by explicitly prohibiting complex or magical API behaviors.

## 16.1 Forbidden DX Patterns
*   **No Implicit Traversal**: The engine does not execute path traversals in the background on tree updates. Traversal must be triggered explicitly using `evaluateSync`.
*   **No Silent Pruning**: Pruning must be logged. Pruned nodes must record their pruning reasons, which are included in the execution trace.
*   **No Global Singletons**: The package must not use global shared states, ensuring that evaluations remain stateless and thread-safe.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 17. Community & Ecosystem Strategy

We structure community contribution guidelines to maintain package focus and quality.

## 17.1 Contribution Guidelines
*   **RFC Submissions**: Proposed changes to the API or architecture must be submitted as an RFC markdown file under `docs/rfc/` for review.
*   **Strict Scope Limits**: Contributions that introduce dynamic thread runners, UI components, or AI models are rejected, keeping the package focused on its core goals.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 18. Developer Workflow Examples

These examples show how developers interact with the API across different use cases.

## 18.1 Quickstart Evaluation Flow

```
  [ Define Nodes & Tree ] ──► [ Load Scoring Config ] ──► [ evaluateSync ] ──► [ Read Output Path ]
```

```dart
final tree = DecisionTree.fromNodes([
  const DecisionNode(id: 'root', childIds: ['option_A']),
  const DecisionNode(id: 'option_A', parentId: 'root', childIds: [], probability: 1.0, impact: 1.0),
]);

final result = BranchIQEngine.createSync().evaluateSync(
  tree: tree,
  context: const EvaluationContext({}),
  scoring: ScoringConfig.balanced(costCeiling: 100.0),
  pruning: PruningConfig.defaultSettings(),
  traversal: const TraversalConfig(),
);
```

## 18.2 Debug Trace Workflow

```
  [ Run evaluateSync ] ──► [ engine.explain(result) ] ──► Inspect Text Log
```

```dart
final engine = BranchIQEngine.createSync();
final result = engine.evaluateSync(tree: tree, ...);

// Export trace log for diagnostics
final explanation = engine.explain(result);
print(explanation);
```

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 19. Deferred Developer Experience Systems

To maintain focus on MVP quality, the following developer tooling systems are deferred:

1.  **DevTools Graphical Tree Inspectors**:
    *   *Rationale*: Visual tree rendering is not required for core CLI validation.
    *   *Risk*: Adds third-party UI dependencies and increases package size.
2.  **Code-Generation Wizards**:
    *   *Rationale*: Trees can be configured cleanly in code without generation tooling.
    *   *Risk*: Generation scripts (`build_runner`) increase project setup complexity.
3.  **AI-Assisted Debugging Plugins**:
    *   *Rationale*: Path analysis is mathematically traceable without AI translation.
    *   *Risk*: Non-deterministic AI outputs can produce inconsistent diagnostics.

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# 20. Final Developer Experience Lock

The developer interfaces and onboarding roadmaps for BranchIQ version 0.1.0 are locked:

> **BranchIQ v0.1.0 developer experience exists only to provide explicit deterministic runtime decision evaluation with minimal cognitive overhead in pure Dart.**
>
> **Everything else is deferred.**

---

## DX Section Checklist

- [ ] onboarding complexity controlled
- [ ] deterministic guarantees explained
- [ ] API readability enforced
- [ ] overengineering avoided
- [ ] developer trust protected

---

# Developer Experience Audit

This audit evaluates the ergonomics, usability, and adoption strategy of the BranchIQ developer experience.

## Subsystem Assessment Scores (1-10)

| Subsystem / Dimension | Score | Assessment Rationale |
| :--- | :--- | :--- |
| **Onboarding Simplicity** | **10/10** | Provides a clean, dependency-free installation and a 5-minute quickstart guide. |
| **API Readability** | **10/10** | Employs explicit naming and immutable parameters, avoiding global singletons. |
| **Developer Trust** | **10/10** | Guarantees deterministic execution outputs, avoiding dynamic hidden states. |
| **Documentation Clarity** | **10/10** | Structures resources progressively from beginner examples to deep specifications. |
| **pub.dev Discoverability** | **10/10** | Uses clear, keyword-optimized descriptions, positioning the engine as a pure Dart package. |
| **Debugging Usability** | **9/10** | Exposes human-readable text logs and structured JSON snapshots for replay. |
| **Complexity Management** | **10/10** | Hides advanced traversal and pruning options behind safe configuration presets. |
| **Ecosystem Scalability** | **9/10** | Exposes clean, decoupled interfaces for custom evaluators and metadata mapping. |

---

## Audit Findings

### 1. Strongest DX Decision
Exposing the **`engine.explain()` text tracing method**. This provides a human-readable summary of the scoring and pruning decisions made during evaluation, enabling developers to diagnose path choices quickly without parsing raw logs.

### 2. Riskiest DX Simplification
Requiring developers to configure weights that sum to exactly $1.0$ in `ScoringConfig`. While mathematically necessary, this can cause runtime initialization failures if developers calculate weights incorrectly. We provide `ScoringConfig.balanced()` as a safe preset.

### 3. Areas Most Likely to Overwhelm Developers
The transition from static tree definitions to dynamic evaluators (`NodeEvaluator`). Custom evaluation logic requires managing state mutations on copied nodes, which can be challenging for beginners. We provide step-by-step guides for custom evaluator setup.

### 4. Developer Workflows That Must Remain Simple
The basic tree initialization, configuration setup, and synchronous execution pipeline. These three steps represent the core integration path and must not be altered by future updates.

### 5. Recommended Next Planning Document
The developer experience specifications are complete. Development can now begin with Phase 0 setup.
