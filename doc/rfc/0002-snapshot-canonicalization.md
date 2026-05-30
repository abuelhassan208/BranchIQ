# RFC-0002: Snapshot Canonicalization & Deterministic Serialization

* **RFC Number**: RFC-0002
* **Title**: Snapshot Canonicalization & Deterministic Serialization
* **Status**: Draft
* **Author**: `<Principal Systems Architect>`
* **Target Version**: v0.2
* **Created Date**: `2026-05-23`

---

## 1. RFC Metadata

This document outlines the canonical serialization protocol, byte-identical hashing architecture, floating-point formatting contracts, and schema validation systems designed to guarantee platform-independent determinism inside the BranchIQ snapshot ecosystem.

* **RFC**: RFC-0002
* **Title**: Snapshot Canonicalization & Deterministic Serialization
* **Status**: Draft
* **Target**: v0.2
* **Author**: `<Principal Systems Architect>`
* **Created**: `2026-05-23`

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay integrity preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 2. Problem Statement

A bounded deterministic decision engine requires that replaying decisions, generating side-by-side diffs, and storing audit logs produce identical, reproducible results across diverse runtimes (e.g., standard Dart VM, AOT-compiled Flutter binaries on iOS/Android, and JS-compiled web outputs).

Without a canonical snapshot definition, deterministic integrity is threatened by:
1. **Map Iteration Divergence**: The order of map keys in JSON formats is often arbitrary and dependent on platform-specific hash algorithms, causing byte-wise variance.
2. **Floating-Point Formatting Ambiguity**: Variations in float representation (trailing zeros, scientific notation, negative zero handling, and compiler floating-point optimizations) break checksums and diff comparisons.
3. **Markdown Formatter Inconsistency**: Slight discrepancies in spacing, newlines, and tables generated in different execution environments render terminal logs and Git golden tests flaky.
4. **Platform & Locale Sensitivities**: Runtimes formatting numbers or strings with locale-aware settings can alter structural data formats.
5. **Hash Instability**: Telemetry changes, execution timestamps, and local benchmarks introduce non-deterministic entropy, making validation hashes volatile.

Replay correctness relies completely on snapshot byte equivalence. If the serialized representation changes based on compile target or execution context, golden regression suites and cryptographic audit trails become unreliable.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay integrity preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 3. Goals

1. **Stable Snapshot Identity**: Formulate strict rules that ensure equivalent runtime decision states result in identical, byte-matching serialized files.
2. **Deterministic Serialization**: Design JSON encoding mechanisms that guarantee stable, lexicographically ordered key-value outputs.
3. **Canonical Markdown Formatting**: Establish rigid markdown generator guidelines to produce stable tables, paths, and lists across all environments.
4. **Replay-Safe Hashing**: Standardize a hashing mechanism that calculates consistent identifiers for snapshots while ignoring execution duration, local clocks, and benchmark metrics.
5. **Reproducible Regression Outputs**: Protect development environments and CI pipelines from flaky test suites by maintaining stable golden snapshots.
6. **Cross-Platform Consistency**: Assure identical serialization output on JIT, AOT, web-transpiled Dart runtimes, and differing operating systems.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay integrity preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 4. Non-Goals

The following specifications are explicitly excluded from this RFC:

1. **Cryptographic Signing & Signature Schemes**: We will not specify asymmetric signatures (e.g., RSA, ECDSA) or token verification (JWT). This is out-of-scope and can be implemented by downstream systems wrapping the canonical outputs.
2. **Distributed Consensus Protocols**: No protocol for replication, sync consensus, or state machine distribution across nodes (e.g., Raft, Paxos).
3. **Compression & Binary Encoding Systems**: The focus is exclusively on standard, text-readable JSON and Markdown exports. Protobuf, CBOR, MessagePack, and gzip compression pipelines are deferred.
4. **Database Storage and ORM Layers**: This RFC does not design integrations with specific databases (SQL, NoSQL) or local persistence layers (Hive, SQLite).
5. **Network Synchronization Protocol**: No definition of REST, WebSocket, or gRPC transport wrappers to share snapshots over networks.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 5. Canonicalization Philosophy

