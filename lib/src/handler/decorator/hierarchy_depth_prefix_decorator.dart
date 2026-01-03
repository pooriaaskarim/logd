part of '../handler.dart';

/// A [LogDecorator] that adds a tree-like hierarchy visualization based on the
/// [LogEntry.hierarchyDepth].
@immutable
final class HierarchyDepthPrefixDecorator extends StructuralDecorator {
  /// Creates a [HierarchyDepthPrefixDecorator].
  ///
  /// - [indent]: The string used for each level of depth (default: '│   ').
  /// - [prefix]: An optional prefix to add before the indentation.
  const HierarchyDepthPrefixDecorator({
    this.indent = '│ ',
    this.prefix = '',
  });

  /// The string used for each level of depth.
  final String indent;

  /// An optional fixed prefix.
  final String prefix;

  @override
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
  ) {
    final depthStr = indent * entry.hierarchyDepth;
    final fullPrefix = '$prefix$depthStr';

    return lines
        .map((final l) => LogLine('$fullPrefix${l.text}', tags: l.tags));
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is HierarchyDepthPrefixDecorator &&
          runtimeType == other.runtimeType &&
          indent == other.indent &&
          prefix == other.prefix;

  @override
  int get hashCode => indent.hashCode ^ prefix.hashCode;
}
