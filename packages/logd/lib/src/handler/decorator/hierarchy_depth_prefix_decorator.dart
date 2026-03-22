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
  void decorate(
    final LogDocument document,
    final LogEntry entry,
    final LogPipelineFactory factory,
  ) {
    if (entry.hierarchyDepth <= 0) {
      return;
    }

    final snapshot = document.nodes.toList();
    document.nodes.clear();

    for (var child in snapshot) {
      for (var i = 0; i < entry.hierarchyDepth; i++) {
        final node = factory.checkoutIndentation()
          ..indentString = indent
          ..style = style
          ..children.add(child);
        child = node;
      }
      document.nodes.add(child);
    }
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
