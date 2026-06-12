part of 'logger.dart';

/// Structured representation of a log event passed to handlers.
///
/// Single source of truth for all log data. Handlers receive
/// this object and decide how to format and where to output.
class LogEntry {
  LogEntry({
    required this.loggerName,
    required this.origin,
    required this.level,
    required this.message,
    required this.timestamp,
    this.stackFrames,
    this.error,
    this.stackTrace,
  });

  @internal
  LogEntry.pooled()
      : loggerName = '',
        origin = '',
        level = LogLevel.debug,
        message = '',
        timestamp = '';

  /// Name of the logger that created this entry.
  String loggerName;

  /// Caller origin string (e.g., 'Class.method').
  String origin;

  /// Log severity level.
  LogLevel level;

  /// Log message content.
  String message;

  /// Formatted timestamp.
  String timestamp;

  /// Hierarchy depth calculated from [loggerName].
  ///
  /// 'global' -> 0
  /// 'a' -> 1
  /// 'a.b' -> 2
  int get hierarchyDepth {
    if (loggerName == 'global') {
      return 0;
    }
    return loggerName.split('.').length;
  }

  /// Parsed stack frames if included.
  List<CallbackInfo>? stackFrames;

  /// Associated error object.
  Object? error;

  /// Full stack trace.
  StackTrace? stackTrace;

  /// Resets the entry for reuse in the pool.
  void reset() {
    loggerName = '';
    origin = '';
    level = LogLevel.debug;
    message = '';
    timestamp = '';
    stackFrames = null;
    error = null;
    stackTrace = null;
  }

  /// Creates a copy of this entry with optional overrides.
  LogEntry copyWith({
    final String? loggerName,
    final String? origin,
    final LogLevel? level,
    final String? message,
    final String? timestamp,
    final List<CallbackInfo>? stackFrames,
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      LogEntry(
        loggerName: loggerName ?? this.loggerName,
        origin: origin ?? this.origin,
        level: level ?? this.level,
        message: message ?? this.message,
        timestamp: timestamp ?? this.timestamp,
        stackFrames: stackFrames ?? this.stackFrames,
        error: error ?? this.error,
        stackTrace: stackTrace ?? this.stackTrace,
      );

  @override
  String toString() => '[$level] (depth $hierarchyDepth) $origin: $message';
}
