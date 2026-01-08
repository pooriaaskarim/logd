import 'package:characters/characters.dart';
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

  /// Returns the estimated terminal cell width of the string, excluding ANSI
  /// codes.
  ///
  /// Wide characters (CJK, Emojis) are counted as 2 cells, others as 1.
  int get visibleLength {
    final stripped = stripAnsi;
    int width = 0;
    for (final char in stripped.characters) {
      width += _isWide(char) ? 2 : 1;
    }
    return width;
  }

  /// Whether the character is likely to take 2 terminal cells (Wide/Emoji).
  bool _isWide(final String char) {
    if (char.length > 1) {
      // It's a surrogate pair or multi-char cluster (likely emoji/complex char)
      return true;
    }
    final code = char.codeUnitAt(0);
    // Simple heuristic for CJK and other wide characters:
    // 0x1100-0x115F: Hangul Jamo
    // 0x2E80-0xA4CF: CJK Radicals, Symbols, Punctuation, Japanese, Chinese, Yi
    // 0xAC00-0xD7A3: Hangul Syllables
    // 0xF900-0xFAFF: CJK Compatibility Ideographs
    // 0xFE10-0xFE19: Vertical forms
    // 0xFE30-0xFE6F: CJK Compatibility Forms
    // 0xFF00-0xFF60: Fullwidth Forms
    // 0xFFE0-0xFFE6: Fullwidth Forms
    return (code >= 0x1100 && code <= 0x115F) ||
        (code >= 0x2E80 && code <= 0xA4CF) ||
        (code >= 0xAC00 && code <= 0xD7A3) ||
        (code >= 0xF900 && code <= 0xFAFF) ||
        (code >= 0xFE10 && code <= 0xFE19) ||
        (code >= 0xFE30 && code <= 0xFE6F) ||
        (code >= 0xFF00 && code <= 0xFF60) ||
        (code >= 0xFFE0 && code <= 0xFFE6);
  }

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

    final stripped = stripAnsi;
    if (visibleLength <= safeWidth) {
      yield this;
      return;
    }

    final chars = stripped.characters.toList();
    var current = 0;

    while (current < chars.length) {
      int accumulatedWidth = 0;
      int breakIndex = current;
      int? lastSpaceIndex;

      // Find how many characters fit in [safeWidth] cell units
      for (int i = current; i < chars.length; i++) {
        final char = chars[i];
        final charWidth = _isWide(char) ? 2 : 1;

        if (accumulatedWidth + charWidth > safeWidth) {
          break;
        }

        accumulatedWidth += charWidth;
        breakIndex = i + 1;
        if (char == ' ') {
          lastSpaceIndex = i;
        }
      }

      // If we found a space and we are not at the end of the string, break
      // there
      if (lastSpaceIndex != null && breakIndex < chars.length) {
        breakIndex = lastSpaceIndex; // break before the space
      }

      final chunk = chars.sublist(current, breakIndex).join();
      yield chunk.trimRight();

      current = breakIndex;
      // Skip leading spaces on the next line
      while (current < chars.length && chars[current] == ' ') {
        current++;
      }

      // Safety break for empty progress
      if (accumulatedWidth == 0 && current < chars.length) {
        // If a single character is wider than safeWidth, we must include it
        // anyway
        // or we'll loop forever.
        final char = chars[current];
        yield char;
        current++;
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
