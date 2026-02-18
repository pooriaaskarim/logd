part of '../../handler.dart';

/// Contextual metadata available from a [LogEntry] for formatters.
///
/// Unlike crucial log content (level, message, error, stackTrace), metadata
/// provides surrounding context that can be selectively omitted.
enum LogMetadata {
  /// The log timestamp (ISO 8601 format).
  timestamp,

  /// The logger name (hierarchical, dot-separated).
  logger,

  /// The call site origin (class.method or file:line).
  origin;

  /// Extracts the value of this metadata field from a [LogEntry].
  String getValue(final LogEntry entry) {
    switch (this) {
      case LogMetadata.timestamp:
        return entry.timestamp;
      case LogMetadata.logger:
        return entry.loggerName;
      case LogMetadata.origin:
        return entry.origin;
    }
  }

  /// Returns the semantic tag associated with this metadata.
  LogTag get tag {
    switch (this) {
      case LogMetadata.timestamp:
        return LogTag.timestamp;
      case LogMetadata.logger:
        return LogTag.loggerName;
      case LogMetadata.origin:
        return LogTag.origin;
    }
  }
}
