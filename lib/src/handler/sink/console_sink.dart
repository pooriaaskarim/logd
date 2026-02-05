part of '../handler.dart';

/// A [LogSink] that outputs formatted log lines to the system console.
@immutable
base class ConsoleSink extends LogSink {
  /// Creates a [ConsoleSink].
  ///
  /// - [theme]: Optional theme to resolve semantic tags into ANSI colors.
  const ConsoleSink({this.theme, super.enabled});

  /// The theme used for ANSI output (if supported).
  final LogTheme? theme;

  @override
  int get preferredWidth =>
      io.stdout.hasTerminal ? io.stdout.terminalColumns : 80;

  @override
  Future<void> output(
    final LogDocument document,
    final LogLevel level,
  ) async {
    if (!enabled) {
      return;
    }
    try {
      final supportsAnsi = io.stdout.supportsAnsiEscapes;
      final LogEncoder<String> encoder =
          supportsAnsi ? AnsiEncoder(theme: theme) : const PlainTextEncoder();

      final output = encoder.encode(document, level);
      print(output);
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
