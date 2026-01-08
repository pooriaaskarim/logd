part of '../handler.dart';

/// A [LogSink] that outputs formatted log lines to the system console.
@immutable
base class ConsoleSink extends LogSink {
  const ConsoleSink({super.enabled});

  @override
  int get preferredWidth =>
      io.stdout.hasTerminal ? io.stdout.terminalColumns : 80;

  @override
  Future<void> output(
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    if (!enabled) {
      return;
    }
    try {
      final supportsAnsi = io.stdout.supportsAnsiEscapes;

      for (final line in lines) {
        final buffer = StringBuffer();
        for (final segment in line.segments) {
          final style = segment.style;
          if (supportsAnsi && style != null) {
            // Apply ANSI codes
            if (style.bold == true) {
              buffer.write(AnsiStyle.bold.sequence);
            }
            if (style.dim == true) {
              buffer.write(AnsiStyle.dim.sequence);
            }
            if (style.italic == true) {
              buffer.write(AnsiStyle.italic.sequence);
            }
            if (style.inverse == true) {
              buffer.write('\x1B[7m'); // Hardcoded inverse for now
            }
            if (style.color != null) {
              final ansiCode = AnsiColorCode.fromLogColor(style.color!);
              buffer.write(ansiCode.foreground);
            }

            buffer
              ..write(segment.text)

              // Reset
              ..write(AnsiStyle.reset.sequence);
          } else {
            buffer.write(segment.text);
          }
        }
        print(buffer);
      }
    } catch (e, s) {
      InternalLogger.log(
        LogLevel.error,
        'ConsoleSink output failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ConsoleSink &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(runtimeType, enabled);
}
