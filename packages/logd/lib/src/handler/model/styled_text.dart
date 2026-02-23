part of '../handler.dart';

/// A semantic segment of a log line.
///
/// Holds the textual content and metadata (tags) describing it.
@immutable
class StyledText {
  /// Creates a [StyledText].
  const StyledText(
    this.text, {
    this.tags = LogTag.none,
    this.style,
  });

  /// The textual content.
  final String text;

  /// Semantic tags describing this segment.
  final int tags;

  /// Optional visual style suggestion.
  final LogStyle? style;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is StyledText &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          style == other.style &&
          tags == other.tags;

  @override
  int get hashCode => text.hashCode ^ style.hashCode ^ tags.hashCode;
}
