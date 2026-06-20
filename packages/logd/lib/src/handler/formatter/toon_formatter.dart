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
  /// - [explicitSchema]: Whether to include a typed, aligned schema definition
  ///   in the header block (default: false).
  const ToonFormatter({
    this.delimiter = '\t',
    this.arrayName = 'logs',
    this.metadata = const {
      LogMetadata.timestamp,
      LogMetadata.logger,
      LogMetadata.origin,
    },
    this.explicitSchema = false,
  });

  /// Whether to include an explicit schema definition in the header.
  final bool explicitSchema;

  /// The character used to separate values.
  final String delimiter;

  /// The name of the array in the header (e.g., 'logs').
  final String arrayName;

  /// Contextual metadata to include.
  @override
  final Set<LogMetadata> metadata;

  @override
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    final columns = <String>[];
    final schema = <String, ToonType>{};
    final messageLines = entry.message.split('\n');
    var isFirst = true;

    for (final line in messageLines) {
      final map = <String, Object?>{};

      void add(final String key, final Object? value, final ToonType type) {
        if (isFirst) {
          columns.add(key);
          schema[key] = type;
        }
        map[key] = value;
      }

      for (final meta in metadata) {
        add(meta.name, meta.getValue(entry), meta.toonType);
      }

      add(
        'level',
        entry.level.name.toUpperCase(),
        ToonType(
          'enum',
          LogLevel.values.map((final e) => e.name.toUpperCase()).join(','),
        ),
      );
      add('message', line, ToonType.markdown);
      add('error', entry.error ?? '', ToonType.string);
      add('stackTrace', entry.stackTrace ?? '', ToonType.stacktrace);
      if (entry.context != null && entry.context!.isNotEmpty) {
        add('context', entry.context, ToonType.string);
      }

      document.metadataBlock(map, factory: factory);
      isFirst = false;
    }

    document
      ..metadata['toon_array'] = arrayName
      ..metadata['toon_delimiter'] = delimiter
      ..metadata['toon_columns'] = columns
      ..metadata['toon_schema'] = explicitSchema ? schema : null;
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
/// (Maps and Lists) inside columns using a compact, token-efficient notation.
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
  /// - [explicitSchema]: Whether to include a typed, aligned schema definition
  ///   in the header block (default: false).
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
    this.explicitSchema = false,
  });

  /// Whether to include an explicit schema definition in the header.
  final bool explicitSchema;

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
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    final columns = <String>[];
    final tags = <String, int>{};
    final schema = <String, ToonType>{};
    final messageLines = entry.message.split('\n');
    var isFirst = true;

    for (final line in messageLines) {
      final map = <String, Object?>{};

      void add(
        final String key,
        final Object? value,
        final int tag,
        final ToonType type,
      ) {
        if (isFirst) {
          columns.add(key);
          tags[key] = tag;
          schema[key] = type;
        }
        map[key] = value;
      }

      for (final meta in metadata) {
        add(meta.name, meta.getValue(entry), meta.tag, meta.toonType);
      }

      add(
        'level',
        entry.level.name.toUpperCase(),
        LogTag.level,
        ToonType(
          'enum',
          LogLevel.values.map((final e) => e.name.toUpperCase()).join(','),
        ),
      );
      add('message', line, LogTag.message, ToonType.markdown);
      add('error', entry.error ?? '', LogTag.error, ToonType.string);
      add(
        'stackTrace',
        entry.stackTrace ?? '',
        LogTag.stackFrame,
        ToonType.stacktrace,
      );
      if (entry.context != null && entry.context!.isNotEmpty) {
        add('context', entry.context, LogTag.preview, ToonType.string);
      }

      document.metadataBlock(
        map,
        tags: color ? LogTag.message : LogTag.none,
        factory: factory,
      );
      isFirst = false;
    }

    document
      ..metadata['toon_array'] = arrayName
      ..metadata['toon_delimiter'] = delimiter
      ..metadata['toon_columns'] = columns
      ..metadata['toon_tags'] = tags
      ..metadata['toon_sort_keys'] = sortKeys
      ..metadata['toon_max_depth'] = maxDepth
      ..metadata['toon_color'] = color
      ..metadata['toon_schema'] = explicitSchema ? schema : null;
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
