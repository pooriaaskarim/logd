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
  LogDocument decorate(
    final LogDocument document,
    final LogEntry entry,
  ) {
    if (prefix.isEmpty) {
      return document;
    }

    return document.copyWith(
      nodes: [
        DecoratedNode(
          leadingWidth: prefix.visibleLength,
          leading: [
            StyledText(prefix, tags: LogTag.prefix, style: style),
          ],
          repeatLeading: true,
          children: document.nodes,
        ),
      ],
    );
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
