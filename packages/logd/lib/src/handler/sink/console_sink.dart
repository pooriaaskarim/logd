part of '../handler.dart';

/// A [LogSink] that outputs formatted log lines to the system console.
@immutable
base class ConsoleSink extends LogSink<LogDocument> {
  const ConsoleSink({super.enabled});

  @override
  int get preferredWidth =>
      io.stdout.hasTerminal ? io.stdout.terminalColumns : 80;

  @override
  Future<void> output(
    final LogDocument document,
    final LogLevel level, {
    final LogContext? context,
  }) async {
    if (!enabled) {
      return;
    }
    try {
      final supportsAnsi = io.stdout.supportsAnsiEscapes;
      final LogEncoder<String> encoder =
          supportsAnsi ? const AnsiEncoder() : const PlainTextEncoder();

      final totalWidth = context?.totalWidth ?? preferredWidth;
      final output = encoder.encode(document, level, width: totalWidth);
      io.stdout.writeln(output);
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