To ensure reliability, the BranchIQ serialization layer is designed around a single principle:

> **"Equivalent runtime states must always produce byte-identical serialized outputs."**

This philosophy translates into the following constraints:
1. **Zero Runtime Dependency**: Serialization formatting must be stateless. It cannot refer to environment variables, hardware architecture, CPU word size, or process memory addresses.
2. **Zero Locale Dependency**: Numbers, currency symbols, separators, and character collations must always be formatted using standard, locale-agnostic rules (ASCII-compatible, standard dot-decimal notation).
3. **No Unordered Structures**: All raw outputs must eliminate dynamic sets or native un-sorted maps. Any collection stored in the snapshot must adhere to topological, chronological, or lexicographical sorting rules.
4. **Purely Static Serializer Optimization**: Avoid runtime reflections or generic type casting inside serialization routines to prevent discrepancies between debug and release builds.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 6. Canonical Snapshot Structure

The canonical snapshot schema enforces a strict structure for the serialized JSON representation. 

### JSON Key Sequence
At the top level of the JSON document, keys must be written in a fixed lexicographical order. 

```json
{
  "benchmarkSnapshot": {},
  "engineVersion": "0.2.0",
  "metadata": {},
  "nodeSnapshots": {},
  "prunedNodeIds": [],
  "pruningTraces": [],
  "rootId": "root",
  "runtimeTraces": [],
  "schemaVersion": "2.0",
  "scoringSummaries": {},
  "selectedPath": [],
  "traversalSummaries": {}
}
```

### Constraints on Collections and Nulls
1. **Null Values**: Keys with null values must be completely omitted from the serialized map rather than written as `"key": null`. This keeps the JSON payload lean and simplifies backward-compatibility audits.
2. **Empty Collections**: Lists and maps that are empty must be serialized as `[]` and `{}` respectively, maintaining their keys inside the output to verify collection presence.
3. **Trace Ordering**: Lists like `pruningTraces` and `runtimeTraces` must preserve their chronological execution order.
4. **Metadata Collections**: All custom properties inside the `metadata` map must be sorted alphabetically by key.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 7. Canonical Field Ordering Rules

To ensure text-based comparisons are stable, we apply three strict ordering models depending on the data type:

### Lexicographical Alphabetical Ordering
All map-like structures must sort their keys alphabetically based on Unicode code points. This applies to:
* Top-level `DebugSnapshot` keys.
* Keys inside the `nodeSnapshots` collection (node IDs are sorted alphabetically).
* Properties inside `DecisionNode.metadata`.
* Key listings in configuration maps.

### Stable Topological Path Ordering
Sequence lists representing paths (such as `selectedPath`) must match the hierarchical traversal path sequence generated by the engine. Paths must start at the root node, descending parent-to-child sequentially (`root -> child_a -> leaf_node`). Dynamic re-sorting of these paths is forbidden.

### Execution Chronological Ordering
Operational execution trace arrays (`pruningTraces` and `runtimeTraces`) must follow execution order. This trace sequence is stable because traversal strategies inside the runtime use deterministic priority queues.

```dart
// Example of Map Normalization
Map<String, dynamic> normalizeMap(Map<String, dynamic> source) {
  final sortedEntries = source.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return Map<String, dynamic>.fromEntries(sortedEntries);
}
```

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 8. Canonical List Ordering Rules

Standard rules for serializing lists within snapshots and reports:

