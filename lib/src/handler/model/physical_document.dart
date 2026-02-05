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
  int get visibleLength {
    var length = 0;
    for (final segment in segments) {
      for (final char in segment.text.characters) {
        if (char == '\t') {
          length += 8 - (length % 8);
        } else {
          length += isWide(char) ? 2 : 1;
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

  @override
  String toString() => segments.map((final s) => s.text).join();
}
