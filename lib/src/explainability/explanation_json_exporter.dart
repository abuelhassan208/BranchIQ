import '../canonicalization/canonical_json_encoder.dart';
import 'explanation_report.dart';

/// Provides deterministic and stable JSON export capabilities for decision explanation reports.
class ExplanationJsonExporter {
  /// Encodes the given [ExplanationReport] into a compact canonical JSON string.
  static String export(ExplanationReport report) {
    return CanonicalJsonEncoder.encode(report.toJson());
  }

  /// Encodes the given [ExplanationReport] into a pretty-printed canonical JSON string for debugging.
  static String exportPretty(ExplanationReport report) {
    return CanonicalJsonEncoder.encodePretty(report.toJson());
  }
}
