part of '../handler.dart';

/// Represents a single line in a log output, composed of semantic segments.
@immutable
class LogLine {
  /// Creates a [LogLine] from a list of segments.
  const LogLine(this.segments);

  /// Creates a [LogLine] with a single plain text segment.
  factory LogLine.text(final String text) => LogLine([StyledText(text)]);

  /// The semantic segments that make up this line.
  final List<StyledText> segments;

  /// The visible width of the line.
  ///
  /// Calculates the maximum terminal width across all physical lines generated
  /// by the segments, correctly accounting for TAB stops (8 cells) across
  /// segment boundaries.
  int get visibleLength {
    if (segments.isEmpty) {
      return 0;
    }

    var maxWidth = 0;
    var currentX = 0;

    for (final segment in segments) {
      final text = segment.text;
      if (text.isEmpty) {
        continue;
      }

      // Handle segments that might contain physical newlines
      final physicalLines = text.split(RegExp(r'\r?\n'));

      for (int i = 0; i < physicalLines.length; i++) {
        if (i > 0) {
          // New physical line within a segment
          if (currentX > maxWidth) {
            maxWidth = currentX;
          }
          currentX = 0;
        }

        final linePart = physicalLines[i].stripAnsi;
        for (final char in linePart.characters) {
          if (char == '\t') {
            currentX += 8 - (currentX % 8);
          } else {
            currentX += isWide(char) ? 2 : 1;
          }
        }
      }
    }

    return currentX > maxWidth ? currentX : maxWidth;
  }

  /// Wraps this line into multiple lines, preserving semantic segments.
  Iterable<LogLine> wrap(final int width, {final String indent = ''}) sync* {
    // If indent is provided, we need to wrap tighter so indented lines
    // don't exceed the width
    final indentWidth = indent.visibleLength;
    final wrapWidth =
        indentWidth > 0 ? (width - indentWidth).clamp(1, width) : width;

    final parts = segments.map((final s) => (s.text, (s.tags, s.style)));
    final wrapped = wrapWithData(
      parts,
      wrapWidth,
    );

    var isFirst = true;
    for (final lineParts in wrapped) {
      final lineSegments = lineParts
          .map(
            (final p) => StyledText(
              p.$1,
              tags: p.$2.$1,
              style: p.$2.$2,
            ),
          )
          .toList();

      if (!isFirst && indent.isNotEmpty) {
        lineSegments.insert(0, StyledText(indent));
      }

      yield LogLine(lineSegments);
      isFirst = false;
    }
  }

  @override
  String toString() => segments.map((final s) => s.text).join();
}
