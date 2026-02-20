part of '../handler.dart';

/// A [LogFormatter] that facilitates Token-Oriented Object Notation (TOON).
///
/// TOON is a compact, token-efficient format designed for feeding logs into
/// machine parsers or Large Language Models (LLMs). It uses a header definition
/// followed by uniform rows of values separated by a delimiter (default: Tab).
///
/// This version is optimized for token efficiency and raw data transport.
/// For a more human-friendly, structured version, use [ToonPrettyFormatter].
@immutable
final class ToonFormatter implements LogFormatter {
  /// Creates a [ToonFormatter].
  ///
  /// - [delimiter]: The separator between values. Defaults to tab (`\t`).
  /// - [arrayName]: The name of the array in the header (e.g., 'logs').
  /// - [metadata]: Contextual metadata to include in the output columns.
  const ToonFormatter({
    this.delimiter = '\t',
    this.arrayName = 'logs',
    this.metadata = const {
      LogMetadata.timestamp,
      LogMetadata.logger,
      LogMetadata.origin,
    },
  });

  /// The character used to separate values.
  final String delimiter;

  /// The name of the array in the header (e.g., 'logs').
  final String arrayName;

  /// Contextual metadata to include.
  @override
  final Set<LogMetadata> metadata;

  @override
  LogDocument format(final LogEntry entry, final LogContext context) {
    final nodes = <LogNode>[];

    // 1. Header
    final metaNames = metadata.map((final m) => m.name).join(',');
    const crucialNames = 'level,message,error,stackTrace';
    final headerStr = '$arrayName[]'
        '{$metaNames${metaNames.isNotEmpty ? ',' : ''}$crucialNames}:';

    nodes.add(HeaderNode(segments: [StyledText(headerStr)]));

    // 2. Row
    final segments = <StyledText>[];
    void add(final String val) {
      if (segments.isNotEmpty) {
        segments.add(StyledText(delimiter));
      }
      segments.add(StyledText(_escapeRaw(val)));
    }

    for (final meta in metadata) {
      add(meta.getValue(entry));
    }

    add(entry.level.name.toUpperCase());
    add(entry.message);
    add(entry.error?.toString() ?? '');
    add(entry.stackTrace?.toString() ?? '');

    nodes.add(MessageNode(segments: segments));

    return LogDocument(nodes: nodes);
  }

  String _escapeRaw(final String value) {
    if (value.isEmpty) {
      return '';
    }
    if (!value.contains(delimiter) &&
        !value.contains('\n') &&
        !value.contains('\r') &&
        !value.contains('"') &&
        !value.contains(':')) {
      return value;
    }
    return '"${value.replaceAll('"', r'\"').replaceAll(
          '\n',
          r'\n',
        ).replaceAll('\r', r'\r')}"';
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ToonFormatter &&
          runtimeType == other.runtimeType &&
          delimiter == other.delimiter &&
          arrayName == other.arrayName &&
          setEquals(metadata, other.metadata);

  @override
  int get hashCode =>
      Object.hash(runtimeType, delimiter, arrayName, Object.hashAll(metadata));
}

/// A [LogFormatter] for TOON with "Wise" object representation.
///
/// TOON-Pretty enhances basic TOON by recursively formatting complex objects
/// (Maps and Lists) inside columns using a compact, token-efficient notation:
/// - Maps: `{key:val,key2:val2}`
/// - Lists: `[val1,val2]`
///
/// It also supports hierarchical metadata tagging for coloring and respects
/// "Wisdom" principles like key sorting and depth control.
@immutable
final class ToonPrettyFormatter implements LogFormatter {
  /// Creates a [ToonPrettyFormatter].
  ///
  /// - [delimiter]: The separator between values. Defaults to tab (`\t`).
  /// - [arrayName]: The name of the array in the header (e.g., 'logs').
  /// - [color]: Whether to emit semantic tags for coloring.
  /// - [metadata]: Contextual metadata to include.
  /// - [sortKeys]: Whether to sort Map keys alphabetically.
  /// - [maxDepth]: Maximum depth for recursive object serialization.
  const ToonPrettyFormatter({
    this.delimiter = '\t',
    this.arrayName = 'logs',
    this.color = true,
    this.metadata = const {
      LogMetadata.timestamp,
      LogMetadata.logger,
      LogMetadata.origin,
    },
    this.sortKeys = false,
    this.maxDepth = 5,
  });

