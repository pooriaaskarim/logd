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

  /// Sinks the buffer and clears it.
  void sink() {
    if (isNotEmpty) {
      _logger._log(logLevel, toString(), null, StackTrace.current).catchError(
            (final e) => InternalLogger.log(
              LogLevel.error,
              'Error while logging from buffer.',
              error: e,
              stackTrace: StackTrace.current,
            ),
          );
      clear();
    }
  }
}
