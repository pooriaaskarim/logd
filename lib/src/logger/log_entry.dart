part of 'logger.dart';

/// Structured representation of a log event passed to printers.
///
/// This is the **single source of truth** for all log data. Printers receive
/// this object and decide how to format and where to send it.
class LogEntry {
  const LogEntry({
    required this.logger,
    required this.origin,
    required this.level,
    required this.message,
    required this.timestamp,
    this.stackFrames,
    this.error,
    this.stackTrace,
  });

  /// The logger name
  final String logger;

  /// Caller origin
  ///
  /// Resolves to ClassName.MethodName form.
  final String origin;

  /// The severity level of the log.
  final LogLevel level;

  /// The log message. May contain newlines.
  final String message;

  /// Formatted timestamp (from [Timestamp]).
  final String timestamp;

  /// Parsed stack frames (only for warning/error if configured).
  final List<CallbackInfo>? stackFrames;

  /// Optional error object (e.g., Exception).
  final Object? error;

  /// Full stack trace (if provided).
  final StackTrace? stackTrace;

  @override
  String toString() => '[$level] $origin: $message';
}
