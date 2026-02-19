part of '../handler.dart';

/// A semantic segment of a log line.
///
/// Holds the textual content and metadata (tags) describing it.
@immutable
class StyledText {
  /// Creates a [StyledText].
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
          _setEquals(tags, other.tags);

  @override
  int get hashCode => text.hashCode ^ style.hashCode ^ Object.hashAll(tags);

  bool _setEquals<T>(final Set<T> a, final Set<T> b) {
    if (a.length != b.length) {
      return false;
    }
    return a.containsAll(b);
  }
}
