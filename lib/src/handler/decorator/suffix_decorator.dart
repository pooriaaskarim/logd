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
        trailingWidth: suffix.visibleLength,
        trailing: [
          StyledText(suffix, tags: const {LogTag.suffix}, style: style),
        ],
        alignTrailing: aligned,
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
