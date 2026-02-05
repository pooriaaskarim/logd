part of '../handler.dart';

/// A [LogDecorator] that applies semantic styles to log lines based on a
/// [LogTheme].
///
/// This decorator resolves the appropriate [LogStyle] for each segment using
/// the provided [theme] (or a default if none is provided).
///
/// Example:
/// ```dart
/// StyleDecorator(theme: LogTheme(
///   colorScheme: LogColorScheme.darkScheme,
///   levelStyle: LogStyle(bold: true), // Make levels bold
/// ))
/// ```
@immutable
final class StyleDecorator extends VisualDecorator {
  /// Creates a [StyleDecorator].
  ///
  /// [theme] defines the styling rules. Defaults to using
  /// [LogColorScheme.defaultScheme].
  const StyleDecorator({
    this.theme = const LogTheme(colorScheme: LogColorScheme.defaultScheme),
  });

  /// The theme used to resolve styles.
  final LogTheme theme;

  @override
  LogDocument decorate(
    final LogDocument document,
    final LogEntry entry,
    final LogContext context,
  ) {
    if (document.nodes.isEmpty) {
      return document;
    }

    final newNodes = <LogNode>[];
    for (final node in document.nodes) {
      newNodes.add(_styleNode(node, entry.level));
    }

    return LogDocument(
      nodes: newNodes,
      metadata: document.metadata,
    );
  }

  LogNode _styleNode(final LogNode node, final LogLevel level) {
    if (node is ContentNode) {
      final newSegments = <StyledText>[];
      for (final segment in node.segments) {
        // Resolve style from theme based on tags
        final themeStyle = theme.getStyle(level, segment.tags);

        // Merge with existing style (existing beats theme)
        final combinedStyle = _mergeStyles(themeStyle, segment.style);

        if (combinedStyle != segment.style) {
          newSegments.add(segment.copyWith(style: combinedStyle));
        } else {
          newSegments.add(segment);
        }
      }
      return switch (node) {
        final HeaderNode n => HeaderNode(segments: newSegments, tags: n.tags),
        final MessageNode n => MessageNode(segments: newSegments, tags: n.tags),
        final FooterNode n => FooterNode(segments: newSegments, tags: n.tags),
        final MetadataNode n => MetadataNode(
            segments: newSegments,
            tags: n.tags,
          ),
        final ErrorNode n => ErrorNode(segments: newSegments, tags: n.tags),
      };
    } else if (node is LayoutNode) {
      final themeStyle = theme.resolveNodeStyle(node, level);

      List<LogNode> styleChildren(final List<LogNode> children) =>
          children.map((final child) => _styleNode(child, level)).toList();

      return switch (node) {
        final BoxNode c => BoxNode(
            children: styleChildren(c.children),
            border: c.border,
            style: _mergeStyles(themeStyle, c.style),
            title: c.title,
            tags: c.tags,
          ),
        final IndentationNode c => IndentationNode(
            children: styleChildren(c.children),
            indentString: c.indentString,
            style: _mergeStyles(themeStyle, c.style),
            tags: c.tags,
          ),
        final DecoratedNode c => DecoratedNode(
            children: styleChildren(c.children),
            leadingWidth: c.leadingWidth,
            trailingWidth: c.trailingWidth,
            leadingHint: c.leadingHint,
            trailingHint: c.trailingHint,
            leading: c.leading != null
                ? c.leading!
                    .map((final s) => s.copyWith(
                          style: _mergeStyles(
                              theme.getStyle(level, s.tags), s.style),
                        ))
                    .toList()
                : null,
            trailing: c.trailing != null
                ? c.trailing!
                    .map((final s) => s.copyWith(
                          style: _mergeStyles(
                              theme.getStyle(level, s.tags), s.style),
                        ))
                    .toList()
                : null,
            alignTrailing: c.alignTrailing,
            style: _mergeStyles(themeStyle, c.style),
            title: c.title,
            tags: c.tags,
          ),
        final GroupNode c => GroupNode(
            children: styleChildren(c.children),
            title: c.title,
            tags: c.tags,
          ),
      };
    }

    // Default passthrough if we add new node types later
    return node;
  }

  LogStyle? _mergeStyles(final LogStyle themeStyle, final LogStyle? existing) {
    if (existing == null) {
      return themeStyle;
    }

    // Existing values override theme values
    return LogStyle(
      color: existing.color ?? themeStyle.color,
      backgroundColor: existing.backgroundColor ?? themeStyle.backgroundColor,
      bold: existing.bold ?? themeStyle.bold,
      dim: existing.dim ?? themeStyle.dim,
      italic: existing.italic ?? themeStyle.italic,
      inverse: existing.inverse ?? themeStyle.inverse,
    );
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is StyleDecorator &&
          runtimeType == other.runtimeType &&
          theme == other.theme;

  @override
  int get hashCode => theme.hashCode;
}

/// Deprecated alias for [StyleDecorator].
@Deprecated('Use [StyleDecorator] instead')
typedef ColorDecorator = StyleDecorator;

extension _StyledTextCopy on StyledText {
  StyledText copyWith({
    final String? text,
    final Set<LogTag>? tags,
    final LogStyle? style,
  }) =>
      StyledText(
        text ?? this.text,
        tags: tags ?? this.tags,
        style: style ?? this.style,
      );
}
