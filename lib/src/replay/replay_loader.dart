import 'dart:convert';
import '../../src/canonicalization/canonicalization_validator.dart';
import '../debug/debug_snapshot.dart';
import 'replay_exceptions.dart';
import 'replay_session.dart';

/// Reconstructs and validates a [ReplaySession] from direct snapshots,
/// raw JSON maps, or canonical JSON strings.
class ReplayLoader {
  /// Loads a [DebugSnapshot] directly into a [ReplaySession].
  static ReplaySession load(DebugSnapshot snapshot) {
    final json = snapshot.toJson();
    if (!json.containsKey('schemaVersion')) {
      if (snapshot.engineVersion.startsWith('0.2')) {
        json['schemaVersion'] = '2.0';
      } else {
        json['schemaVersion'] = '1.0';
      }
    }
    return loadJson(json);
  }

  /// Reconstructs a [ReplaySession] from a raw JSON-safe Map structure.
  /// Performs strict validation checks against missing nodes, unsupported
  /// schema versions, and missing root identities.
  static ReplaySession loadJson(Map<String, Object?> json) {
    try {
      // 1. Extract and validate schemaVersion
      final schemaRaw = json['schemaVersion'];
      final String schemaVersion;
      if (schemaRaw == null) {
        schemaVersion = '1.0';
      } else if (schemaRaw is String) {
        schemaVersion = schemaRaw;
      } else {
        throw const ReplayCorruptException(
            'Invalid schemaVersion format (must be a String).');
      }

      // Reject unsupported future schema versions (greater than 2.0)
      if (schemaVersion != '1.0' && schemaVersion != '2.0') {
        try {
          final versionNum = double.parse(schemaVersion);
          if (versionNum > 2.0) {
            throw ReplayCorruptException(
              'Unsupported newer schema version.',
              schemaVersion: schemaVersion,
            );
          }
        } catch (e) {
          if (e is ReplayCorruptException) rethrow;
          throw ReplayCorruptException(
            'Unsupported newer schema version.',
            schemaVersion: schemaVersion,
          );
        }
      }

      // 2. Extract and validate engineVersion and rootId
      final engineVersion = json['engineVersion'] as String? ?? '0.1.0';
      final rootId = json['rootId'] as String? ?? '';
      if (rootId.isEmpty) {
        throw const ReplayCorruptException(
            'Snapshot rootId must not be empty.');
      }

      // 3. Extract and validate selectedPath
      final rawPath = json['selectedPath'];
      if (rawPath is! List) {
        throw const ReplayCorruptException('selectedPath must be a List.');
      }
      for (final item in rawPath) {
        if (item is! String) {
          throw const ReplayCorruptException(
              'selectedPath must only contain String elements.');
        }
      }
      final selectedPath = List<String>.unmodifiable(rawPath.cast<String>());

      // 4. Extract and validate nodeSnapshots
      final rawSnapshots = json['nodeSnapshots'];
      if (rawSnapshots is! Map) {
        throw const ReplayCorruptException('nodeSnapshots must be a Map.');
      }

      final nodeSnapshots = <String, Map<String, dynamic>>{};
      for (final entry in rawSnapshots.entries) {
        final key = entry.key.toString();
        final val = entry.value;
        if (val is! Map) {
          throw ReplayCorruptException(
              'nodeSnapshot for node $key must be a Map.');
        }

        // Ensure the map values are JSON-safe and valid
        try {
          CanonicalizationValidator.validateJsonSafe(val);
        } catch (e) {
          throw ReplayCorruptException(
            'nodeSnapshot for node $key contains non-JSON safe values: $e',
            mismatchReason: e.toString(),
          );
        }

        nodeSnapshots[key] =
            Map<String, dynamic>.unmodifiable(Map<String, dynamic>.from(val));
      }

      // 5. Upgrade missing optional fields with safe defaults
      final rawPruned = json['prunedNodeIds'] as List? ?? [];
      for (final item in rawPruned) {
        if (item is! String) {
          throw const ReplayCorruptException(
              'prunedNodeIds must only contain String elements.');
        }
      }
      final prunedNodeIds = List<String>.unmodifiable(rawPruned.cast<String>());

      final rawPruningTraces = json['pruningTraces'] as List? ?? [];
      for (final item in rawPruningTraces) {
        if (item is! String) {
          throw const ReplayCorruptException(
              'pruningTraces must only contain String elements.');
        }
      }
      final pruningTraces =
          List<String>.unmodifiable(rawPruningTraces.cast<String>());

      final rawRuntimeTraces = json['runtimeTraces'] as List? ?? [];
      for (final item in rawRuntimeTraces) {
        if (item is! String) {
          throw const ReplayCorruptException(
              'runtimeTraces must only contain String elements.');
        }
      }
      final runtimeTraces =
          List<String>.unmodifiable(rawRuntimeTraces.cast<String>());

      // 5.5 Extract and validate pluginProvenance
      final rawProvenance = json['pluginProvenance'] as List? ?? [];
      final pluginProvenance = <Map<String, dynamic>>[];
      for (final item in rawProvenance) {
        if (item is! Map) {
          throw const ReplayCorruptException(
              'pluginProvenance must only contain Map elements.');
        }
        pluginProvenance.add(Map<String, dynamic>.from(item));
      }

      // 6. Integrity validation rules
      // Selected path nodes must exist in nodeSnapshots
      for (final nodeId in selectedPath) {
        if (!nodeSnapshots.containsKey(nodeId)) {
          throw ReplayCorruptException(
            'Selected path node "$nodeId" is missing from nodeSnapshots.',
            missingNodeId: nodeId,
          );
        }
      }

      // selectedPath is not empty unless the snapshot is failed
      if (selectedPath.isEmpty) {
        final metadata = json['metadata'] as Map? ?? {};
        final hasError = metadata.containsKey('error') ||
            metadata.containsKey('errorMessage') ||
            (json['errorMessage'] != null &&
                (json['errorMessage'] as String).isNotEmpty);

        if (!hasError) {
          throw const ReplayCorruptException(
            'selectedPath must not be empty for a successful evaluation.',
          );
        }
      }

      // Reconstruct the original DebugSnapshot using v0.1 model parser
      final snapshot = DebugSnapshot.fromJson(json);

      return ReplaySession(
        snapshot: snapshot,
        schemaVersion: schemaVersion,
        engineVersion: engineVersion,
        selectedPath: selectedPath,
        prunedNodeIds: prunedNodeIds,
        runtimeTraces: runtimeTraces,
        pruningTraces: pruningTraces,
        nodeSnapshots: nodeSnapshots,
        rootId: rootId,
        pluginProvenance: pluginProvenance,
      );
    } on ReplayCorruptException {
      rethrow;
    } catch (e) {
      throw ReplayCorruptException(
        'Failed to reconstruct ReplaySession due to unexpected error: $e',
        mismatchReason: e.toString(),
      );
    }
  }

  /// Parses a canonical JSON string, verifies its formatting rules, and loads it.
  static ReplaySession loadCanonicalJson(String json) {
    // Validate format against strict canonical guidelines (whitespace, sorted keys, float precision)
    CanonicalizationValidator.validateCanonicalJsonString(json);

    final Object? decoded = jsonDecode(json);
    if (decoded is! Map<String, Object?>) {
      throw const ReplayCorruptException(
          'Canonical JSON payload must represent a Map.');
    }
    return loadJson(decoded);
  }
}
