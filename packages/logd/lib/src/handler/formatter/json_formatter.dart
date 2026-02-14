part of '../handler.dart';

/// A [LogFormatter] that transforms a [LogEntry] into
/// a single-line JSON string.
///
/// The output is compact and suitable for machine parsing or structured logging
/// backends.
@immutable
final class JsonFormatter implements LogFormatter {
  /// Creates a [JsonFormatter].
  ///
  /// - [metadata]: List of [LogMetadata] to include in the output.
  ///   Crucial fields (level, message, etc.) are always included.
  const JsonFormatter({
    this.metadata = const {
      LogMetadata.timestamp,
      LogMetadata.logger,
      LogMetadata.origin,
    },
  });

  /// The contextual metadata to include in the JSON output.
  @override
  final Set<LogMetadata> metadata;

  @override
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    final map = <String, dynamic>{
      'level': entry.level.name,
      'message': entry.message,
    };

    for (final meta in metadata) {
      final value = meta.getValue(entry);
      if (value.isNotEmpty) {
        map[meta.name] = value;
      }
    }

    if (entry.error != null) {
      map['error'] = entry.error.toString();
    }
    if (entry.stackTrace != null) {
      map['stackTrace'] = entry.stackTrace.toString();
    }

    final json = jsonEncode(map);
    yield LogLine.text(json);
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is JsonFormatter &&
          runtimeType == other.runtimeType &&
          setEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(metadata));
}

/// A [LogFormatter] that transforms a [LogEntry]
/// into a pretty-printed, optionally styled JSON string.
///
/// Each part of the JSON (keys, values, punctuation) is tagged with semantic
/// tags like [LogTag.key], [LogTag.value], [LogTag.punctuation], etc.
/// when [color] is enabled.
@immutable
final class JsonPrettyFormatter implements LogFormatter {
  /// Creates a [JsonPrettyFormatter].
  ///
  /// - [indent]: Indentation string (default: two spaces).
  /// - [color]: Whether to emit semantic tags for coloring.
  /// - [metadata]: List of [LogMetadata] to include in the output.
  ///   Crucial fields (level, message, etc.) are always included.
  const JsonPrettyFormatter({
    this.indent = '  ',
    this.color = false,
    this.prettyPrintNestedJson = true,
    this.metadata = const {
      LogMetadata.timestamp,
      LogMetadata.logger,
      LogMetadata.origin,
    },
  });

  /// Indentation string (default: two spaces).
  final String indent;

  /// Whether to emit semantic tags for coloring.
  final bool color;

  /// Whether to detect and pretty-print nested JSON strings.
  final bool prettyPrintNestedJson;

  /// The contextual metadata to include in the output.
  @override
  final Set<LogMetadata> metadata;

  @override
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    final width = context.availableWidth;
    final map = <String, Object?>{
      'level': entry.level.name,
      'message': entry.message,
    };
    final fieldTags = <String, LogTag>{
      'level': LogTag.level,
      'message': LogTag.message,
    };

    for (final meta in metadata) {
      final value = meta.getValue(entry);
      if (value.isNotEmpty) {
        final key = meta.name;
        map[key] = value;
        fieldTags[key] = meta.tag;
      }
    }

    if (entry.error != null) {
      final error = entry.error;
      if (error is Map || error is List) {
        map['error'] = error;
      } else {
        map['error'] = error.toString();
      }
      fieldTags['error'] = LogTag.error;
    }
    if (entry.stackTrace != null) {
      map['stackTrace'] = entry.stackTrace.toString();
      fieldTags['stackTrace'] = LogTag.stackFrame;
    }

