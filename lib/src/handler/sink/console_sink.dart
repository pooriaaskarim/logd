part of '../handler.dart';

/// Outputs to console using debugPrint (Flutter-safe).
class ConsoleSink implements LogSink {
  const ConsoleSink({
    this.enabled = true,
  });

  @override
  final bool enabled;

  @override
  void output(final List<String> lines, final LogLevel level) {
    for (final line in lines) {
      debugPrint(line);
    }
    debugPrint('');
  }
}
