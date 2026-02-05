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
  LogDocument format(
    final LogEntry entry,
    final LogContext context,
  ) {
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

    return LogDocument(
      nodes: [
        MessageNode(
          segments: [
            StyledText(json, tags: const {LogTag.message}),
          ],
        ),
      ],
      metadata: map, // Also attach raw map for sinks that might prefer it
    );
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
  LogDocument format(
    final LogEntry entry,
    final LogContext context,
  ) {
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

    return LogDocument(
      nodes: _formatValue(map, tags: fieldTags),
      metadata: map,
    );
  }

  List<LogNode> _formatValue(
    final Object? value, {
    final Map<String, LogTag>? tags,
    final bool isLastValue = true,
  }) {
    final nodes = <LogNode>[];

    if (value is Map) {
      final entries = value.entries.toList();

      // Opening brace
      nodes.add(
        MessageNode(
          segments: [
            StyledText(
              '{',
              tags: color ? const {LogTag.punctuation} : const {},
            ),
          ],
        ),
      );

      final bodyNodes = <LogNode>[];
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isLast = i == entries.length - 1;
        final key = entry.key;
        final val = entry.value;
        final valueTag = tags?[key] ?? LogTag.value;

        final keySegments = [
          StyledText(
            '"$key": ',
            tags: color ? const {LogTag.key, LogTag.punctuation} : const {},
          ),
        ];

        final processedValue =
            (val is String) ? (_tryParseJson(val) ?? val) : val;

        if (processedValue is Map || processedValue is List) {
          // Recursive call for nested structure
          final nestedNodes = _formatValue(
            processedValue,
            tags: tags,
            isLastValue: isLast,
          );

          // Merge the key into the first line of the nested block (brace/bracket)
          if (nestedNodes.isNotEmpty && nestedNodes.first is MessageNode) {
            final firstNode = nestedNodes.first as MessageNode;
            bodyNodes.add(
              MessageNode(
                segments: [...keySegments, ...firstNode.segments],
              ),
            );
            bodyNodes.addAll(nestedNodes.skip(1));
          } else {
            bodyNodes.add(MessageNode(segments: keySegments));
            bodyNodes.addAll(nestedNodes);
          }
        } else {
          // Leaf value
          final valueStr = _valueString(processedValue);
          bodyNodes.add(
            MessageNode(
              segments: [
                ...keySegments,
                StyledText(valueStr, tags: {valueTag}),
                if (!isLast)
                  StyledText(
                    ',',
                    tags: color ? const {LogTag.punctuation} : const {},
                  ),
              ],
            ),
          );
        }
      }

      nodes.add(IndentationNode(indentString: indent, children: bodyNodes));

      // Closing brace
      nodes.add(
        MessageNode(
          segments: [
            StyledText(
              '}',
              tags: color ? const {LogTag.punctuation} : const {},
            ),
            if (!isLastValue)
              StyledText(
                ',',
                tags: color ? const {LogTag.punctuation} : const {},
              ),
          ],
        ),
      );
    } else if (value is List) {
      // Opening bracket
      nodes.add(
        MessageNode(
          segments: [
            StyledText(
              '[',
              tags: color ? const {LogTag.punctuation} : const {},
            ),
          ],
        ),
      );

      final bodyNodes = <LogNode>[];
      for (int i = 0; i < value.length; i++) {
        final isLast = i == value.length - 1;
        final val = value[i];
        final processedValue =
            (val is String) ? (_tryParseJson(val) ?? val) : val;

        if (processedValue is Map || processedValue is List) {
          bodyNodes.addAll(
            _formatValue(
              processedValue,
              tags: tags,
              isLastValue: isLast,
            ),
          );
        } else {
          final valueStr = _valueString(processedValue);
          bodyNodes.add(
            MessageNode(
              segments: [
                StyledText(valueStr, tags: color ? {LogTag.value} : const {}),
                if (!isLast)
                  StyledText(
                    ',',
                    tags: color ? const {LogTag.punctuation} : const {},
                  ),
              ],
            ),
          );
        }
      }

      nodes.add(IndentationNode(indentString: indent, children: bodyNodes));

      // Closing bracket
      nodes.add(
        MessageNode(
          segments: [
            StyledText(
              ']',
              tags: color ? const {LogTag.punctuation} : const {},
            ),
            if (!isLastValue)
              StyledText(
                ',',
                tags: color ? const {LogTag.punctuation} : const {},
              ),
          ],
        ),
      );
    }

    return nodes;
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
