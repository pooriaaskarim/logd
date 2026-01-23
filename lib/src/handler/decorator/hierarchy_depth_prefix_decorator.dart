part of '../handler.dart';

/// A [LogDecorator] that adds a tree-like hierarchy visualization based on the
/// [LogEntry.hierarchyDepth].
@immutable
final class HierarchyDepthPrefixDecorator extends StructuralDecorator {
  /// Creates a [HierarchyDepthPrefixDecorator].
  ///
  /// - [indent]: The string used for each level of depth (default: '│   ').
  const HierarchyDepthPrefixDecorator({
    this.indent = '│ ',
  });

  /// The string used for each level of depth.
  final String indent;

  @override
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
    final LogContext context,
  ) {
    if (entry.hierarchyDepth <= 0) {
      return lines;
    }

    final depthStr = indent * entry.hierarchyDepth;
    final prefixSegment = LogSegment(depthStr, tags: const {LogTag.hierarchy});

    return lines.map((final l) => LogLine([prefixSegment, ...l.segments]));
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is HierarchyDepthPrefixDecorator &&
          runtimeType == other.runtimeType &&
          indent == other.indent;

  @override
  int get hashCode => indent.hashCode;
}
