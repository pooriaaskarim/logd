part of '../handler.dart';

/// A [LogDecorator] that appends a fixed string to each log line.
@immutable
final class SuffixDecorator extends ContentDecorator {
  /// Creates a [SuffixDecorator] with the given [suffix].
  ///
  /// - [suffix]: The string to append to each line.
  /// - [aligned]: Whether to align the suffix to the end of the available
  /// width. Defaults to true.
  /// - [style]: Optional style for the suffix.
  const SuffixDecorator(
    this.suffix, {
    this.aligned = true,
    this.style,
  });

  /// The suffix string to append.
  final String suffix;

  /// Whether to align the suffix to the right edge.
  final bool aligned;

  /// Optional style for the suffix.
  final LogStyle? style;

  @override
  void decorate(
    final LogDocument document,
    final LogEntry entry,
    final LogNodeFactory factory,
  ) {
    if (suffix.isEmpty) {
      return;
    }

    final node = factory.checkoutDecorated()
      ..trailingWidth = suffix.visibleLength
      ..trailing = [StyledText(suffix, tags: LogTag.suffix, style: style)]
      ..repeatTrailing = true
      ..alignTrailing = aligned
      ..children.addAll(document.nodes);
    document.nodes
      ..clear()
      ..add(node);
  }

  @override
  int paddingWidth(final LogEntry entry) => suffix.visibleLength;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is SuffixDecorator &&
          runtimeType == other.runtimeType &&
          suffix == other.suffix &&
          style == other.style &&
          aligned == other.aligned;

  @override
  int get hashCode => Object.hash(suffix, aligned, style);
}
