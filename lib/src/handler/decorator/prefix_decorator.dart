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
    final LogContext context,
  ) {
    if (document.nodes.isEmpty) {
      return document;
    }

    return LogDocument(
      nodes: document.nodes.map(_decorateNode).toList(),
      metadata: document.metadata,
    );
  }

  LogNode _decorateNode(final LogNode node) {
    if (node is ContentNode || node is DecoratedNode) {
      return DecoratedNode(
        children: [node],
        leadingWidth: prefix.visibleLength,
        leading: [
          StyledText(prefix, tags: const {LogTag.prefix}, style: style),
        ],
        // Prefix shouldn't force right-alignment of trailing space by itself
        alignTrailing: false,
      );
    }

    if (node is LayoutNode) {
      return switch (node) {
        final BoxNode n => BoxNode(
            children: n.children.map(_decorateNode).toList(),
            border: n.border,
            style: n.style,
            title: n.title,
            tags: n.tags,
          ),
        final IndentationNode n => IndentationNode(
            children: n.children.map(_decorateNode).toList(),
            indentString: n.indentString,
            style: n.style,
            tags: n.tags,
          ),
        final DecoratedNode _ =>
          throw StateError('Should be handled by first if'),
        final GroupNode n => GroupNode(
            children: n.children.map(_decorateNode).toList(),
            title: n.title,
            tags: n.tags,
          ),
      };
    }

    return node;
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
