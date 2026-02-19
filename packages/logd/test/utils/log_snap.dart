import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';

/// A utility to capture snapshots of log output for verification.
class LogSnap {
  /// Captures the output of a [LogDocument] rendered at a specific [width].
  ///
  /// Uses [AnsiEncoder] by default to capture styles and layout.
  static String capture(
    final LogDocument document,
    final LogLevel level, {
    final int width = 80,
    final bool useAnsi = true,
  }) {
    final LogEncoder<String> encoder =
        useAnsi ? const AnsiEncoder() : const PlainTextEncoder();

    return encoder.encode(document, level, width: width);
  }

  /// Captures the output of a full [Handler] pipeline for a given [entry].
  ///
  /// This simulates the exact visual result a user would see.
  static Future<String> captureHandler(
    final Handler handler,
    final LogEntry entry, {
    final int width = 80,
    final bool useAnsi = true,
  }) async {
    final sink = _CaptureSink(width: width);

    // We create a temporary handler with our capture sink
    final captureHandler = Handler(
      formatter: handler.formatter,
      sink: sink,
      filters: handler.filters,
      decorators: handler.decorators,
      lineLength: width,
    );

    await captureHandler.log(entry);

    if (sink.lastDocument == null) {
      return '';
    }

    final LogEncoder<String> encoder =
        useAnsi ? const AnsiEncoder() : const PlainTextEncoder();

    return encoder.encode(sink.lastDocument!, entry.level, width: width);
  }
}

base class _CaptureSink extends LogSink<LogDocument> {
  _CaptureSink({required this.width});

  final int width;
  LogDocument? lastDocument;

  @override
  int get preferredWidth => width;

  @override
  Future<void> output(
    final LogDocument document,
    final LogLevel level, {
    final LogContext? context,
  }) async {
    lastDocument = document;
  }
}
