part of '../handler.dart';

/// Outputs to console using debugPrint (Flutter-safe).
class ConsoleSink implements LogSink {
  const ConsoleSink({
    this.enabled = true,
  });

  @override
  final bool enabled;

  @override
  Future<void> output(final List<String> lines, final LogLevel level) async {
    try {
      for (final line in lines) {
        //ignore: avoid_print
        print(line);
      }
      //ignore: avoid_print
      print('');
    } catch (e, s) {
      InternalLogger.log(
        LogLevel.error,
        'ConsoleSink output failed',
        error: e,
        stackTrace: s,
      );
    }
  }
}
