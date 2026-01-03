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
  Iterable<LogLine> format(final LogEntry entry) sync* {
    final map = {
      'timestamp': entry.timestamp,
      'level': entry.level.name,
      'logger': entry.loggerName,
      'origin': entry.origin,
      'message': entry.message,
      if (entry.error != null) 'error': entry.error.toString(),
      if (entry.stackTrace != null) 'stackTrace': entry.stackTrace.toString(),
    };
    yield LogLine(jsonEncode(map), tags: const {LogLineTag.message});
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
  Iterable<LogLine> format(final LogEntry entry) sync* {
    final map = {
      'timestamp': entry.timestamp,
      'level': entry.level.name,
      'logger': entry.loggerName,
      'origin': entry.origin,
      'message': entry.message,
      if (entry.error != null) 'error': entry.error.toString(),
      if (entry.stackTrace != null) 'stackTrace': entry.stackTrace.toString(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(map);
    for (final line in json.split('\n')) {
      yield LogLine(line, tags: const {LogLineTag.message});
    }
  }
}