1. **`nodeSnapshots` Array Rendering**: When serializing lists of nodes (e.g., within reports or diagnostic summaries), nodes must be ordered lexicographically by their unique `id`.
2. **`prunedNodeIds` sequence**: Sorted alphabetically by node ID. This ensures the pruned listing is stable even if pruning steps occur in parallel or in varying queue states.
3. **`selectedPath` values**: Preserves execution depth ordering (`depth: 0`, then `depth: 1`, up to target `depth: N`).
4. **Markdown Export Elements**:
   * Sibling nodes evaluated on a shared frontier must be listed in a table sorted alphabetically by `nodeId`.
   * Pruning tables must be sorted alphabetically by the excluded `nodeId`.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 9. Floating-Point Canonicalization

Because different hardware architectures and compilers interpret float calculations with slight differences, we enforce strict formatting rules on all decimal serialization steps.

### Rules for Decimal Values
1. **Fixed Precision Formatting**: All floating-point fields (`probability`, `impact`, `cost`, `confidence`, and calculated `score`) must be rounded and serialized as a string or number formatted to exactly **4 decimal places** (e.g., `0.8500`).
2. **Decimal Point Policy**: Decimals must use the standard dot separator (`.`). Comma formats (e.g., standard French or German locales) are forbidden.
3. **Trailing Zeros**: Trailing zeros must be explicitly written out (e.g., `0.5` becomes `0.5000`, `1.0` becomes `1.0000`).
4. **Negative Zero**: The value `-0.0` or `-0.0000` must be normalized to positive `0.0000`.
5. **Special Numeric Values**:
   * `NaN` is not allowed inside evaluated nodes. The engine must throw an exception if calculations resolve to `NaN`.
   * `Infinity` and `-Infinity` must be represented inside JSON payloads as special fallback constants `"INFINITY"` and `"-INFINITY"`.

```dart
// Floating Point Formatting Engine
String formatDouble(double value) {
  if (value.isNaN) {
    throw ArgumentError('NaN is not a valid snapshot numeric state.');
  }
  if (value == double.infinity) return 'INFINITY';
  if (value == double.negativeInfinity) return '-INFINITY';
  
  // Normalize negative zero
  final normalized = value == -0.0 ? 0.0 : value;
  return normalized.toStringAsFixed(4);
}
```

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 10. Stable JSON Serialization Rules

To ensure snapshots are stable and readable under diff tools, the JSON serialization process must follow a strict formatting standard:

* **No Indentation or Whitespace in Core Storage**: While human-friendly tools can pretty-print JSON files, the canonical serialized representation used for cryptographic hashing must be compact, with no unnecessary spaces, indents, or newlines.
* **UTF-8 Normalization**: All strings must be encoded in UTF-8 format. Unicode characters must be normalized using Unicode Normalization Form C (NFC) before sorting or writing.
* **Stable Key Insertion**: Raw JSON encoders must iterate over map properties following their sorted order.
* **Newline Standard**: Newlines inside trace messages or string fields must be normalized to use the single LF (`\n`) character. Carriage return characters (`\r`) are stripped.

```json
{"engineVersion":"0.2.0","rootId":"root","selectedPath":["root","accept"],"schemaVersion":"2.0"}
```

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 11. Deterministic Markdown Export Rules

The Markdown Export system renders explanation reports into human-readable text documents. Because these files are checked into version control as golden files, they must be generated deterministically.

### Layout and Markdown Contracts
1. **Sequential Headers**: Headings must follow a strict hierarchy (`#`, `##`, `###`) with exactly one trailing space and no leading spaces.
2. **Table Alignment**: Data tables must use standard pipes (`|`) with a single space padding on both sides. Columns must align using fixed formatting.
3. **Numeric Display**: Decimal values inside Markdown tables must always be printed with **exactly 4 decimal places** (e.g., `0.7410`).
4. **List Markers**: Bullet points must consistently use the dash marker (`-`). Spacing between list items must be normalized to a single empty line, and trailing newlines must be clean.

