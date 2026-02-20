part of '../handler.dart';

/// An intermediate, "camera-ready" representation of a log document.
///
/// This structure represents the final physical geometry of a log (lines,
/// segments) after layout processing (wrapping, boxing, indentation) but
/// before it is serialized into a specific output format (like ANSI escape
/// codes or HTML).
///
/// This is used internally by [LogEncoder]s to separate layout calculation
/// from visual styling.
@immutable
class PhysicalDocument {
  /// Creates a [PhysicalDocument].
  const PhysicalDocument({
    required this.lines,
  });

  /// The sequence of physical lines in the document.
  final List<PhysicalLine> lines;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is PhysicalDocument && listEquals(lines, other.lines);

  @override
  int get hashCode => Object.hashAll(lines);
}

/// A single line in a [PhysicalDocument].
@immutable
class PhysicalLine {
  /// Creates a [PhysicalLine].
  const PhysicalLine({
    required this.segments,
  });

  /// The styled segments that make up this line.
  final List<StyledText> segments;

  /// Returns the total visible length of the line (excluding escape codes).
  ///
  /// If startX is provided, it accounts for the absolute position for correct
  /// TAB expansion.
  int get visibleLength => getVisibleLength(startX: 0);

  /// Calculates the visible length starting from [startX].
  int getVisibleLength({final int startX = 0}) {
    var length = 0;
    var currentPos = startX;
    for (final segment in segments) {
      for (final char in segment.text.characters) {
        if (char == '\t') {
          final advance = 8 - (currentPos % 8);
          length += advance;
          currentPos += advance;
        } else {
          final advance = isWide(char) ? 2 : 1;
          length += advance;
          currentPos += advance;
        }
      }
    }
    return length;
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is PhysicalLine && listEquals(segments, other.segments);

  @override
  int get hashCode => Object.hashAll(segments);

  /// Returns a new [PhysicalLine] truncated to the [targetWidth].
  ///
  /// This is used to ensure physical integrity of structural elements (like
  /// boxes) when content overflows.
  /// Returns a new [PhysicalLine] truncated to the [targetWidth].
  ///
  /// This is used to ensure physical integrity of structural elements (like
  /// boxes) when content overflows.
  ///
  /// [startX] specifies the starting visual offset (default 0). This is
  /// critical for accurate truncation of content containing tabs, as their
  /// width varies based on position.
  PhysicalLine truncate(final int targetWidth, {final int startX = 0}) {
    if (getVisibleLength(startX: startX) <= targetWidth) {
      return this;
    }

    final newSegments = <StyledText>[];
    var currentWidth = 0; // Relative visual width from startX
    var absolutePos = startX;

    for (final segment in segments) {
      final remaining = targetWidth - currentWidth;
      if (remaining <= 0) {
        break;
      }

      final segmentWidth = _getSegmentVisibleLength(segment, absolutePos);
      if (currentWidth + segmentWidth <= targetWidth) {
        newSegments.add(segment);
        currentWidth += segmentWidth;
        absolutePos += segmentWidth;
      } else {
        // Partial segment truncation
        var truncatedText = '';
        var subWidth = 0;
        var subPos = absolutePos;
        for (final char in segment.text.characters) {
          final charWidth =
              (char == '\t') ? (8 - (subPos % 8)) : (isWide(char) ? 2 : 1);
          if (subWidth + charWidth <= remaining) {
            truncatedText += char;
            subWidth += charWidth;
            subPos += charWidth;
          } else {
            break;
          }
        }
        if (truncatedText.isEmpty && subWidth == 0 && newSegments.isEmpty) {
          // Edge case: First char doesn't fit?
          // Just break loop.
        } else if (truncatedText.isNotEmpty) {
          newSegments.add(
            StyledText(
              truncatedText,
              style: segment.style,
              tags: segment.tags,
            ),
          );
        }
        currentWidth += subWidth;
        absolutePos += subWidth;
        break;
      }
    }

    return PhysicalLine(segments: newSegments);
  }

  int _getSegmentVisibleLength(final StyledText segment, final int startPos) {
    var length = 0;
    var currentPos = startPos;
    for (final char in segment.text.characters) {
      if (char == '\t') {
        final advance = 8 - (currentPos % 8);
        length += advance;
        currentPos += advance;
      } else {
        final advance = isWide(char) ? 2 : 1;
        length += advance;
        currentPos += advance;
      }
    }
    return length;
  }

  @override
  String toString() => segments.map((final s) => s.text).join();
}
