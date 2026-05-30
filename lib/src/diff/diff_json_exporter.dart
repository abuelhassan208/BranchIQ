import '../canonicalization/canonical_json_encoder.dart';
import 'snapshot_diff.dart';

/// Provides deterministic and platform-independent JSON serialization and formatting for snapshot diffs.
class DiffJsonExporter {
  /// Encodes the snapshot diff into a compact, single-line canonical JSON string.
  static String exportCompact(SnapshotDiff diff) {
    return CanonicalJsonEncoder.encode(diff.toJson());
  }

  /// Encodes the snapshot diff into a pretty-printed canonical JSON string for debugging and comparison logs.
  static String exportPretty(SnapshotDiff diff) {
    return CanonicalJsonEncoder.encodePretty(diff.toJson());
  }
}
