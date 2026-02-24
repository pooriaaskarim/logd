part of '../handler.dart';

/// A [LogDecorator] that applies semantic styles to a [LogDocument] based on a
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
    final LogArena arena,
  ) {
    final snapshot = document.nodes.toList();
    document.nodes
      ..clear()
      ..addAll(snapshot.map((final node) => _styleNode(node, entry.level)));
    return document;
  }

  LogNode _styleNode(final LogNode node, final LogLevel level) =>
      switch (node) {
        final ContentNode n => n.copyWith(
            segments: n.segments
                .map((final s) => _styleStyledText(s, level))
                .toList(),
          ),
        final BoxNode n => n.copyWith(
            style: _mergeStyles(theme.getStyle(level, n.tags), n.style),
            title: n.title != null ? _styleStyledText(n.title!, level) : null,
            children:
                n.children.map((final c) => _styleNode(c, level)).toList(),
          ),
        final IndentationNode n => n.copyWith(
            style: _mergeStyles(theme.getStyle(level, n.tags), n.style),
            children:
                n.children.map((final c) => _styleNode(c, level)).toList(),
          ),
        final DecoratedNode n => n.copyWith(
            style: _mergeStyles(theme.getStyle(level, n.tags), n.style),
            leading: n.leading
                ?.map((final s) => _styleStyledText(s, level))
                .toList(),
            trailing: n.trailing
                ?.map((final s) => _styleStyledText(s, level))
                .toList(),
            children:
                n.children.map((final c) => _styleNode(c, level)).toList(),
          ),
        final GroupNode n => n.copyWith(
            children:
                n.children.map((final c) => _styleNode(c, level)).toList(),
          ),
        final ParagraphNode n => n.copyWith(
            children:
                n.children.map((final c) => _styleNode(c, level)).toList(),
          ),
        final RowNode n => n.copyWith(
            children:
                n.children.map((final c) => _styleNode(c, level)).toList(),
          ),
        final FillerNode n => n.copyWith(
            style: _mergeStyles(theme.getStyle(level, n.tags), n.style),
          ),
        final MapNode n => n,
        final ListNode n => n,
      };

  StyledText _styleStyledText(final StyledText s, final LogLevel level) {
    final themeStyle = theme.getStyle(level, s.tags);
    return s.copyWith(style: _mergeStyles(themeStyle, s.style));
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
    final int? tags,
    final LogStyle? style,
  }) =>
      StyledText(
        text ?? this.text,
        tags: tags ?? this.tags,
        style: style ?? this.style,
      );
}
