part of '../handler.dart';

/// A [LogFormatter] that transforms a [LogEntry] into
/// a single-line JSON string.
///
/// The output is compact and suitable for machine parsing or structured logging
/// backends. For a human-friendly pretty-printed version, see
/// [JsonPrettyFormatter].
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
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    final node = factory.checkoutMap();
    final map = node.map;

    map['level'] = entry.level.name;
    map['message'] = entry.message;

    for (final meta in metadata) {
      final value = meta.getValue(entry);
      if (value.isNotEmpty) {
        map[meta.name] = value;
      }
    }

    if (entry.error != null) {
      final error = entry.error;
      if (error is Map || error is List) {
        map['error'] = error;
      } else {
        map['error'] = error.toString();
      }
    }
    if (entry.stackTrace != null) {
      map['stackTrace'] = entry.stackTrace.toString();
    }

    document.writeNode(node);
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
///
/// This "Wise" formatter uses adaptive layout logic to preserve readability on
/// narrow terminals by stacking keys or compacting small composites.
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
    this.keyWrapThreshold = 40,
    this.stackThreshold = 20,
    this.sortKeys = false,
    this.maxDepth = 10,
  });

  /// Indentation string (default: two spaces).
  final String indent;

  /// Whether to emit semantic tags for coloring.
  final bool color;

  /// Whether to detect and pretty-print nested JSON strings.
  final bool prettyPrintNestedJson;

  /// The threshold for breaking long keys onto their own lines (Structural
  /// Hint).
  ///
  /// This applies to scalar values. For composite values, [stackThreshold] is
  /// used.
  final int keyWrapThreshold;

  /// The threshold for stacking keys above composite values (Maps/Lists).
  ///
  /// If the key length exceeds this, it moves above the '{' or '['.
  final int stackThreshold;

  /// Whether to sort Map keys alphabetically.
  final bool sortKeys;

  /// Maximum depth to recurse into JSON structures (default: 10).
  final int maxDepth;

  /// The contextual metadata to include in the output.
  @override
  final Set<LogMetadata> metadata;

  @override
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    final map = factory.checkoutDataMap<String, Object?>();
    map['level'] = entry.level.name;
    map['message'] = entry.message;

    final fieldTags = factory.checkoutDataMap<String, int>();
    fieldTags['level'] = LogTag.level;
    fieldTags['message'] = LogTag.message;

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

    final nodes = factory.checkoutDataList<LogNode>();
    _buildNodes(factory, map, 0, nodes, fieldTags: fieldTags);
    for (final node in nodes) {
      document.writeNode(node);
    }

    factory
      ..release(nodes)
      ..release(map)
      ..release(fieldTags);
  }

  void _buildNodes(
    final LogPipelineFactory factory,
    final Object? value,
    final int depth,
    final List<LogNode> destination, {
    final Map<String, int>? fieldTags,
    final List<StyledText>? prefixSegments,
    final Object? currentKey,
    final bool isLast = true,
  }) {
    if (depth > maxDepth) {
      final msg = factory.checkoutMessage()
        ..segments.add(const StyledText('...'));
      destination.add(factory.checkoutParagraph()..children.add(msg));
      return;
    }

    // 1. Adaptive Indent: If space is tight, use a minimal 1-space indent.
    // NOTE: Simplified to always use provided indent for semantic consistency.
    final effectiveIndent = indent;

    if (value is Map) {
      final header = factory.checkoutHeader();
      if (prefixSegments != null) {
        header.segments.addAll(prefixSegments);
      }
      header.segments.add(
        StyledText(
          '{',
          tags: color ? LogTag.punctuation : LogTag.none,
        ),
      );

      // Add breadcrumb summary for the collapsed state
      _addPreviewSegments(factory, header.segments, value, isLast: isLast);

      final entries = factory.checkoutDataList<MapEntry<dynamic, dynamic>>()
        ..addAll(value.entries);

      if (sortKeys) {
        entries.sort(
          (final a, final b) => a.key.toString().compareTo(b.key.toString()),
        );
      }

      final body = factory.checkoutDataList<LogNode>();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final isEntryLast = i == entries.length - 1;
        final entryVal = entry.value;

        // Try to parse nested JSON strings if space allows
        final processedValue = (entryVal is String)
            ? (_tryParseJson(entryVal) ?? entryVal)
            : entryVal;

        final isComposite = processedValue is Map || processedValue is List;
        final keyText = '"${entry.key}": ';
        final int keyTag =
            color ? (LogTag.key | LogTag.punctuation) : LogTag.none;

        // WISDOM: Check if we can compact this composite into a single line
        // Only compact if the key itself isn't too long to force stacking.
        if (_isSmallComposite(processedValue) &&
            keyText.visibleLength <= stackThreshold) {
          final scalarStr = _valueString(processedValue);
          final msg = factory.checkoutMessage()
            ..segments.add(StyledText(keyText, tags: keyTag))
            ..segments.add(
              StyledText(
                scalarStr,
                tags: color ? LogTag.value : LogTag.none,
              ),
            );
          if (!isEntryLast) {
            msg.segments.add(
              StyledText(
                ',',
                tags: color ? LogTag.punctuation : LogTag.none,
              ),
            );
          }
          body.add(factory.checkoutParagraph()..children.add(msg));
          continue;
        }

        // VIRTUAL MODE: Put key on its own line if it's too long (Structural
        // Hint)
        final threshold = isComposite ? stackThreshold : keyWrapThreshold;

        if (keyText.visibleLength > threshold) {
          final structuralGroup = factory.checkoutGroup();

          structuralGroup.children.add(
            factory.checkoutParagraph()
              ..children.add(
                factory.checkoutHeader()
                  ..segments.add(StyledText(keyText, tags: keyTag)),
              ),
          );

          _buildNodes(
            factory,
            processedValue,
            depth + 1,
            structuralGroup.children,
            fieldTags: fieldTags,
            prefixSegments: null,
            currentKey: entry.key,
            isLast: isEntryLast,
          );

          body.add(structuralGroup);
        } else {
          // Unify the key into the nested SectionNode's summary if collapsible
          final prefix = factory.checkoutDataList<StyledText>()
            ..add(StyledText(keyText, tags: keyTag));

          _buildNodes(
            factory,
            processedValue,
            depth + 1,
            body,
            fieldTags: fieldTags,
            prefixSegments: prefix,
            currentKey: entry.key,
            isLast: isEntryLast,
          );
          factory.release(prefix);
        }
      }

      final closing = factory.checkoutHeader()
        ..segments.add(
          StyledText(
            isLast ? '}' : '},',
            tags: color ? LogTag.punctuation : LogTag.none,
          ),
        );

      destination.add(
        factory.checkoutSection()
          ..summary = header
          ..children.add(
            factory.checkoutIndentation()
              ..indentString = effectiveIndent
              ..children.addAll(body),
          )
          ..children.add(closing)
          ..tags = LogTag.collapsible,
      );

      factory
        ..release(entries)
        ..release(body);
    } else if (value is List) {
      final header = factory.checkoutHeader();
      if (prefixSegments != null) {
        header.segments.addAll(prefixSegments);
      }
      header.segments.add(
        StyledText(
          '[',
          tags: color ? LogTag.punctuation : LogTag.none,
        ),
      );

      // Add breadcrumb summary for the collapsed state
      _addPreviewSegments(factory, header.segments, value, isLast: isLast);

      final body = factory.checkoutDataList<LogNode>();
      for (int i = 0; i < value.length; i++) {
        final isEntryLast = i == value.length - 1;
        final entryVal = value[i];
        final processedValue = (entryVal is String)
            ? (_tryParseJson(entryVal) ?? entryVal)
            : entryVal;

        final group = factory.checkoutGroup();
        _buildNodes(
          factory,
          processedValue,
          depth + 1,
          group.children,
          fieldTags: fieldTags,
          prefixSegments: null,
          isLast: isEntryLast,
        );
        body.add(group);
      }

      final closing = factory.checkoutHeader()
        ..segments.add(
          StyledText(
            isLast ? ']' : '],',
            tags: color ? LogTag.punctuation : LogTag.none,
          ),
        );

      destination.add(
        factory.checkoutSection()
          ..summary = header
          ..children.add(
            factory.checkoutIndentation()
              ..indentString = effectiveIndent
              ..children.addAll(body),
          )
          ..children.add(closing)
          ..tags = LogTag.collapsible,
      );

      factory.release(body);
    } else {
      // Scalar value
      final valStr = _valueString(value);
      final valueTag = (fieldTags != null && currentKey != null)
          ? (fieldTags[currentKey] ?? (color ? LogTag.value : LogTag.none))
          : (color ? LogTag.value : LogTag.none);

      // WISDOM: For long scalars, use DecoratedNode to provide a hanging indent
      // so the wrapped text stays aligned after the key.
      if (valStr.length > 40 && prefixSegments != null) {
        final keyWidth = prefixSegments.fold<int>(
          0,
          (final sum, final s) => sum + s.text.length,
        );

        final msg = factory.checkoutMessage()
          ..segments.add(
            StyledText(
              valStr,
              tags: valueTag,
            ),
          );
        if (!isLast) {
          msg.segments.add(
            StyledText(
              ',',
              tags: color ? LogTag.punctuation : LogTag.none,
            ),
          );
        }

        destination.add(
          factory.checkoutDecorated()
            ..leading = prefixSegments
            ..leadingWidth = keyWidth
            ..repeatLeading = false
            ..children.add(factory.checkoutParagraph()..children.add(msg)),
        );
        return;
      }

      if (valStr.contains('\n')) {
        // WISDOM: Handle multiline strings as a block
        final msg = factory.checkoutMessage();
        if (prefixSegments != null) {
          msg.segments.addAll(prefixSegments);
        }
        msg.segments.add(
          StyledText(
            valStr,
            tags: valueTag,
          ),
        );
        if (!isLast) {
          msg.segments.add(
            StyledText(
              ',',
              tags: color ? LogTag.punctuation : LogTag.none,
            ),
          );
        }
        destination.add(factory.checkoutParagraph()..children.add(msg));
        return;
      }

      final msg = factory.checkoutMessage();
      if (prefixSegments != null) {
        msg.segments.addAll(prefixSegments);
      }
      msg.segments.add(
        StyledText(
          valStr,
          tags: valueTag,
        ),
      );
      if (!isLast) {
        msg.segments.add(
          StyledText(
            ',',
            tags: color ? LogTag.punctuation : LogTag.none,
          ),
        );
      }
      destination.add(factory.checkoutParagraph()..children.add(msg));
    }
  }

  void _addPreviewSegments(
    final LogPipelineFactory factory,
    final List<StyledText> segments,
    final Object? value, {
    required final bool isLast,
    final int maxItems = 10,
  }) {
    const previewTag = LogTag.noWrap | LogTag.preview;
    const dimStyle = LogStyle(dim: true);

    if (value is Map) {
      if (value.isEmpty) {
        segments.add(
          StyledText(
            isLast ? ' }' : ' },',
            tags: (color ? LogTag.punctuation : LogTag.none) | previewTag,
            style: dimStyle,
          ),
        );
        return;
      }
      final entries = value.entries.toList();
      if (sortKeys) {
        entries.sort(
          (final a, final b) => a.key.toString().compareTo(b.key.toString()),
        );
      }
      for (int i = 0; i < entries.length && i < maxItems; i++) {
        final entry = entries[i];
        final k = '"${entry.key}": ';
        final v = _valueString(entry.value);

        segments
          ..add(
            StyledText(
              i == 0 ? ' $k' : ', $k',
              tags: (color ? LogTag.key | LogTag.punctuation : LogTag.none) |
                  previewTag,
              style: dimStyle,
            ),
          )
          ..add(
            StyledText(
              v,
              tags: (color ? LogTag.value : LogTag.none) | previewTag,
              style: dimStyle,
            ),
          );
      }
      if (entries.length > maxItems) {
        segments.add(
          StyledText(
            isLast ? ', ... }' : ', ... },',
            tags: (color ? LogTag.punctuation : LogTag.none) | previewTag,
            style: dimStyle,
          ),
        );
      } else {
        segments.add(
          StyledText(
            isLast ? ' }' : ' },',
            tags: (color ? LogTag.punctuation : LogTag.none) | previewTag,
            style: dimStyle,
          ),
        );
      }
    } else if (value is List) {
      if (value.isEmpty) {
        segments.add(
          StyledText(
            isLast ? ' ]' : ' ],',
            tags: (color ? LogTag.punctuation : LogTag.none) | previewTag,
            style: dimStyle,
          ),
        );
        return;
      }

      for (int i = 0; i < value.length && i < maxItems; i++) {
        final v = _valueString(value[i]);
        segments.add(
          StyledText(
            i == 0 ? ' $v' : ', $v',
            tags: (color ? LogTag.value : LogTag.none) | previewTag,
            style: dimStyle,
          ),
        );
      }

      if (value.length > maxItems) {
        segments.add(
          StyledText(
            isLast ? ', ... ]' : ', ... ],',
            tags: (color ? LogTag.punctuation : LogTag.none) | previewTag,
            style: dimStyle,
          ),
        );
      } else {
        segments.add(
          StyledText(
            isLast ? ' ]' : ' ],',
            tags: (color ? LogTag.punctuation : LogTag.none) | previewTag,
            style: dimStyle,
          ),
        );
      }
    }
  }

  /// WISDOM: Determines if a composite value should be rendered on a single
  /// line.
  bool _isSmallComposite(final Object? value) {
    // WISDOM: For maximum interactivity and recursive collapsibility,
    // we flatten small structures ONLY if they contain primitive values.
    // This preserves structural depth for complex objects.
    if (value is Map) {
      if (value.isEmpty) {
        return true;
      }
      if (value.length > 5) {
        return false;
      }
      int totalLen = 0;
      for (final entry in value.entries) {
        if (entry.value is Map || entry.value is List) {
          return false;
        }
        totalLen += entry.key.toString().length + 4;
        totalLen += _valueString(entry.value).length + 2;
        if (totalLen > 60) {
          return false;
        }
      }
      return true;
    } else if (value is List) {
      if (value.isEmpty) {
        return true;
      }
      if (value.length > 5) {
        return false;
      }
      int totalLen = 0;
      for (final item in value) {
        if (item is Map || item is List) {
          return false;
        }
        totalLen += _valueString(item).length + 2;
        if (totalLen > 60) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  String _valueString(final Object? value) {
    if (value == null) {
      return 'null';
    } else if (value is String) {
      return '"$value"';
    } else if (value is Map || value is List) {
      if (sortKeys && value is Map) {
        final sortedMap = Map.fromEntries(
          value.entries.toList()
            ..sort(
              (final a, final b) =>
                  a.key.toString().compareTo(b.key.toString()),
            ),
        );
        return convert.jsonEncode(sortedMap);
      }
      return convert.jsonEncode(value);
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
      return convert.jsonDecode(trimmed);
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
          keyWrapThreshold == other.keyWrapThreshold &&
          stackThreshold == other.stackThreshold &&
          sortKeys == other.sortKeys &&
          maxDepth == other.maxDepth &&
          setEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
        indent,
        color,
        keyWrapThreshold,
        stackThreshold,
        sortKeys,
        maxDepth,
        Object.hashAll(metadata),
      );
}
