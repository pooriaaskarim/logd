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

  /// Returns the visible length of the string, excluding ANSI escape sequences.
  int get visibleLength => replaceAll(_ansiRegex, '').length;

  /// Pads this string on the right to [width] visible characters.
  String padVisible(final int width, [final String padding = ' ']) {
    final visible = visibleLength;
    if (visible >= width) {
      return this;
    }
    return this + padding * (width - visible);
  }

  /// Removes all ANSI escape sequences from the string.
  String get stripAnsi => replaceAll(_ansiRegex, '');

  /// Wraps this string into multiple lines, each with a visible length
  /// at most [width].
  ///
  /// This is a basic implementation that does not currently preserve
  /// ANSI state across line breaks.
  Iterable<String> wrapVisible(final int width) sync* {
    if (visibleLength <= width) {
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
      var end = start + width;
      if (end > raw.length) {
        end = raw.length;
      }

      // Find visible width of this chunk
      var chunk = raw.substring(start, end);
      while (chunk.visibleLength > width && chunk.length > 1) {
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
}
