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
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    final level = entry.level;

    for (final line in lines) {
      final newSegments = <LogSegment>[];
      for (final segment in line.segments) {
        // Resolve style from theme
        final themeStyle = theme.getStyle(level, segment.tags);

        // Merge with existing style
        final combinedStyle = _mergeStyles(themeStyle, segment.style);

        newSegments.add(segment.copyWith(style: combinedStyle));
      }
      yield LogLine(newSegments);
    }
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

extension _LogSegmentCopy on LogSegment {
  LogSegment copyWith({
    final String? text,
    final Set<LogTag>? tags,
    final LogStyle? style,
  }) =>
      LogSegment(
        text ?? this.text,
        tags: tags ?? this.tags,
        style: style ?? this.style,
      );
}