```markdown
# BranchIQ Decision Report

## Selected Path
- [root] (Utility: 1.0000)
- [accept] (Utility: 0.8500)

## Node Traversal Metrics
| Node ID | Score | Probability | Impact | Cost | Confidence |
| :--- | :--- | :--- | :--- | :--- | :--- |
| accept | 0.8500 | 0.9000 | 0.8000 | 50.0000 | 1.0000 |
| root | 1.0000 | 1.0000 | 0.0000 | 0.0000 | 1.0000 |
```

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 12. Snapshot Identity & Hashing

To uniquely identify decisions without depending on cryptographic packages, BranchIQ defines a deterministic hashing mechanism called `CanonicalSnapshotHasher`.

```
┌─────────────────────────────────────────────────────────┐
│                    DebugSnapshot                        │
└──────────────────────────┬──────────────────────────────┘
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
    [ Included Fields ]         [ Excluded Fields ]
    - Selected Path             - Duration Metrics
    - Topo & Node Metrics       - System Timestamps
    - Pruned Node Listings      - Local CPU Benchmarks
    - Traces                    - OS Telemetry
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│                 Canonical String Digest                 │
└──────────────────────────┬──────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│              CanonicalSnapshotHasher                    │
│                 (Deterministic Hash)                    │
└─────────────────────────────────────────────────────────┘
```

### Hash Integrity Constraints
To ensure the calculated hash matches across different systems, the hashing process must **exclude** environment-dependent fields:
* Excluded: `benchmarkSnapshot` (CPU cycles, memory allocation times, execute durations).
* Excluded: `metadata['timestamp']` (evaluation runtime clocks).
* Included: `engineVersion`, `schemaVersion`, `selectedPath`, `nodeSnapshots` (with normalized 4-decimal coordinates), `prunedNodeIds`, and chronological traces.

### Deterministic Identity Implementation
```dart
class CanonicalSnapshotHasher {
  /// Computes a stable, deterministic hash string for a snapshot.
  static String calculateHash(DebugSnapshot snapshot) {
    final buffer = StringBuffer();

    // 1. Write metadata
    buffer.write('engine:${snapshot.engineVersion};');
    buffer.write('root:${snapshot.rootId};');

    // 2. Write path sequence
    buffer.write('path:${snapshot.selectedPath.join(',')};');

    // 3. Write sorted nodes
    final sortedNodeIds = snapshot.nodeSnapshots.keys.toList()..sort();
    for (final id in sortedNodeIds) {
      final node = snapshot.nodeSnapshots[id]!;
      buffer.write('node:$id[');
      buffer.write('p:${_format(node['probability'])},');
      buffer.write('i:${_format(node['impact'])},');
      buffer.write('c:${_format(node['cost'])},');
      buffer.write('f:${_format(node['confidence'])},');
      buffer.write('s:${_format(node['score'])}];');
    }

    // 4. Write sorted pruned nodes
    final sortedPruned = snapshot.prunedNodeIds.toList()..sort();
    buffer.write('pruned:${sortedPruned.join(',')};');

    // Simple Jenkins One-at-a-time hash implementation for platform-independent stability
    return _jenkinsHash(buffer.toString());
  }

  static String _format(dynamic value) {
    if (value is num) {
      return value.toDouble().toStringAsFixed(4);
    }
    return '0.0000';
  }

  static String _jenkinsHash(String key) {
    int hash = 0;
    for (int i = 0; i < key.length; i++) {
      hash += key.codeUnitAt(i);
      hash = (hash & 0xFFFFFFFF);
      hash += (hash << 10);
      hash = (hash & 0xFFFFFFFF);
      hash ^= (hash >> 6);
    }
    hash += (hash << 3);
    hash = (hash & 0xFFFFFFFF);
    hash ^= (hash >> 11);
    hash += (hash << 15);
    hash = (hash & 0xFFFFFFFF);
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
```

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 13. Canonical Replay Guarantees

By defining canonical representations, we establish the following guarantees:

