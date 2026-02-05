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
    final LogContext context,
  ) {
    if (entry.hierarchyDepth <= 0) {
      return document;
    }

    // Wrap the existing blocks in a hierarchy container.
    // We can nest containers to represent depth, but typically the encoder
    // handles depth calculations. However, since this decorator
    // is manually applied, we effectively just mark "this structure is
    // hierarchical".
    //
    // To support the existing behavior where the loop in Handler might call
    // this, we simply return a container implementation.
    //
    // Note: In the new architecture, the Encoder usually handles hierarchy
    // simply by checking entry.hierarchyDepth if it wants to.
    // But if we want to force manual hierarchy injection via decorators,
    // we use a Container.

    return LogDocument(
      nodes: [
        IndentationNode(
          children: document.nodes,
          indentString: indent * entry.hierarchyDepth,
          style: style,
        ),
      ],
      metadata: document.metadata,
    );
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