    yield* _formatValue(map, 0, width, tags: fieldTags);
  }

  Iterable<LogLine> _formatValue(
    final Object? value,
    final int depth,
    final int width, {
    final Map<String, LogTag>? tags,
    final List<LogSegment>? keySegments,
    final bool isLastValue = true,
  }) sync* {
    final prefix = indent * depth;

    if (value is Map) {
      final entries = value.entries.toList();
      // First line of Map (opening brace)
      yield LogLine([
        if (keySegments != null) ...keySegments,
        LogSegment(
          '{',
          tags: color ? const {LogTag.punctuation} : const {},
        ),
      ]);

      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isLast = i == entries.length - 1;

        final segments = <LogSegment>[
          // Combine key parts into single segment to prevent wrapping from
          // splitting them and trimming the trailing space
          LogSegment(
            '$prefix$indent"${entry.key}": ',
            tags: color ? const {LogTag.key, LogTag.punctuation} : const {},
          ),
        ];

        final val = entry.value;
        final Object? processedValue;
        if (val is String) {
          processedValue = _tryParseJson(val) ?? val;
        } else {
          processedValue = val;
        }

        if (processedValue is Map || processedValue is List) {
          yield* _formatValue(
            processedValue,
            depth + 1,
            width,
            tags: tags,
            keySegments: segments,
            isLastValue: isLast,
          );
        } else {
          final currentPrefixWidth = segments.fold(
            0,
            (final s, final seg) => s + seg.text.visibleLength,
          );

          final valueStr = _valueString(val);
          final valueTag = tags?[entry.key] ?? LogTag.value;

          // Wrap the value with an indent that matches the key part
          final valueLine = LogLine([
            LogSegment(valueStr, tags: {valueTag}),
          ]);
          final valueLines =
              valueLine.wrap(width, indent: ' ' * currentPrefixWidth).toList();

          if (valueLines.isEmpty) {
            yield LogLine([
              ...segments,
              LogSegment('', tags: {valueTag}),
              if (!isLast)
                LogSegment(
                  ',',
                  tags: color ? const {LogTag.punctuation} : const {},
                ),
            ]);
          } else {
            // First line has the key prepended
            yield LogLine([
              ...segments,
              ...valueLines[0].segments,
              if (valueLines.length == 1 && !isLast)
                LogSegment(
                  ',',
                  tags: color ? const {LogTag.punctuation} : const {},
                ),
            ]);

            // Subsequent lines already have the correct indent from wrap()
            for (int j = 1; j < valueLines.length; j++) {
              final isValueLast = j == valueLines.length - 1;
              yield LogLine([
                ...valueLines[j].segments,
                if (isValueLast && !isLast)
                  LogSegment(
                    ',',
                    tags: color ? const {LogTag.punctuation} : const {},
                  ),
              ]);
            }
          }
        }
      }

      // Closing brace
      yield LogLine([
        LogSegment(
          '$prefix}',
          tags: color ? const {LogTag.punctuation} : const {},
        ),
        if (!isLastValue)
          LogSegment(
            ',',
            tags: color ? const {LogTag.punctuation} : const {},
          ),
      ]);
    } else if (value is List) {
      // First line of List (opening bracket)
      yield LogLine([
        if (keySegments != null) ...keySegments,
        LogSegment(
          '[',
          tags: color ? const {LogTag.punctuation} : const {},
        ),
      ]);
      for (int i = 0; i < value.length; i++) {
        final isLast = i == value.length - 1;
        final val = value[i];
        final Object? processedValue;
        if (val is String) {
          processedValue = _tryParseJson(val) ?? val;
        } else {
          processedValue = val;
        }

        if (processedValue is Map || processedValue is List) {
          yield* _formatValue(
            processedValue,
            depth + 1,
            width,
            tags: tags,
            isLastValue: isLast,
          );
        } else {
          final prefixStr = '$prefix$indent';
          final segments = [
            LogSegment(
              prefixStr,
              tags: const {},
            ),
          ];
          final currentPrefixWidth = prefixStr.visibleLength;

          final valueStr = _valueString(val);
          final valueTag = color ? {LogTag.value} : <LogTag>{};

          // Wrap the value with an indent that matches the prefix
          final valueLine = LogLine([LogSegment(valueStr, tags: valueTag)]);
          final valueLines =
              valueLine.wrap(width, indent: ' ' * currentPrefixWidth).toList();

          if (valueLines.isNotEmpty) {
            yield LogLine([
              ...segments,
              ...valueLines[0].segments,
              if (valueLines.length == 1 && !isLast)
                LogSegment(
                  ',',
                  tags: color ? const {LogTag.punctuation} : const {},
                ),
            ]);

            if (valueLines.length > 1) {
              for (int j = 1; j < valueLines.length; j++) {
                final isValueLast = j == valueLines.length - 1;
                yield LogLine([
                  ...valueLines[j].segments,
                  if (isValueLast && !isLast)
                    LogSegment(
                      ',',
                      tags: color ? const {LogTag.punctuation} : const {},
                    ),
                ]);
              }
            }
          }
        }
      }
      // Closing bracket
      yield LogLine([
        LogSegment(
          '$prefix]',
          tags: color ? const {LogTag.punctuation} : const {},
        ),
        if (!isLastValue)
          LogSegment(
            ',',
            tags: color ? const {LogTag.punctuation} : const {},
          ),
      ]);
    }
  }

  String _valueString(final Object? value) {
    if (value == null) {
      return 'null';
    } else if (value is String) {
      return '"$value"';
    } else {
      return value.toString();
    }
  }

  /// Try to parse a string as JSON. Returns null if not valid JSON.
  Object? _tryParseJson(final String value) {
    if (!prettyPrintNestedJson) {
      return null;
    }
    final trimmed = value.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      return null;
    }
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is JsonPrettyFormatter &&
          runtimeType == other.runtimeType &&
          indent == other.indent &&
          color == other.color &&
          setEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
        indent,
        color,
        Object.hashAll(metadata),
      );
}
