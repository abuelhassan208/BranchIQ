# Contributing to BranchIQ

Thank you for your interest in contributing to BranchIQ. This package is designed to be a highly stable, deterministic decision engine. To maintain these guarantees, we enforce a strict set of development guidelines.

---

## 1. RFC-First Philosophy

Before writing any implementation code or proposing modifications to the public API surface, submit a Request for Comments (RFC) document under `doc/rfc/`.

- The RFC must define the problem statement, proposed interfaces, complexity implications, and impact on determinism guarantees.
- Code changes submitted without an approved RFC will be closed automatically.

---

## 2. Deterministic Guarantees

BranchIQ guarantees that given identical tree models, configuration parameters, and evaluation context, the engine will yield the exact same path on all hardware architectures.

- Do not introduce `dart:math.Random`, system clock access (`DateTime.now()`), or asynchronous side effects anywhere in evaluation code.
- All tie-breakers in pathfinding and pruning must remain strictly deterministic (lexicographic node ID ordering).
- Do not introduce `Stopwatch` or wall-clock profiling inside evaluation paths.

---

## 3. Anti-Overengineering Policy

Our mission is to maintain a simple, lightweight, bounded runtime engine.

- Do not introduce background isolates, database caching, or widget integrations. Plugins must adhere strictly to the synchronous, pure-in-memory `NodeEvaluator` interface.
- Do not add async/Future/Stream to the evaluation pipeline.
- Do not add adaptive learning, ML inference, or AGI-style systems.
- We maintain a zero runtime dependency codebase that compiles instantly and runs synchronously.

---

## 4. Testing Requirements

We maintain rigorous quality standards.

- All mathematical and scoring code must achieve **100% unit test coverage**.
- All other package modules must maintain at least **95% code coverage**.
- Pull requests must include regression tests to verify execution reproducibility across multiple iterations.
- All tests must pass with zero warnings:

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

---

## 5. API Stability

We adhere to Semantic Versioning (SemVer). Public API signatures for `BranchIQEngine`, `DecisionNode`, `DecisionTree`, and configuration classes are frozen for minor releases. Breaking changes are deferred to major release cycles and require migration documentation.

---

## 6. Formatting & Analysis

All contributions must pass the following checks before review:

```bash
dart format .      # Format all Dart files
dart analyze       # Zero warnings/errors required
dart test          # All tests must pass
dart doc           # Documentation must build cleanly
```

---

## 7. Scope Boundaries for v0.3.x

Accepted contributions:
- Bug fixes in deterministic scoring, traversal, replay, explainability, diffing, or plugin registries
- Additional unit and regression tests
- Documentation improvements

Out of scope for v0.3.x (require RFC for future versions):
- New traversal strategies
- Async evaluation, background isolates, or I/O/reflection in plugins
- Flutter widget integrations
- Dynamic node expansion (`BranchExpander`) or custom report exporters (`ReportExporter`)

---

## 8. Release Process

To publish a new version of BranchIQ to pub.dev, follow this automated release process:

1. **Update Version**: Bump the package version in `pubspec.yaml` (e.g., `version: 0.3.0`).
2. **Update Changelog**: Document all notable changes under the new version header in `CHANGELOG.md`.
3. **Commit & Push**: Commit the version bump and push changes to the `main` branch.
4. **CI Verification**: Wait for the GitHub Actions CI workflow to run and pass successfully on the commit.
5. **Create & Push Release Tag**: Tag the commit with a version tag prefix `v` matching the version in `pubspec.yaml`, then push the tag:
   ```bash
   git tag v0.3.0
   git push origin v0.3.0
   ```
6. **Automated Publishing**: The publish workflow (`publish.yml`) will trigger on the pushed tag, run formatting, static analysis, unit tests, example validations, and publish the package automatically to pub.dev via **Trusted Publishing** (OIDC).
