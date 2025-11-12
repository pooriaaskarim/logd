part of 'logger.dart';

/// Efficient buffer for building multi-line log messages before syncing.
class LogBuffer extends StringBuffer {
  LogBuffer._(this._logger, this.logLevel);

  /// Internal: The logger to sync to.
  final Logger _logger;

  /// The level for this buffer's log.
  final LogLevel logLevel;

  @override
  void writeAll(final Iterable objects, [final String separator = '']) {
    for (final object in objects) {
      writeln(object);
    }
  }

  /// Sends the buffer to all printers and clears it.
  void sync() {
    if (isNotEmpty) {
      _logger
          ._log(logLevel, toString(), null, StackTrace.current)
          .catchError((final e) => print('Logging error: $e'));
      clear();
    }
  }
}
