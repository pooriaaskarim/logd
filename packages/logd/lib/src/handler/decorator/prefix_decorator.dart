part of '../handler.dart';

/// A [LogDecorator] that prepends a fixed string to each log line.
@immutable
final class PrefixDecorator extends ContentDecorator {
  /// Creates a [PrefixDecorator] with the given [prefix].
  ///
  /// - [prefix]: The string to prepend.
  /// - [style]: Optional style for the prefix.
  const PrefixDecorator(this.prefix, {this.style});

  /// The prefix to prepend.
  final String prefix;

  /// Optional style for the prefix.
  final LogStyle? style;

  @override
  void decorate(
    final LogDocument document,
    final LogEntry entry,
    final LogPipelineFactory factory,
  ) {
    if (prefix.isEmpty) {
      return;
    }

    final snapshot = document.nodes.toList();
    document.nodes.clear();
    for (final child in snapshot) {
      final node = factory.checkoutDecorated()
        ..leadingWidth = prefix.visibleLength
        ..leading = [StyledText(prefix, tags: LogTag.prefix, style: style)]
        ..repeatLeading = true
        ..alignTrailing = false
        ..children.add(child);
      document.nodes.add(node);
    }
  }

  @override
  int paddingWidth(final LogEntry entry) => prefix.visibleLength;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is PrefixDecorator &&
          runtimeType == other.runtimeType &&
          prefix == other.prefix &&
          style == other.style;

  @override
  int get hashCode => Object.hash(prefix, style);
}
