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
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    final map = {
      'timestamp': entry.timestamp,
      'level': entry.level.name,
      'logger': entry.loggerName,
      'origin': entry.origin,
      'message': entry.message,
      if (entry.error != null) 'error': entry.error.toString(),
      if (entry.stackTrace != null) 'stackTrace': entry.stackTrace.toString(),
    };
    yield LogLine(
      [
        LogSegment(jsonEncode(map), tags: const {LogTag.message}),
      ],
    );
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
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
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
      yield LogLine(
        [
          LogSegment(line, tags: const {LogTag.message}),
        ],
      );
    }
  }
}

/// A [LogFormatter] that transforms a [LogEntry] into JSON with semantic tags.
///
/// Useful for JSON-based logging systems that want to preserve semantic
/// information for rendering or analysis. Each field includes its semantic
/// tags.
///
/// Example output:
/// ```json
/// {
///   "fields": {
///     "timestamp": {"value": "2024-01-01 10:00:00", "tags": ["timestamp"]},
///     "level": {"value": "INFO", "tags": ["level"]},
///     "logger": {"value": "app", "tags": ["loggerName"]},
///     "message": {"value": "Hello", "tags": ["message"]}
///   }
/// }
/// ```
@immutable
final class JsonSemanticFormatter implements LogFormatter {
  /// Creates a [JsonSemanticFormatter].
  const JsonSemanticFormatter({this.prettyPrint = false});

  /// Whether to pretty-print the JSON output.
  final bool prettyPrint;

  @override
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    final map = {
      'fields': {
        'timestamp': {
          'value': entry.timestamp,
          'tags': ['header', 'timestamp'],
        },
        'level': {
          'value': entry.level.name,
          'tags': ['header', 'level'],
        },
        'logger': {
          'value': entry.loggerName,
          'tags': ['header', 'loggerName'],
        },
        'origin': {
          'value': entry.origin,
          'tags': ['origin'],
        },
        'message': {
          'value': entry.message,
          'tags': ['message'],
        },
        if (entry.error != null)
          'error': {
            'value': entry.error.toString(),
            'tags': ['error'],
          },
        if (entry.stackTrace != null)
          'stackTrace': {
            'value': entry.stackTrace.toString(),
            'tags': ['stackFrame'],
          },
      },
      'metadata': {
        'hierarchyDepth': entry.hierarchyDepth,
      },
    };

    final encoder =
        prettyPrint ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    final json = encoder.convert(map);

    for (final line in json.split('\n')) {
      yield LogLine([
        LogSegment(line, tags: const {LogTag.message}),
      ]);
    }
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is JsonSemanticFormatter &&
          runtimeType == other.runtimeType &&
          prettyPrint == other.prettyPrint;

  @override
  int get hashCode => prettyPrint.hashCode;
}
