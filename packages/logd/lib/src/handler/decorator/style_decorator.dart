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
  void decorate(
    final LogDocument document,
    final LogEntry entry,
    final LogPipelineFactory factory,
  ) {
    for (final node in document.nodes) {
      _applyStyle(node, entry.level, factory);
    }
  }

  void _applyStyle(
    final LogNode node,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) {
    switch (node) {
      case final ContentNode n:
        try {
          final segments = n.segments;
          for (int i = 0; i < segments.length; i++) {
            segments[i] = _styleStyledText(segments[i], level);
          }
        } catch (_) {
          // If the list was unmodifiable (e.g. from a legacy formatter),
          // replace it with a pooled modifiable list.
          final segments = factory.checkoutDataList<StyledText>()
            ..addAll(n.segments);
          for (int i = 0; i < segments.length; i++) {
            segments[i] = _styleStyledText(segments[i], level);
          }
          n.segments = segments;
        }
        break;

      case final BoxNode n:
        n.style = _mergeStyles(theme.getStyle(level, n.tags), n.style);
        if (n.title != null) {
          n.title = _styleStyledText(n.title!, level);
        }
        for (final child in n.children) {
          _applyStyle(child, level, factory);
        }
        break;

      case final IndentationNode n:
        n.style = _mergeStyles(theme.getStyle(level, n.tags), n.style);
        for (final child in n.children) {
          _applyStyle(child, level, factory);
        }
        break;

      case final DecoratedNode n:
        n.style = _mergeStyles(theme.getStyle(level, n.tags), n.style);
        final leading = n.leading;
        if (leading != null) {
          try {
            for (int i = 0; i < leading.length; i++) {
              leading[i] = _styleStyledText(leading[i], level);
            }
          } catch (_) {
            final styledLeading = factory.checkoutDataList<StyledText>()
              ..addAll(leading);
            for (int i = 0; i < styledLeading.length; i++) {
              styledLeading[i] = _styleStyledText(styledLeading[i], level);
            }
            n.leading = styledLeading;
          }
        }
        final trailing = n.trailing;
        if (trailing != null) {
          try {
            for (int i = 0; i < trailing.length; i++) {
              trailing[i] = _styleStyledText(trailing[i], level);
            }
          } catch (_) {
            final styledTrailing = factory.checkoutDataList<StyledText>()
              ..addAll(trailing);
            for (int i = 0; i < styledTrailing.length; i++) {
              styledTrailing[i] = _styleStyledText(styledTrailing[i], level);
            }
            n.trailing = styledTrailing;
          }
        }
        for (final child in n.children) {
          _applyStyle(child, level, factory);
        }
        break;

      case final SectionNode n:
        _applyStyle(n.summary, level, factory);
        for (final child in n.children) {
          _applyStyle(child, level, factory);
        }
        break;

      case final LayoutNode n:
        // Generic container handling (GroupNode, ParagraphNode, RowNode, etc.)
        for (final child in n.children) {
          _applyStyle(child, level, factory);
        }
        break;

      case final FillerNode n:
        n.style = _mergeStyles(theme.getStyle(level, n.tags), n.style);
        break;

      case final MapNode _:
      case final ListNode _:
        // Raw structured data carries no visual style within the doc tree.
        break;
    }
  }

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
