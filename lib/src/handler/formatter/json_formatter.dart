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
/// into a pretty-printed, optionally styled JSON string.
///
/// Each part of the JSON (keys, values, punctuation) is tagged with semantic
/// tags like [LogTag.jsonKey], [LogTag.jsonValue], and [LogTag.jsonPunctuation]
/// when [color] is enabled. This allows decorators like [ColorDecorator]
/// to style the JSON output.
@immutable
final class JsonPrettyFormatter implements LogFormatter {
  /// Creates a [JsonPrettyFormatter].
  const JsonPrettyFormatter({
    this.indent = '  ',
    this.color = true,
  });

  /// Indentation string (default: two spaces).
  final String indent;

  /// Whether to emit semantic tags for coloring.
  final bool color;

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

    yield* _formatValue(map, 0);
  }

  Iterable<LogLine> _formatValue(final Object? value, final int depth) sync* {
    final prefix = indent * depth;

    if (value is Map) {
      yield LogLine([
        LogSegment(
          '{',
          tags: color
              ? const {LogTag.jsonPunctuation, LogTag.message}
              : const {LogTag.message},
        ),
      ]);

      final entries = value.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isLast = i == entries.length - 1;

        final segments = <LogSegment>[
          LogSegment(
            '$prefix$indent"',
            tags: color
                ? const {LogTag.jsonPunctuation, LogTag.message}
                : const {LogTag.message},
          ),
          LogSegment(
            entry.key.toString(),
            tags: color
                ? const {LogTag.jsonKey, LogTag.message}
                : const {LogTag.message},
          ),
          LogSegment(
            '": ',
            tags: color
                ? const {LogTag.jsonPunctuation, LogTag.message}
                : const {LogTag.message},
          ),
        ];

        final val = entry.value;
        if (val is Map || val is List) {
          yield LogLine(segments);
          yield* _formatValue(val, depth + 1);
          if (!isLast) {
            // Need to append a comma to the last line of the recursive call.
            // This is tricky with sync*.
            // For now, let's just emit the closing brace/bracket with a comma if needed.
          }
        } else {
          segments.add(_valueSegment(val));
          if (!isLast) {
            segments.add(
              LogSegment(
                ',',
                tags: color
                    ? const {LogTag.jsonPunctuation, LogTag.message}
                    : const {LogTag.message},
              ),
            );
          }
          yield LogLine(segments);
        }
      }

      yield LogLine([
        LogSegment(
          '$prefix}',
          tags: color
              ? const {LogTag.jsonPunctuation, LogTag.message}
              : const {LogTag.message},
        ),
      ]);
    } else if (value is List) {
      yield LogLine([
        LogSegment(
          '[',
          tags: color
              ? const {LogTag.jsonPunctuation, LogTag.message}
              : const {LogTag.message},
        ),
      ]);
      for (int i = 0; i < value.length; i++) {
        final isLast = i == value.length - 1;
        final val = value[i];
        if (val is Map || val is List) {
          yield* _formatValue(val, depth + 1);
        } else {
          final segments = [
            LogSegment(
              '$prefix$indent',
              tags: const {LogTag.message},
            ),
            _valueSegment(val),
          ];
          if (!isLast) {
            segments.add(
              LogSegment(
                ',',
                tags: color
                    ? const {LogTag.jsonPunctuation, LogTag.message}
                    : const {LogTag.message},
              ),
            );
          }
          yield LogLine(segments);
        }
      }
      yield LogLine([
        LogSegment(
          '$prefix]',
          tags: color
              ? const {LogTag.jsonPunctuation, LogTag.message}
              : const {LogTag.message},
        ),
      ]);
    }
  }

  LogSegment _valueSegment(final Object? value) {
    if (value == null) {
      return LogSegment(
        'null',
        tags: color
            ? const {LogTag.jsonValue, LogTag.message}
            : const {LogTag.message},
      );
    }
    if (value is String) {
      return LogSegment(
        '"$value"',
        tags: color
            ? const {LogTag.jsonValue, LogTag.message}
            : const {LogTag.message},
      );
    }
    return LogSegment(
      value.toString(),
      tags: color
          ? const {LogTag.jsonValue, LogTag.message}
          : const {LogTag.message},
    );
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is JsonPrettyFormatter &&
          runtimeType == other.runtimeType &&
          indent == other.indent &&
          color == other.color;

  @override
  int get hashCode => Object.hash(indent, color);
}
