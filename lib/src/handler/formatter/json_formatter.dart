part of '../handler.dart';

/// A [LogFormatter] that transforms a [LogEntry] into
/// a single-line JSON string.
///
/// The output is compact and suitable for machine parsing or structured logging
/// backends.
final class JsonFormatter implements LogFormatter {
  /// Creates a [JsonFormatter].
  const JsonFormatter();

  @override
  Iterable<String> format(final LogEntry entry) sync* {
    final map = {
      'timestamp': entry.timestamp,
      'level': entry.level.name,
      'logger': entry.loggerName,
      'origin': entry.origin,
      'message': entry.message,
      if (entry.error != null) 'error': entry.error.toString(),
      if (entry.stackTrace != null) 'stackTrace': entry.stackTrace.toString(),
    };
    yield jsonEncode(map);
  }
}

/// A [LogFormatter] that transforms a [LogEntry]
/// into a pretty-printed JSON string.
///
/// The output includes indentation and newlines, making it more readable for
/// humans.
final class JsonPrettyFormatter implements LogFormatter {
  /// Creates a [JsonPrettyFormatter].
  const JsonPrettyFormatter();

  @override
  Iterable<String> format(final LogEntry entry) sync* {
    final map = {
      'timestamp': entry.timestamp,
      'level': entry.level.name,
      'logger': entry.loggerName,
      'origin': entry.origin,
      'message': entry.message,
      if (entry.error != null) 'error': entry.error.toString(),
      if (entry.stackTrace != null) 'stackTrace': entry.stackTrace.toString(),
    };
    yield const JsonEncoder.withIndent('  ').convert(map);
  }
}
