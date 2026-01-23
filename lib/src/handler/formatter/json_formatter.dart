part of '../handler.dart';

/// A [LogFormatter] that transforms a [LogEntry] into
/// a single-line JSON string.
///
/// The output is compact and suitable for machine parsing or structured logging
/// backends.
final class JsonFormatter implements LogFormatter {
  /// Creates a [JsonFormatter].
  ///
  /// - [fields]: Optional list of [LogField]s to include in the output.
  ///   If null (default), all available fields are included.
  const JsonFormatter({this.fields});

  /// Optional list of fields to include. If null, includes all fields.
  final List<LogField>? fields;

  @override
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    // Build map from selected fields (or all if fields is null)
    final selectedFields = fields ??
        [
          LogField.timestamp,
          LogField.level,
          LogField.logger,
          LogField.origin,
          LogField.message,
          LogField.error,
          LogField.stackTrace,
        ];

    final map = <String, dynamic>{};
    for (final field in selectedFields) {
      final value = field.getValue(entry);
      // Only include non-empty values
      if (value.isNotEmpty) {
        map[field.name] = value;
      }
    }
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
/// tags like [LogTag.header], [LogTag.timestamp], [LogTag.level], etc.
/// when [color] is enabled. This allows decorators like [StyleDecorator]
/// to style the JSON output.
@immutable
final class JsonPrettyFormatter implements LogFormatter {
  /// Creates a [JsonPrettyFormatter].
  ///
  /// - [indent]: Indentation string (default: two spaces).
  /// - [color]: Whether to emit semantic tags for coloring.
  /// - [fields]: Optional list of [LogField]s to include in the output.
  ///   If null (default), all available fields are included.
  const JsonPrettyFormatter({
    this.indent = '  ',
    this.color = true,
    this.fields,
  });

  /// Indentation string (default: two spaces).
  final String indent;

  /// Whether to emit semantic tags for coloring.
  final bool color;

  /// Optional list of fields to include. If null, includes all fields.
  final List<LogField>? fields;

  @override
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    // Build map from selected fields (or all if fields is null)
    final selectedFields = fields ??
        [
          LogField.timestamp,
          LogField.level,
          LogField.logger,
          LogField.origin,
          LogField.message,
          LogField.error,
          LogField.stackTrace,
        ];

    final map = <String, dynamic>{};
    final fieldTags = <String, LogTag>{};
    for (final field in selectedFields) {
      final value = field.getValue(entry);
      // Only include non-empty values
      if (value.isNotEmpty) {
        final key = field.name;
        map[key] = value;
        fieldTags[key] = _tagForField(field);
      }
    }

    yield* _formatValue(map, 0, tags: fieldTags);
  }

  LogTag _tagForField(final LogField field) {
    switch (field) {
      case LogField.timestamp:
        return LogTag.timestamp;
      case LogField.level:
        return LogTag.level;
      case LogField.logger:
        return LogTag.loggerName;
      case LogField.origin:
        return LogTag.origin;
      case LogField.message:
        return LogTag.message;
      case LogField.error:
        return LogTag.error;
      case LogField.stackTrace:
        return LogTag.stackFrame;
    }
  }

  Iterable<LogLine> _formatValue(
    final Object? value,
    final int depth, {
    final Map<String, LogTag>? tags,
  }) sync* {
    final prefix = indent * depth;

    if (value is Map) {
      yield LogLine([
        LogSegment(
          '{',
          tags: color ? const {LogTag.border} : const {},
        ),
      ]);

      final entries = value.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isLast = i == entries.length - 1;

        final segments = <LogSegment>[
          LogSegment(
            '$prefix$indent"',
            tags: color ? const {LogTag.border} : const {},
          ),
          LogSegment(
            entry.key.toString(),
            tags: color ? const {LogTag.header} : const {},
          ),
          LogSegment(
            '": ',
            tags: color ? const {LogTag.border} : const {},
          ),
        ];

        final val = entry.value;
        if (val is Map || val is List) {
          yield LogLine(segments);
          yield* _formatValue(val, depth + 1);
        } else {
          segments.add(_valueSegment(val, tags?[entry.key]));
          if (!isLast) {
            segments.add(
              LogSegment(
                ',',
                tags: color ? const {LogTag.border} : const {},
              ),
            );
          }
          yield LogLine(segments);
        }
      }

      yield LogLine([
        LogSegment(
          '$prefix}',
          tags: color ? const {LogTag.border} : const {},
        ),
      ]);
    } else if (value is List) {
      yield LogLine([
        LogSegment(
          '[',
          tags: color ? const {LogTag.border} : const {},
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
              tags: const {},
            ),
            _valueSegment(val),
          ];
          if (!isLast) {
            segments.add(
              LogSegment(
                ',',
                tags: color ? const {LogTag.border} : const {},
              ),
            );
          }
          yield LogLine(segments);
        }
      }
      yield LogLine([
        LogSegment(
          '$prefix]',
          tags: color ? const {LogTag.border} : const {},
        ),
      ]);
    }
  }

  LogSegment _valueSegment(final Object? value, [final LogTag? tag]) {
    final tags = <LogTag>{};
    if (color && tag != null) {
      tags.add(tag);
    }

    if (value == null) {
      return LogSegment(
        'null',
        tags: tags,
      );
    }
    if (value is String) {
      return LogSegment(
        '"$value"',
        tags: tags,
      );
    }
    return LogSegment(
      value.toString(),
      tags: tags,
    );
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is JsonPrettyFormatter &&
          runtimeType == other.runtimeType &&
          indent == other.indent &&
          color == other.color &&
          listEquals(fields, other.fields);

  @override
  int get hashCode => Object.hash(indent, color, Object.hashAll(fields ?? []));
}
