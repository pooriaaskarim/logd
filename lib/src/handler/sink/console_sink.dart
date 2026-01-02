part of '../handler.dart';

/// A [LogSink] that outputs formatted log lines to the system console.
@immutable
base class ConsoleSink extends LogSink {
  const ConsoleSink({super.enabled});

  @override
  Future<void> output(
    final Iterable<String> lines,
    final LogLevel level,
  ) async {
    if (!enabled) {
      return;
    }
    try {
      for (final line in lines) {
        print(line);
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
