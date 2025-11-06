part of 'logger.dart';

/// Efficient buffer for building multi-line logs.
class LogBuffer extends StringBuffer {
  LogBuffer._(this.logger, this.level);
  final Logger logger;
  final LogLevel level;

  @override
  void writeAll(final Iterable objects, [final String separator = '']) {
    for (final object in objects) {
      writeln(object);
    }
  }

  /// Sends the buffer to all printers and clears it.
  void sync() {
    if (isNotEmpty) {
      logger._log(level, toString(), null, StackTrace.current);
      clear();
    }
  }
}
