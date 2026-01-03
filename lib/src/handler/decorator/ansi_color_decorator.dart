part of '../handler.dart';

/// A [LogDecorator] that adds ANSI color escape sequences to log lines.
///
/// Colors are applied based on the [LogLevel] severity. This is useful for
/// enhancing readability in terminal environments that support ANSI colors.
final class AnsiColorDecorator implements LogDecorator {
  /// Creates an [AnsiColorDecorator].
  ///
  /// If [useColors] is `null`, it will attempt to auto-detect terminal support
  /// using `io.stdout.supportsAnsiEscapes`.
  const AnsiColorDecorator({
    this.useColors,
  });

  /// Explicit override for enabling or disabling ANSI colors.
  final bool? useColors;

  static const _ansiReset = '\x1B[0m';
  static final _levelColors = {
    LogLevel.trace: '\x1B[90m', // Grey
    LogLevel.debug: '\x1B[37m', // White
    LogLevel.info: '\x1B[32m', // Green
    LogLevel.warning: '\x1B[33m', // Yellow
    LogLevel.error: '\x1B[31m', // Red
  };

  @override
  Iterable<String> decorate(
    final Iterable<String> lines,
    final LogLevel level,
  ) sync* {
    final enabled = useColors ?? io.stdout.supportsAnsiEscapes;
    if (!enabled) {
      yield* lines;
      return;
    }

    final color = _levelColors[level] ?? '';
    for (final line in lines) {
      for (final splitLine in line.split('\n')) {
        yield '$color$splitLine$_ansiReset';
      }
    }
  }
}
