part of '../handler.dart';

/// Formatter that outputs log entries as compact JSON.
class JsonFormatter implements LogFormatter {
  const JsonFormatter();

  @override
  List<String> format(final LogEntry entry) {
    final map = {
      'time': entry.timestamp,
      'logger': entry.loggerName,
      'level': entry.level.name.toUpperCase(),
      'origin': entry.origin,
      'message': entry.message,
      if (entry.error != null) 'error': entry.error.toString(),
      if (entry.stackTrace != null) 'stack': entry.stackTrace.toString(),
    };
    return [jsonEncode(map)];
  }
}

/// Formatter that outputs log entries as pretty-printed JSON (multi-line).
class JsonPrettyFormatter implements LogFormatter {
  const JsonPrettyFormatter();

  @override
  List<String> format(final LogEntry entry) {
    final map = {
      'time': entry.timestamp,
      'logger': entry.loggerName,
      'level': entry.level.name.toUpperCase(),
      'origin': entry.origin,
      'message': entry.message,
      if (entry.error != null) 'error': entry.error.toString(),
      if (entry.stackTrace != null) 'stack': entry.stackTrace.toString(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(map).split('\n');
  }
}
