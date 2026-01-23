part of '../handler.dart';

/// Standard fields available from a [LogEntry] for formatters.
///
/// This enum provides a type-safe way to specify which fields should be
/// included in formatted log output. Used by [ToonFormatter], [JsonFormatter],
/// and other formatters that support customizable fields.
enum LogField {
  /// The log timestamp (ISO 8601 format).
  timestamp,

  /// The log level (TRACE, DEBUG, INFO, WARNING, ERROR).
  level,

  /// The logger name (hierarchical, dot-separated).
  logger,

  /// The call site origin (class.method or file:line).
  origin,

  /// The log message.
  message,

  /// The error object, if present.
  error,

  /// The stack trace, if present.
  stackTrace;

  /// Extracts the value of this field from a [LogEntry].
  ///
  /// Returns an empty string for optional fields (error, stackTrace) when
  /// they are not present in the entry.
  String getValue(final LogEntry entry) {
    switch (this) {
      case LogField.timestamp:
        return entry.timestamp;
      case LogField.level:
        return entry.level.name;
      case LogField.logger:
        return entry.loggerName;
      case LogField.origin:
        return entry.origin;
      case LogField.message:
        return entry.message;
      case LogField.error:
        return entry.error?.toString() ?? '';
      case LogField.stackTrace:
        return entry.stackTrace?.toString() ?? '';
    }
  }
}
