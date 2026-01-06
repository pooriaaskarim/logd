import 'package:meta/meta.dart';

/// Internal utility for list equality.
@internal
bool listEquals<T>(final List<T>? a, final List<T>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

/// Internal utility for map equality.
@internal
bool mapEquals<K, V>(final Map<K, V>? a, final Map<K, V>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (final K key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) {
      return false;
    }
  }
  return true;
}

/// Extension for ANSI-aware string manipulations.
@internal
extension AnsiStringExtension on String {
  static final _ansiRegex = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');
  static const _ansiReset = '\x1B[0m';

  /// Returns the visible length of the string, excluding ANSI escape sequences.
  int get visibleLength => replaceAll(_ansiRegex, '').length;

  /// Pads this string on the right to [width] visible characters,
  /// preserving leading ANSI sequences and ensuring padding is styled.
  ///
  /// If the string has leading ANSI (e.g., color), the padding is added
  /// to the stripped text, then the ANSI is reapplied around the padded
  /// content with reset at the end. This ensures padding inherits the style
  /// (e.g., background/inverse), preventing "gaps" or "weird" appearance
  /// in styled lines (like headers with inverse).
  String padRightVisiblePreserveAnsi(
    final int width, [
    final String padding = ' ',
  ]) {
    final safeWidth = width.clamp(1, double.infinity).toInt();
    final visible = visibleLength;
    if (visible >= safeWidth) {
      return this;
    }
    // Extract all leading ANSI escape sequences
    final ansiRegex = RegExp(r'^(?:\x1B\[[0-?]*[ -/]*[@-~])+');
    final match = ansiRegex.firstMatch(this);
    final ansiPrefix = match?.group(0) ?? '';
    // Get visible text without ANSI codes for padding
    final visibleText = stripAnsi;
    // Pad the visible text
    final paddedText = visibleText.padRight(safeWidth, padding);
    // Reapply ANSI prefix to padded text with reset at end
    return '$ansiPrefix$paddedText$_ansiReset';
  }

  /// Removes all ANSI escape sequences from the string.
  String get stripAnsi => replaceAll(_ansiRegex, '');

  /// Wraps this string into multiple lines, each with a visible length
  /// at most [width].
  ///
  /// This is a basic implementation that does not currently preserve
  /// ANSI state across line breaks.
  ///
  /// If [width] is less than 1, it is clamped to 1 to prevent issues.
  Iterable<String> wrapVisible(final int width) sync* {
    // Ensure width is at least 1
    final safeWidth = width.clamp(1, double.infinity).toInt();

    if (visibleLength <= safeWidth) {
      yield this;
      return;
    }

    final raw = this;
    var start = 0;

    // This is a naive implementation: it finds safe breakpoints
    // based on technical length but checks visible width.
    // Truly robust multi-line ANSI wrapping is complex, but this
    // will fix the "scattered box" issue for most cases.

    while (start < raw.length) {
      var end = start + safeWidth;
      if (end > raw.length) {
        end = raw.length;
      }

      // Find visible width of this chunk
      var chunk = raw.substring(start, end);
      while (chunk.visibleLength > safeWidth && chunk.length > 1) {
        end--;
        chunk = raw.substring(start, end);
      }

      // Try to break at space
      if (end < raw.length && !raw[end].contains(RegExp(r'\s'))) {
        final space = raw.lastIndexOf(' ', end);
        if (space > start) {
          end = space;
          chunk = raw.substring(start, end);
        }
      }

      yield chunk.trimRight();
      start = end;
      while (start < raw.length && raw[start].contains(RegExp(r'\s'))) {
        start++;
      }
    }
  }

  /// Wraps this string preserving ANSI escape codes across line breaks.
  ///
  /// ANSI codes at the start are preserved and applied to each wrapped line.
  /// The reset code (\x1B[0m) is added at the end of each line to prevent
  /// style leakage.
  ///
  /// If [width] is less than 1, it is clamped to 1 to prevent issues.
  Iterable<String> wrapVisiblePreserveAnsi(final int width) sync* {
    // Ensure width is at least 1
    final safeWidth = width.clamp(1, double.infinity).toInt();

    final visible = visibleLength;
    if (visible <= safeWidth) {
      yield this;
      return;
    }
    // Extract all leading ANSI escape sequences
    final ansiRegex = RegExp(r'^(?:\x1B\[[0-?]*[ -/]*[@-~])+');
    final match = ansiRegex.firstMatch(this);
    final ansiPrefix = match?.group(0) ?? '';
    // Get visible text without ANSI codes for wrapping
    final visibleText = stripAnsi;
    // Wrap the visible text
    final lines = visibleText.wrapVisible(safeWidth).toList();
    // Apply ANSI prefix to each wrapped line
    for (var i = 0; i < lines.length; i++) {
      // Add reset at end of each line to prevent leakage
      yield '$ansiPrefix${lines[i]}$_ansiReset';
    }
  }
}
