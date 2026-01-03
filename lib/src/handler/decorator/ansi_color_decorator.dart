part of '../handler.dart';

/// A [LogDecorator] that adds ANSI color escape sequences to log lines.
///
/// Colors are applied based on the [LogLevel] severity. This is useful for
/// enhancing readability in terminal environments that support ANSI colors.
@immutable
final class AnsiColorDecorator extends VisualDecorator {
  /// Creates an [AnsiColorDecorator].
  ///
  /// If [useColors] is `null`, it will attempt to auto-detect terminal support
  /// using `io.stdout.supportsAnsiEscapes`.
  const AnsiColorDecorator({
    this.useColors,
    this.colorHeaderBackground = false,
  });

  /// Explicit override for enabling or disabling ANSI colors.
  final bool? useColors;

  /// Whether to use a background color for the header line.
  final bool colorHeaderBackground;

  static const _ansiReset = '\x1B[0m';
  static final _levelColors = {
    LogLevel.trace: '\x1B[90m', // Grey
    LogLevel.debug: '\x1B[37m', // White
    LogLevel.info: '\x1B[32m', // Green
    LogLevel.warning: '\x1B[33m', // Yellow
    LogLevel.error: '\x1B[31m', // Red
  };

  @override
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
  ) sync* {
    final enabled = useColors ?? io.stdout.supportsAnsiEscapes;
    if (!enabled) {
      yield* lines;
      return;
    }

    final level = entry.level;
    final baseColor = _levelColors[level] ?? '';

    for (final line in lines) {
      // Idempotency: Skip if already colored
      if (line.tags.contains(LogLineTag.ansiColored)) {
        yield line;
        continue;
      }

      String coloredText;
      if (line.tags.contains(LogLineTag.header)) {
        if (colorHeaderBackground) {
          // Headers with background: Bold + Level Color + Inverse/Background
          coloredText = '\x1B[1m\x1B[7m$baseColor${line.text}$_ansiReset';
        } else {
          // Headers: Bold + Level color
          coloredText = '\x1B[1m$baseColor${line.text}$_ansiReset';
        }
      } else if (line.tags.contains(LogLineTag.border)) {
        // Borders: Pure level color
        coloredText = '$baseColor${line.text}$_ansiReset';
      } else if (line.tags.contains(LogLineTag.stackFrame)) {
        // Stack frames: Dimmed (grey)
        coloredText = '\x1B[90m${line.text}$_ansiReset';
      } else {
        // Message/Content: Pure level color
        coloredText = '$baseColor${line.text}$_ansiReset';
      }

      yield LogLine(coloredText, tags: {...line.tags, LogLineTag.ansiColored});
    }
  }
}
