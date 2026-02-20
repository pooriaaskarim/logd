part of '../handler.dart';

/// A [LogDecorator] that adds a tree-like hierarchy visualization based on the
/// [LogEntry.hierarchyDepth].
@immutable
final class HierarchyDepthPrefixDecorator extends StructuralDecorator {
  /// Creates a [HierarchyDepthPrefixDecorator].
  ///
  /// - [indent]: The string used for each level of depth (default: '│   ').
  /// - [style]: Optional style for the hierarchy prefix.
  const HierarchyDepthPrefixDecorator({
    this.indent = '│ ',
    this.style,
  });

  /// The string used for each level of depth.
  final String indent;

  /// Optional style for the hierarchy prefix.
  final LogStyle? style;

  @override
  LogDocument decorate(
    final LogDocument document,
    final LogEntry entry,
    
  ) {
    if (entry.hierarchyDepth <= 0) {
      return document;
    }

    var nodes = document.nodes;
    for (var i = 0; i < entry.hierarchyDepth; i++) {
      nodes = [
        IndentationNode(
          indentString: indent,
          style: style,
          children: nodes,
        ),
      ];
    }

    return document.copyWith(nodes: nodes);
  }

  @override
  int paddingWidth(final LogEntry entry) =>
      indent.visibleLength * entry.hierarchyDepth;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is HierarchyDepthPrefixDecorator &&
          runtimeType == other.runtimeType &&
          indent == other.indent &&
          style == other.style;

  @override
  int get hashCode => Object.hash(indent, style);
}
