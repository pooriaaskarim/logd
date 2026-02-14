part of 'logger.dart';

/// Internal: The actual buffer implementation holding state.
/// This acts as the "Body" which survives the "Handle" (LogBuffer).
class _LogBuffer extends StringBuffer {
  _LogBuffer(this._logger, this.logLevel);

  /// Internal: The logger to sync to.
  final Logger _logger;

  /// The level for this buffer's log.
  final LogLevel logLevel;

  /// Optional error associated with this log.
  Object? error;

  /// Optional stack trace associated with this log.
  StackTrace? stackTrace;

  @override
  void writeAll(final Iterable objects, [final String separator = '']) {
    for (final object in objects) {
      writeln(object);
    }
  }

  @override
  void clear() {
    error = null;
    stackTrace = null;
    super.clear();
  }

  /// Sinks the buffer and clears it.
  void sink() {
    if (isNotEmpty || error != null || stackTrace != null) {
      _logger._log(logLevel, toString(), error, stackTrace).catchError(
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

/// Efficient buffer for building multi-line log messages before syncing.
///
/// This class acts as a finite "Handle" to an internal buffer.
/// It uses composition to ensure the internal buffer can be tracked by a
/// finalizer without creating circular references that prevent garbage
/// collection.
class LogBuffer implements StringSink {
  LogBuffer._(final Logger logger, final LogLevel level)
      : _buffer = _LogBuffer(logger, level) {
    _finalizer.attach(this, _buffer, detach: this);
  }

  /// Internal: The inner buffer token/body.
  final _LogBuffer _buffer;

  /// Finalizer for auto-sinking abandoned buffers.
  static final Finalizer<_LogBuffer> _finalizer =
      Finalizer<_LogBuffer>((final buffer) {
    if (buffer.isNotEmpty ||
        buffer.error != null ||
        buffer.stackTrace != null) {
      // Log leak warning
      if (buffer._logger.autoSinkBuffer) {
        // Auto-sink the content
        buffer._logger
            ._log(
              buffer.logLevel,
              buffer.toString(),
              buffer.error,
              buffer.stackTrace,
            )
            .catchError(
              (final e) => InternalLogger.log(
                LogLevel.error,
                'Error while auto-sinking buffer.',
                error: e,
                stackTrace: StackTrace.current,
              ),
            );

        InternalLogger.log(
          LogLevel.warning,
          'LogBuffer leak detected! '
          'Content was automatically logged to prevent data loss. '
          'Logger: "${buffer._logger.name}", Level: ${buffer.logLevel.name}. '
          'Call .sink() explicitly to ensure immediate logging and avoid this'
          ' warning.',
          stackTrace: StackTrace.current,
        );
      } else {
        InternalLogger.log(
          LogLevel.warning,
          'LogBuffer leak detected! '
          'Auto-sink is disabled, so data was LOST. '
          'Logger: "${buffer._logger.name}", Level: ${buffer.logLevel.name}. '
          'Call .sink() explicitly to avoid this warning and ensure data is '
          'logged.',
          stackTrace: StackTrace.current,
        );
      }
    }
  });

  /// Sets the error object for this log message.
  set error(final Object? value) => _buffer.error = value;

  /// Gets the current error object.
  Object? get error => _buffer.error;

  /// Sets the stack trace for this log message.
  set stackTrace(final StackTrace? value) => _buffer.stackTrace = value;

  /// Gets the current stack trace.
  StackTrace? get stackTrace => _buffer.stackTrace;

  int get length => _buffer.length;

  bool get isEmpty => _buffer.isEmpty;

  bool get isNotEmpty => _buffer.isNotEmpty;

  @override
  void write(final Object? object) => _buffer.write(object);

  @override
  void writeln([final Object? object = '']) => _buffer.writeln(object);

  @override
  void writeAll(final Iterable objects, [final String separator = '']) =>
      _buffer.writeAll(objects, separator);

  @override
  void writeCharCode(final int charCode) => _buffer.writeCharCode(charCode);

  void clear() => _buffer.clear();

  @override
  String toString() => _buffer.toString();

  /// Sinks the buffer and clears it.
  void sink() {
    if (isNotEmpty || error != null || stackTrace != null) {
      _buffer.sink();
    }
  }
}
