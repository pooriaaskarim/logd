part of 'logger.dart';

/// Structured representation of a log event passed to handlers.
///
/// Single source of truth for all log data. Handlers receive
/// this object and decide how to format and where to output.
@internal
class LogEntry {
  const LogEntry({
    required this.loggerName,
    required this.origin,
    required this.level,
    required this.message,
    required this.timestamp,
    this.stackFrames,
    this.error,
    this.stackTrace,
  });

  /// Name of the logger that created this entry.
  final String loggerName;

  /// Caller origin string (e.g., 'Class.method').
  final String origin;

  /// Log severity level.
  final LogLevel level;

  /// Log message content.
  final String message;

  /// Formatted timestamp.
  final String timestamp;

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
  final List<CallbackInfo>? stackFrames;

  /// Associated error object.
  final Object? error;

  /// Full stack trace.
  final StackTrace? stackTrace;

  @override
  String toString() => '[$level] (depth $hierarchyDepth) $origin: $message';
}
