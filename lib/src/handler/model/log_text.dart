part of '../handler.dart';

/// A styled text segment with semantic tags.
@immutable
class StyledText {
  /// Creates a semantically tagged text segment.
  const StyledText(
    this.text, {
    this.tags = const {},
    this.style,
  });

  /// The textual content.
  final String text;

  /// Semantic tags describing this segment.
  final Set<LogTag> tags;

  /// Optional visual style suggestion.
  final LogStyle? style;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is StyledText &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          style == other.style &&
          setEquals(tags, other.tags);

  @override
  int get hashCode => text.hashCode ^ style.hashCode ^ Object.hashAll(tags);

  @override
  String toString() => text;
}
