# BranchIQ Infrastructure Conventions

This document establishes the initial implementation constraints, coding standards, and architectural safety rules for **BranchIQ v0.1.0**.

---

## 1. Initial Implementation Constraints

To protect the MVP from scope creep and maintain high stability, the following subsystems are strictly frozen and **MUST NOT** be implemented in the v0.1.0 release cycle:

* **Isolate Orchestration Workers**: Multi-threaded execution adds overhead (10ms-50ms) and introduces race hazards. The core runtime must execute synchronously on the calling thread.
* **Asynchronous Runtimes**: Evaluation loops and scoring mechanisms must run synchronously to maintain predictable execution latency.
* **Adaptive Learning (Online Policies)**: Dynamic weight updating compromises determinism and trace reproducibility. Weights must remain immutable.
* **AI & Machine Learning Models**: There are no generative LLMs or heuristic neural-networks. Path selection is calculated using deterministic Multi-Attribute Utility Theory (MAUT).
* **Monte Carlo Tree Search (MCTS)**: Traversal is done via deterministic A* search. Stochastic tree rollouts are prohibited.
* **Saved Session Replays**: The loading of past JSON runs into live execution states is deferred to tooling.
* **Flutter Widget Integrations**: The core engine has zero UI packages to allow headless testing in terminal runners.

---

## 2. Architecture Enforcement Rules

To prevent code degradation, developers must adhere to these structural boundaries:

* **No Cyclic Imports**: Clean directional imports are enforced: `math` -> `config` -> `models` -> `core`. Circular reference dependencies will block compile validation.
* **No God Modules**: Orchestration is strictly decoupled. The engine manages evaluation steps but does not contain custom calculation logic or telemetry parsing.
* **No Mutable Runtime Globals**: Engine instances, configurations, and models must remain stateless. Using static singletons (e.g., `BranchIQEngine.instance`) is prohibited.
* **No Hidden Side Effects**: Evaluations must be pure mathematical transformations. Writing to disk, querying system state clocks (`DateTime.now()`), or reading device telemetry directly from within traversals is forbidden.
* **No Nondeterministic Helpers**: Using random seed calculations or round-robin operations in tie-breakers is prohibited.

---

## 3. Initial Coding Standards

Every code contribution must comply with the following standards:

* **Naming Conventions**:
  * Classes must use `UpperCamelCase` (e.g., [DecisionNode](file:///Users/user/StudioProjects/BranchIQ/lib/src/models/decision_node.dart)).
  * Variables, methods, and parameters must use `lowerCamelCase` (e.g., `evaluateSync`).
  * Configurations must use explicit, descriptive naming (e.g., `costCeiling`, not `maxCost`).
* **File Conventions**:
  * Implementations must follow the standard Dart library layout: private logic goes inside `lib/src/` and only stable APIs are exported in `lib/branchiq.dart`.
  * One primary class per file to maintain readability.
* **Test Naming**:
  * Test files must match the target source file name and end with `_test.dart` (e.g., `placeholder_test.dart`).
* **API Documentation Rules**:
  * Public classes, fields, and constructors must have comprehensive Dartdoc triple-slash (`///`) comments explaining their purpose.
* **Immutable-First Rules**:
  * Model constructors must use the `const` keyword.
  * Fields must be marked as `final` and modification operations must return new instances via `copyWith` methods.

---

## 4. Final Repository Lock

> BranchIQ repository initialization exists only to establish a stable deterministic runtime infrastructure foundation.
>
> Everything else is deferred.
