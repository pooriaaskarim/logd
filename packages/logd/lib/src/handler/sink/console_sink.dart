part of '../handler.dart';

/// A [LogSink] that outputs formatted log lines to the system console.
@immutable
base class ConsoleSink extends LogSink<LogDocument> {
  const ConsoleSink({this.lineLength, super.enabled});

  /// The maximum line length for the output.
  final int? lineLength;

  /// The width this sink prefers for its output.
  int get resolvedWidth =>
      lineLength ?? (io.stdout.hasTerminal ? io.stdout.terminalColumns : 80);

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

      final width = resolvedWidth;
      final output = encoder.encode(document, level, width: width);
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
