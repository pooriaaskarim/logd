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
        ParagraphNode(
          children: [
            MessageNode(
              segments: [
                StyledText(json, tags: const {}),
              ],
            ),
          ],
        ),
      ],
      metadata: const {'width': 10000},
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
      nodes: _buildNodes(
        map,
        0,
        context: context,
        fieldTags: fieldTags,
        remainingWidth: context.availableWidth,
      ),
      metadata: {'width': context.totalWidth},
    );
  }

  List<LogNode> _buildNodes(
    final Object? value,
    final int depth, {
    required final LogContext context,
    required final int remainingWidth, // Exact width available at this depth
    final Map<String, LogTag>? fieldTags,
    final String? currentKey,
    final bool isLast = true,
  }) {
    // 1. Adaptive Nesting: If very narrow, stop auto-parsing nested JSON.
    final canParseNested = remainingWidth > 15 && prettyPrintNestedJson;

    // 2. Adaptive Indent: If space is tight, use a minimal 1-space indent.
    final effectiveIndent =
        (remainingWidth < 20 && indent.length > 1) ? ' ' : indent;

    // Hierarchy overhead: IndentationNode usually adds '│ ' (2 chars)
    final childRemainingWidth = remainingWidth - effectiveIndent.length - 2;

    if (value is Map) {
      final nodes = <LogNode>[
        ParagraphNode(
          children: [
            HeaderNode(
              segments: [
                StyledText(
                  '{',
                  tags: color ? const {LogTag.punctuation} : const {},
                ),
              ],
            ),
          ],
        ),
      ];

      final entries = value.entries.toList();
      final body = <LogNode>[];
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isEntryLast = i == entries.length - 1;
        final entryVal = entry.value;

        // Try to parse nested JSON strings if space allows
        final processedValue = (entryVal is String && canParseNested)
            ? (_tryParseJson(entryVal) ?? entryVal)
            : entryVal;

        final keyText = '"${entry.key}": ';
        final Set<LogTag> keyTag =
            color ? const {LogTag.key, LogTag.punctuation} : const {};

        // VIRTUAL MODE: If space is extremely limited (e.g. nested deeply),
        // put key on its own line to save horizontal width.
        if (remainingWidth < 25) {
          body
            ..add(
              ParagraphNode(
                children: [
                  HeaderNode(
                    segments: [StyledText(keyText, tags: keyTag)],
                  ),
                ],
              ),
            )
            ..addAll(
              _buildNodes(
                processedValue,
                depth + 1,
                context: context,
                remainingWidth: childRemainingWidth,
                fieldTags: fieldTags,
                isLast: isEntryLast,
              ),
            );
        } else {
          body.add(
            DecoratedNode(
              leadingWidth: keyText.visibleLength,
              leading: [StyledText(keyText, tags: keyTag)],
              repeatLeading: false,
              children: _buildNodes(
                processedValue,
                depth + 1,
                context: context,
                remainingWidth: childRemainingWidth - keyText.visibleLength,
                fieldTags: fieldTags,
                currentKey: entry.key,
                isLast: isEntryLast,
              ),
            ),
          );
        }
      }

      nodes
        ..add(
          IndentationNode(
            indentString: effectiveIndent,
            children: body,
          ),
        )
        ..add(
          ParagraphNode(
            children: [
              HeaderNode(
                segments: [
                  StyledText(
                    isLast ? '}' : '},',
                    tags: color ? const {LogTag.punctuation} : const {},
                  ),
                ],
              ),
            ],
          ),
        );
      return nodes;
    } else if (value is List) {
      final nodes = <LogNode>[
        ParagraphNode(
          children: [
            HeaderNode(
              segments: [
                StyledText(
                  '[',
                  tags: color ? const {LogTag.punctuation} : const {},
                ),
              ],
            ),
          ],
        ),
      ];

      final body = <LogNode>[];
      for (int i = 0; i < value.length; i++) {
        final isEntryLast = i == value.length - 1;
        final entryVal = value[i];
        final processedValue = (entryVal is String)
            ? (_tryParseJson(entryVal) ?? entryVal)
            : entryVal;

        body.add(
          GroupNode(
            children: _buildNodes(
              processedValue,
              depth + 1,
              context: context,
              remainingWidth: childRemainingWidth,
              fieldTags: fieldTags,
              isLast: isEntryLast,
            ),
          ),
        );
      }

      nodes
        ..add(
          IndentationNode(
            indentString: effectiveIndent,
            children: body,
          ),
        )
        ..add(
          ParagraphNode(
            children: [
              HeaderNode(
                segments: [
                  StyledText(
                    isLast ? ']' : '],',
                    tags: color ? const {LogTag.punctuation} : const {},
                  ),
                ],
              ),
            ],
          ),
        );
      return nodes;
    } else {
      // Scalar value
      final valStr = _valueString(value);
      final valueTag = (fieldTags != null && currentKey != null)
          ? (fieldTags[currentKey] ?? (color ? LogTag.value : null))
          : (color ? LogTag.value : null);

      return [
        ParagraphNode(
          children: [
            MessageNode(
              segments: [
                StyledText(
                  valStr,
                  tags: valueTag != null ? {valueTag} : const {},
                ),
                if (!isLast)
                  StyledText(
                    ',',
                    tags: color ? const {LogTag.punctuation} : const {},
                  ),
              ],
            ),
          ],
        ),
      ];
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