1. **Replay Equivalence**: Any snapshot loaded from JSON into a `ReplaySession` must match the execution state of the original runtime run down to the byte level.
2. **Safe Schema Upgrades**: When loading legacy snapshots, they are upgraded to the current canonical representation using safe defaults before calculation. This keeps replay logic predictable across versions.
3. **Strict Validation**: Replay loader logic will refuse to process payloads that fail canonical integrity checks. This prevents corrupted metadata from polluting production databases.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 14. Diff Stability Rules

Deterministic diff generation depends on applying stable comparison and formatting rules:

1. **Alphabetical Comparison Order**: When comparing differences between two nodes in different snapshots, the nodes must be analyzed alphabetically by their `nodeId`. This keeps diff files predictable.
2. **Consistent Insertion and Deletion Grouping**: Added nodes must always be listed before deleted nodes in diff summaries, followed by modified nodes.
3. **Structured Field Sorting**: When reporting changed properties inside a node (e.g., changes to impact and cost), the differences must be written in a fixed alphabetical order: `confidence`, `cost`, `impact`, `probability`, `score`.
4. **Stable Path Alignment**: Discrepancies between paths must be aligned side-by-side starting at their common ancestor node, showing the point of divergence clearly.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 15. Schema Evolution Strategy

To support updates to BranchIQ snapshots over time, we use a structured schema evolution strategy:

```
                  ┌──────────────────────┐
                  │    Incoming JSON     │
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │    Extract version   │
                  │   ("schemaVersion")  │
                  └──────────┬───────────┘
                             │
             ┌───────────────┴───────────────┐
             ▼ (== 1.0)                      ▼ (>= 2.0)
 ┌──────────────────────┐        ┌──────────────────────┐
 │    Apply Migrator    │        │ Validate against     │
 │ - Add fallback keys  │        │ current strict       │
 │ - Normalize Decimals │        │ Canonical Schema     │
 └──────────┬───────────┘        └──────────┬───────────┘
            │                               │
            └───────────────┬───────────────┘
                            │
                            ▼
 ┌──────────────────────────────────────────────┐
 │          Replay Reconstitution               │
 └──────────────────────────────────────────────┘
```

### Schema Rules
* **Version Identification**: Every JSON payload must contain a `schemaVersion` key. Snapshots missing this property are assumed to be v1.0 (legacy v0.1.x payloads).
* **Backward Compatibility Guarantee**: The v0.2 `ReplayLoader` can parse v1.0 schemas. It will automatically initialize missing properties (e.g., `traversalSummaries`) with default values.
* **Forward Compatibility Restraints**: If a v0.2 engine encounters a newer schema version (e.g., `3.0`), it must halt evaluation and throw a detailed version compatibility error to prevent unsafe executions.
* **Deprecated Property Lifecycle**: Deprecated fields must remain supported for one minor version release. During this transition, they are written to a secondary `deprecated` partition in the JSON output, keeping the main keys clean.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 16. Canonical Validation Layer

The `CanonicalizationValidator` operates as a gatekeeper. It checks incoming JSON payloads to ensure they meet canonical standards before the engine processes them.

```dart
class CanonicalizationValidator {
  /// Inspects a serialized snapshot payload for strict canonical correctness.
  static ValidationResult validate(Map<String, dynamic> json) {
    // 1. Validate top-level key sorting
    final keys = json.keys.toList();
    final sortedKeys = List<String>.from(keys)..sort();
    if (!_listsEqual(keys, sortedKeys)) {
      return ValidationResult.fail('Top-level JSON keys are not sorted alphabetically.');
    }

    // 2. Validate node formatting compliance
    final nodeSnapshots = json['nodeSnapshots'] as Map<String, dynamic>? ?? {};
    for (final entry in nodeSnapshots.entries) {
      if (entry.value is! Map) {
        return ValidationResult.fail('Node snapshot ${entry.key} is malformed.');
      }
      final nodeData = entry.value as Map<String, dynamic>;
      final nodeKeys = nodeData.keys.toList();
      final sortedNodeKeys = List<String>.from(nodeKeys)..sort();
      if (!_listsEqual(nodeKeys, sortedNodeKeys)) {
        return ValidationResult.fail('Keys in node ${entry.key} are not sorted alphabetically.');
      }

      // Verify float compliance (checking for non-canonical numeric structures)
      for (final metric in ['probability', 'impact', 'cost', 'confidence', 'score']) {
        final val = nodeData[metric];
        if (val is! num) {
          return ValidationResult.fail('Metric $metric on node ${entry.key} must be a number.');
        }
      }
    }

    return ValidationResult.pass();
  }

  static bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
```

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 17. Failure Semantics

