part of '../handler.dart';

/// A [LogFormatter] that facilitates Token-Oriented Object Notation (TOON).
///
/// TOON is a compact, token-efficient format designed for feeding logs into
/// Large Language Models (LLMs). It uses a header definition followed by
/// uniform rows of values separated by a delimiter (default: Tab).
@immutable
final class ToonFormatter implements LogFormatter {
  /// Creates a [ToonFormatter].
  ///
  /// - [delimiter]: The separator between values. Defaults to tab (`\t`).
  /// - [arrayName]: The name of the array in the header (e.g., 'logs').
  /// - [metadata]: Contextual metadata to include in the output columns.
  /// - [color]: Whether to emit semantic tags for coloring.
  ///   metadata: {LogMetadata.timestamp, LogMetadata.logger,
  ///   LogMetadata.origin},
  ///   color: true,
  ///   multiline: true,
  /// );
  /// ```
  const ToonFormatter({
    this.delimiter = '\t',
    this.arrayName = 'logs',
    this.metadata = const {
      LogMetadata.timestamp,
      LogMetadata.logger,
      LogMetadata.origin,
    },
    this.color = false,
    this.multiline = false,
  });

  /// The character used to separate values.
  final String delimiter;

  /// The name of the array in the header (e.g., 'logs').
  final String arrayName;

  /// Contextual metadata to include.
  @override
  final Set<LogMetadata> metadata;

  /// Whether to emit semantic tags for coloring.
  final bool color;

  /// Whether to allow actual newlines in strings (rather than escaping to \n).
  /// Recommended for visual high-detail benchmarks but can break machine
  /// parsers.
  final bool multiline;

  @override
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    // Header includes metadata followed by crucial fields
    final metaNames = metadata.map((final m) => m.name).join(',');
    const crucialNames = 'level,message,error,stackTrace';
    final headerStr =
        '$arrayName[]{$metaNames${metaNames.isNotEmpty ? ',' : ''}'
        '$crucialNames}:';

    final headerLine = color
        ? LogLine([
            LogSegment(headerStr, tags: const {LogTag.header}),
          ])
        : LogLine.text(headerStr);

    yield* headerLine.wrap(context.availableWidth);

    final rowLine = color ? _formatColorizedRow(entry) : _formatPlainRow(entry);

    yield* rowLine.wrap(context.availableWidth);
  }

  LogLine _formatPlainRow(final LogEntry entry) {
    final values = [
      ...metadata.map((final m) => m.getValue(entry)),
      entry.level.name,
      entry.message,
      entry.error?.toString() ?? '',
      entry.stackTrace?.toString() ?? '',
    ];

    return LogLine.text(values.map(_escapeAndQuote).join(delimiter));
  }

  LogLine _formatColorizedRow(final LogEntry entry) {
    final segments = <LogSegment>[];

    void add(final String val, final LogTag tag) {
      if (segments.isNotEmpty) {
        segments.add(LogSegment(delimiter, tags: const {LogTag.punctuation}));
      }
      segments.add(LogSegment(_escapeAndQuote(val), tags: {tag}));
    }

    for (final meta in metadata) {
      add(meta.getValue(entry), meta.tag);
    }

    add(entry.level.name, LogTag.level);
    add(entry.message, LogTag.message);
    add(entry.error?.toString() ?? '', LogTag.error);
    add(entry.stackTrace?.toString() ?? '', LogTag.stackFrame);

    return LogLine(segments);
  }

  String _escapeAndQuote(final String value) {
    if (value.isEmpty) {
      return '';
    }
    final hasDelimiter = value.contains(delimiter);
    final hasNewline = value.contains('\n') || value.contains('\r');
    final hasQuote = value.contains('"');
    final hasColon = value.contains(':');

    if (!hasDelimiter && !hasNewline && !hasQuote && !hasColon) {
      return value;
    }

    final buffer = StringBuffer('"');
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      switch (char) {
        case '"':
          buffer.write(r'\"');
          break;
        case '\n':
          if (multiline) {
            buffer.write('\n');
          } else {
            buffer.write(r'\n');
          }
          break;
        case '\r':
          if (multiline) {
            buffer.write('\r');
          } else {
            buffer.write(r'\r');
          }
          break;
        default:
          buffer.write(char);
      }
    }
    buffer.write('"');
    return buffer.toString();
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ToonFormatter &&
          runtimeType == other.runtimeType &&
          delimiter == other.delimiter &&
          arrayName == other.arrayName &&
          color == other.color &&
          setEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        delimiter,
        arrayName,
        color,
        Object.hashAll(metadata),
      );
}
