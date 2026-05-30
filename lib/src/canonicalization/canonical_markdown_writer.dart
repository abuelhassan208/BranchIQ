import 'dart:math' as math;
import 'canonicalization_exceptions.dart';

/// Provides deterministic and normalized markdown generation primitives for reporting and golden tests.
class CanonicalMarkdownWriter {
  /// Generates a standard markdown heading with exact spacing.
  ///
  /// Enforces heading level in range 1-6 and trims trailing whitespace.
  static String heading(int level, String text) {
    if (level < 1 || level > 6) {
      throw const CanonicalMarkdownException(
          'Markdown heading level must be between 1 and 6.');
    }
    final trimmedText = text.trim();
    return '${'#' * level} $trimmedText\n';
  }

  /// Generates a bullet point with a dash marker.
  static String bullet(String text) {
    final trimmedText = text.trim();
    return '- $trimmedText\n';
  }

  /// Generates a column-aligned, stable markdown table.
  ///
  /// Verifies that all rows contain the same number of columns as the headers list.
  /// Dynamically aligns columns with padding spaces to guarantee stable aesthetics.
  static String table(List<String> headers, List<List<String>> rows) {
    if (headers.isEmpty) {
      throw const CanonicalMarkdownException(
          'Table must have at least one header.');
    }

    final headerCount = headers.length;
    for (int i = 0; i < rows.length; i++) {
      if (rows[i].length != headerCount) {
        throw CanonicalMarkdownException(
          'Row at index $i has ${rows[i].length} cells, but table expects $headerCount headers.',
        );
      }
    }

    // Determine the maximum width for each column to ensure fixed-alignment formatting.
    // Separator line ':---' requires at least 4 characters.
    final colWidths = List<int>.generate(headerCount, (colIndex) {
      int maxWidth = math.max(headers[colIndex].trim().length, 4);
      for (final row in rows) {
        maxWidth = math.max(maxWidth, row[colIndex].trim().length);
      }
      return maxWidth;
    });

    final buffer = StringBuffer();

    // 1. Build Header Row
    buffer.write('|');
    for (int i = 0; i < headerCount; i++) {
      final headerStr = headers[i].trim().padRight(colWidths[i]);
      buffer.write(' $headerStr |');
    }
    buffer.write('\n');

    // 2. Build Separator Row (e.g. | :--- | :--- |)
    buffer.write('|');
    for (int i = 0; i < headerCount; i++) {
      final sepStr = ':---'.padRight(colWidths[i], '-');
      buffer.write(' $sepStr |');
    }
    buffer.write('\n');

    // 3. Build Data Rows
    for (final row in rows) {
      buffer.write('|');
      for (int i = 0; i < headerCount; i++) {
        final cellStr = row[i].trim().padRight(colWidths[i]);
        buffer.write(' $cellStr |');
      }
      buffer.write('\n');
    }

    return normalize(buffer.toString());
  }

  /// Normalizes all newlines to LF ('\n'), removes trailing space from all lines,
  /// and guarantees that the document ends with exactly one newline.
  static String normalize(String markdown) {
    final lines =
        markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

    final normalizedLines = lines.map((line) => line.trimRight()).toList();

    var result = normalizedLines.join('\n');
    result = result.trimRight();

    if (result.isEmpty) {
      return '\n';
    }
    return '$result\n';
  }
}