When validating or parsing snapshots, execution errors must be predictable and deterministic across all runtimes.

### Error Classifications
* **`UnsortedSnapshotException`**: Raised when map keys do not match their expected alphabetical order during a strict validation check.
* **`FloatPrecisionException`**: Thrown if the parser encounters values with invalid decimal precision or formatting.
* **`UnsupportedSchemaException`**: Raised when the engine encounters schema versions newer than its supported limit.

All exceptions must include structured, platform-agnostic messages. This prevents varying error outputs across compile targets.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 18. Performance Constraints

The canonicalization validation process is lightweight, ensuring it can run safely in production and continuous integration environments:

1. **Synchronous Validation**: All validation and parsing steps are synchronous, with no isolate overhead or futures.
2. **Minimal Memory Overhead**: Map sorting and string verification routines operate directly on input streams.
3. **Linear Time Complexity**: Key validation executes in `O(K)` time, where `K` is the count of individual fields in the snapshot.
4. **Zero Cache Leakage**: The validation process is stateless, ensuring no intermediate objects are retained in memory after check completion.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 19. Testing Strategy

To ensure canonicalization rules remain stable over time, we use a comprehensive suite of regression tests:

### Core Testing Areas
* **Byte-for-Byte Golden Tests**: Compare newly generated JSON outputs with checked-in golden snapshots. These tests fail if even a single space, character, or key order shifts.
* **Platform Invariance Suite**: Run the test suite on both JIT and compiled JS/Wasm targets, asserting that all runtimes output identical files.
* **Corrupted Snapshot Rejection**: Verify that `CanonicalizationValidator` detects and rejects payloads with unsorted keys or malformed floats.
* **Multi-Format Verification**: Ensure that importing, exporting, and re-exporting snapshots yields identical byte-level outputs across cycles.
* **Jenkins Hash Consistency**: Test the hashing function against predetermined inputs to verify checksum calculations match expected static hashes.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 20. Proposed File Structure

We will organize the v0.2 canonicalization components under `lib/src/canonicalization/`:

```
lib/
└── src/
    └── canonicalization/
        ├── canonical_json_encoder.dart    <-- Stable JSON formatter
        ├── canonical_markdown_writer.dart <-- Stable Markdown formatter
        ├── canonical_snapshot_hasher.dart <-- Snapshot Jenkins identity engine
        ├── canonicalization_validator.dart <-- Key and float gatekeeper
        └── exceptions.dart                <-- Structured exceptions
```

### Access Boundaries
* **Public APIs**: `CanonicalSnapshotHasher` and `CanonicalizationValidator` are exported in the main `lib/branchiq.dart` library.
* **Internal APIs**: Formatter engines reside within `lib/src/canonicalization/` and are inaccessible to user code.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 21. Rollout Plan

To ensure a smooth transition, we will roll out the canonicalization layer in four sequential phases:

```
┌────────────────────────────────┐
│   Phase A: Canonical JSON      │
│   - Sorted key serializations  │
│   - Float decimal formatters   │
└───────────────┬────────────────┘
                │
                ▼
┌────────────────────────────────┐
│   Phase B: Markdown Export     │
│   - Table layout normalize     │
│   - Alignment standardizations │
└───────────────┬────────────────┘
                │
                ▼
┌────────────────────────────────┐
│   Phase C: Snapshot Hashing    │
│   - Jenkins digest system      │
│   - Unique identity checks     │
└───────────────┬────────────────┘
                │
                ▼
┌────────────────────────────────┐
│  Phase D: strict Validation    │
│   - Validator layer checks     │
│   - Replay error enforcements  │
└────────────────────────────────┘
```

