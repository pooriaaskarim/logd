part of '../handler.dart';

/// A [LogDecorator] that adds ANSI color escape sequences to log lines.
///
/// Colors are applied based on the [LogLevel] severity. This is useful for
/// enhancing readability in terminal environments that support ANSI colors.
///
/// Example with custom colors:
/// ```dart
/// ColorDecorator(
///   colorScheme: AnsiColorScheme(
///     trace: AnsiColor.cyan,
///     debug: AnsiColor.white,
///     info: AnsiColor.brightBlue,
///     warning: AnsiColor.yellow,
///     error: AnsiColor.brightRed,
///   ),
///   config: AnsiColorConfig.noBorders,
/// )
/// ```
@immutable
final class ColorDecorator extends VisualDecorator {
  /// Creates a [ColorDecorator].
  ///
  /// If [useColors] is `null`, it will attempt to auto-detect terminal support
  /// using `io.stdout.supportsAnsiEscapes`.
  ///
  /// Defaults to [ColorScheme.defaultScheme].
  ///
  /// [config] controls which parts of the log to color.
  /// Defaults to [ColorConfig.all] (color everything).
  const ColorDecorator({
    this.useColors,
    this.colorScheme = ColorScheme.defaultScheme,
    this.config = ColorConfig.all,
  });

  /// Explicit override for enabling or disabling ANSI colors.
  final bool? useColors;

  /// Color scheme mapping log levels to semantic colors.
  final ColorScheme colorScheme;

  /// Configuration for color application.
  final ColorConfig config;

  @override
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    // If the sink or context explicitly says no ANSI, we might skip decoration
    // to save processing, OR we can attach styles anyway and let the Sink ignore them.
    // Providing styles allows sinks that *do* support them to work, even if the primary one doesn't?
    // But `supportsAnsi` in context usually comes from the primary sink.
    // Let's stick to: if context says no ANSI, we can skip for optimization,
    // unless we want to support multi-sink with mixed capabilities?
    // "Deferred Rendering" implies we attach styles regardless, and Sink decides.
    // BUT `ColorDecorator` implies "ANSI" specifically?
    // Actually, it maps *semantics* to *colors*. It should probably be called `SemanticColorDecorator` but let's keep the name suitable.
    // However, if we want to support a FileSink (no color) and ConsoleSink (color) from the same pipeline,
    // we MUST attach styles here. The FileSink will ignore `TextStyle`.

    // Default to true here, Sink decides final rendering.
    // Actually, if `useColors` is explicitly `false`, we shouldn't decorate.
    if (useColors == false) {
      yield* lines;
      return;
    }

    final level = entry.level;
    final baseColor = colorScheme.colorForLevel(level);

    for (final line in lines) {
      final newSegments = <LogSegment>[];
      for (final segment in line.segments) {
        if (segment.style != null) {
          // Idempotency: if already styled, maybe skip? or merge?
          // For now, preserve existing style if it seems "complete"?
          // Or just overwrite/merge. Let's merge if possible or just append.
          newSegments.add(segment);
          continue;
        }

        TextStyle? style;
        final tags = segment.tags;

        if (tags.contains(LogTag.stackFrame)) {
          if (config.colorStackFrame) {
            style = const TextStyle(color: LogColor.brightBlack);
          }
        } else if (tags.contains(LogTag.border)) {
          if (config.colorBorder) {
            style = TextStyle(color: baseColor, dim: true);
          }
        } else if (tags.contains(LogTag.header)) {
          if (config.colorHeader) {
            // Differentiate inner header parts if possible
            if (tags.contains(LogTag.level)) {
              style = TextStyle(
                color: baseColor,
                bold: true,
                inverse: config.headerBackground,
              );
            } else if (tags.contains(LogTag.timestamp) ||
                tags.contains(LogTag.loggerName)) {
              style = TextStyle(
                color: baseColor,
                dim: true,
                inverse: config.headerBackground,
              );
            } else {
              // Generic header fallback
              style = TextStyle(
                color: baseColor,
                bold: true,
                inverse: config.headerBackground,
              );
            }
          }
        } else {
          // Body/Message
          if (config.colorBody) {
            style = TextStyle(color: baseColor);
          }
        }

        if (style != null) {
          newSegments
              .add(LogSegment(segment.text, tags: segment.tags, style: style));
        } else {
          newSegments.add(segment);
        }
      }
      yield LogLine(newSegments);
    }
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ColorDecorator &&
          runtimeType == other.runtimeType &&
          useColors == other.useColors &&
          colorScheme == other.colorScheme &&
          config == other.config;

  @override
  int get hashCode =>
      useColors.hashCode ^ colorScheme.hashCode ^ config.hashCode;
}
