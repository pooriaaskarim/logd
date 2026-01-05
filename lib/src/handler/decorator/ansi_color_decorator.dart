part of '../handler.dart';

/// A [LogDecorator] that adds ANSI color escape sequences to log lines.
///
/// Colors are applied based on the [LogLevel] severity. This is useful for
/// enhancing readability in terminal environments that support ANSI colors.
///
/// Example with custom colors:
/// ```dart
/// AnsiColorDecorator(
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
final class AnsiColorDecorator extends VisualDecorator {
  /// Creates an [AnsiColorDecorator].
  ///
  /// If [useColors] is `null`, it will attempt to auto-detect terminal support
  /// using `io.stdout.supportsAnsiEscapes`.
  ///
  /// [colorScheme] defines which color to use for each log level.
  /// Defaults to [AnsiColorScheme.defaultScheme].
  ///
  /// [config] controls which parts of the log to color.
  /// Defaults to [AnsiColorConfig.all] (color everything).
  const AnsiColorDecorator({
    this.useColors,
    this.colorScheme = AnsiColorScheme.defaultScheme,
    this.config = AnsiColorConfig.all,
  });

  /// Explicit override for enabling or disabling ANSI colors.
  final bool? useColors;

  /// Color scheme mapping log levels to ANSI colors.
  final AnsiColorScheme colorScheme;

  /// Configuration for color application.
  final AnsiColorConfig config;

  static const _ansiReset = '\x1B[0m';

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
    final baseColor = colorScheme.colorForLevel(level);

    for (final line in lines) {
      // Idempotency: Skip if already colored
      if (line.tags.contains(LogLineTag.ansiColored)) {
        yield line;
        continue;
      }

      String coloredText;
      if (line.tags.contains(LogLineTag.header)) {
        if (config.colorHeader) {
          if (config.headerBackground) {
            // Headers with background: Bold + Level Color + Inverse/Background
            coloredText = '${AnsiStyle.bold.sequence}\x1B[7m'
                '${baseColor.foreground}${line.text}$_ansiReset';
          } else {
            // Headers: Bold + Level color
            coloredText = '${AnsiStyle.bold.sequence}'
                '${baseColor.foreground}${line.text}$_ansiReset';
          }
        } else {
          coloredText = line.text;
        }
      } else if (line.tags.contains(LogLineTag.border)) {
        if (config.colorBorder) {
          coloredText = '${baseColor.foreground}${line.text}$_ansiReset';
        } else {
          coloredText = line.text;
        }
      } else if (line.tags.contains(LogLineTag.stackFrame)) {
        if (config.colorStackFrame) {
          // Stack frames: Dimmed (grey)
          coloredText = '${AnsiColor.brightBlack.foreground}'
              '${line.text}$_ansiReset';
        } else {
          coloredText = line.text;
        }
      } else {
        if (config.colorBody) {
          // Message/Content: Pure level color
          coloredText = '${baseColor.foreground}${line.text}$_ansiReset';
        } else {
          coloredText = line.text;
        }
      }

      yield LogLine(coloredText, tags: {...line.tags, LogLineTag.ansiColored});
    }
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is AnsiColorDecorator &&
          runtimeType == other.runtimeType &&
          useColors == other.useColors &&
          colorScheme == other.colorScheme &&
          config == other.config;

  @override
  int get hashCode =>
      useColors.hashCode ^ colorScheme.hashCode ^ config.hashCode;
}