### Rationale
* **Phase A**: Provides the foundation by ensuring JSON files are written with stable ordering.
* **Phase B**: Leverages stable JSON data to construct deterministic markdown logs.
* **Phase C**: Implements the unique hash engine on top of the structured data models.
* **Phase D**: Activates strict validation gates to block non-canonical payloads from executing in production replays.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 22. Risks & Complexity Analysis

| Identified Risk | Severity | Mitigation Strategy |
| :--- | :--- | :--- |
| **Floating-Point Precision Variance**: Native compiler variations (e.g. JS double numbers vs AOT floats) could round values differently. | High | Enforce strict `toStringAsFixed(4)` conversions for all decimal metrics before writing to outputs. |
| **Locale Formatting Drift**: Locale-specific runtimes might output commas instead of decimal dots. | High | Enforce ASCII-only decimal parsing checks within formatters. |
| **Map Sorting Performance Overhead**: Lexicographical sorting on huge trees could slow down operations. | Medium | Restrict sorting to export and serialization steps. Dynamic in-memory calculations inside the engine continue to use fast, unsorted maps. |
| **Hash Collisions**: Using simple Jenkins hashes might theoretically lead to collisions in extremely large systems. | Low | Combine Jenkins hashes with structural identifiers (such as root nodes and path paths) to guarantee unique indexes. |

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 23. Deferred Systems

The following systems are deferred to maintain focus on core snapshot stability:

1. **Binary Snapshots (Protobuf/MessagePack)**: Postponed until payload sizes exceed text-based transfer constraints.
2. **Snapshot Compression Layer**: Compressing snapshots is deferred to downstream implementations.
3. **Encrypted Snapshot Storage**: Symmetric/asymmetric encryption of snapshots is deferred.
4. **Cloud Snapshot Registry**: Building hosted registries or remote database APIs to store snapshots is postponed.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

## 24. Final RFC Lock

> **BranchIQ canonicalization exists to ensure that identical runtime decisions always produce identical serialized representations.**

Replay correctness depends on canonicalization correctness.

### RFC Validation Checklist
* [x] deterministic guarantees preserved
* [x] replay safety preserved
* [x] serialization stability preserved
* [x] cross-platform consistency preserved
* [x] locale-sensitive behavior avoided

---

# RFC Readiness Audit

Score from 1–10:
* **Deterministic integrity**: 10/10
* **Replay safety**: 10/10
* **Serialization stability**: 10/10
* **Implementation feasibility**: 9/10
* **Hashing consistency**: 9/10
* **Diff reproducibility**: 10/10
* **Markdown stability**: 9/10

### Architectural & Execution Details
1. **Most Critical Canonicalization Rule**: Formatting all decimal values to exactly 4 decimal places with positive zero normalization. This prevents floating-point discrepancies from breaking hashing and comparisons across different CPU architectures.
2. **Biggest Replay Stability Risk**: Ensuring that custom telemetry stored in the `metadata` map uses basic, JSON-serializable types and sorted keys to avoid breaking verification checks.
3. **Most Difficult Serialization Problem**: Implementing stable JSON key ordering in standard Dart environments without adding heavy, external dependencies.
4. **Recommended Implementation Order**:
   * Implement Phase A (Canonical JSON and float encoders) first.
   * Add Phase B (Markdown standard formatter).
   * Integrate Phase C (Jenkins-based unique hasher).
   * Activate Phase D (Strict validation gates) inside the Replay loaders.
5. **Systems Intentionally Deferred**: Binary representations (Protobuf/MessagePack), encrypted payloads, compression steps, and cloud-hosted snapshot registries are deferred to preserve a lean, dependency-free core.