  /// The character used to separate values.
  final String delimiter;

  /// The name of the array in the header.
  final String arrayName;

  /// Whether to emit semantic tags for coloring.
  final bool color;

  /// Metadata to include.
  @override
  final Set<LogMetadata> metadata;

  /// Whether to sort Map keys alphabetically.
  final bool sortKeys;

  /// Maximum depth for recursion.
  final int maxDepth;

  @override
  LogDocument format(final LogEntry entry, final LogContext context) {
    final nodes = <LogNode>[];

    // 1. Header
    final metaNames = metadata.map((final m) => m.name).join(',');
    const crucialNames = 'level,message,error,stackTrace';
    final headerStr = '$arrayName[]'
        '{$metaNames${metaNames.isNotEmpty ? ',' : ''}$crucialNames}:';

    nodes.add(
      HeaderNode(
        segments: [
          StyledText(headerStr, tags: color ? const {LogTag.header} : const {}),
        ],
      ),
    );

    // 2. Row
    final segments = <StyledText>[];
    void add(final Object? val, final LogTag tag) {
      if (segments.isNotEmpty) {
        segments.add(
          StyledText(
            delimiter,
            tags: color ? {LogTag.punctuation} : const {},
          ),
        );
      }
      segments.add(
        StyledText(_formatValue(val, 0), tags: color ? {tag} : const {}),
      );
    }

    for (final meta in metadata) {
      add(meta.getValue(entry), meta.tag);
    }

    add(entry.level.name.toUpperCase(), LogTag.level);
    add(entry.message, LogTag.message);
    add(entry.error, LogTag.error);
    add(entry.stackTrace, LogTag.stackFrame);

    nodes.add(MessageNode(segments: segments));

    return LogDocument(nodes: nodes);
  }

  String _formatValue(final Object? value, final int depth) {
    if (value == null) {
      return '';
    }
    if (depth >= maxDepth && (value is Map || value is List)) {
      return '...';
    }

    if (value is Map) {
      final entries = value.entries.toList();
      if (sortKeys) {
        entries.sort(
          (final a, final b) => a.key.toString().compareTo(b.key.toString()),
        );
      }
      final items = entries
          .map(
            (final e) => '${_formatValue(e.key, depth + 1)}:${_formatValue(
              e.value,
              depth + 1,
            )}',
          )
          .join(',');
      return '{$items}';
    } else if (value is List) {
      final items =
          value.map((final e) => _formatValue(e, depth + 1)).join(',');
      return '[$items]';
    }

    return _escape(value.toString());
  }

  String _escape(final String value) {
    if (value.isEmpty) {
      return '';
    }
    final hasDelimiter = value.contains(delimiter);
    final hasNewline = value.contains('\n') || value.contains('\r');
    final hasSpecial = value.contains('{') ||
        value.contains('}') ||
        value.contains('[') ||
        value.contains(']') ||
        value.contains(':') ||
        value.contains(',');

    if (!hasDelimiter && !hasNewline && !hasSpecial && !value.contains('"')) {
      return value;
    }

    return '"${value.replaceAll('"', r'\"').replaceAll(
          '\n',
          r'\n',
        ).replaceAll(
          '\r',
          r'\r',
        )}"';
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ToonPrettyFormatter &&
          runtimeType == other.runtimeType &&
          delimiter == other.delimiter &&
          arrayName == other.arrayName &&
          color == other.color &&
          sortKeys == other.sortKeys &&
          maxDepth == other.maxDepth &&
          setEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        delimiter,
        arrayName,
        color,
        sortKeys,
        maxDepth,
        Object.hashAll(metadata),
      );
}
