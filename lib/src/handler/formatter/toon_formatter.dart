part of '../handler.dart';

/// A [LogFormatter] that facilitates Token-Oriented Object Notation (TOON).
///
/// TOON is a compact, token-efficient format designed for feeding logs into
/// Large Language Models (LLMs). It uses a header definition followed by
/// uniform rows of values separated by a delimiter (default: Tab).
///
/// Example Output:
/// ```text
/// logs[]{timestamp,level,logger,message,error}:
/// 2025-01-01T10:00:00Z	INFO	auth	User logged in
/// 2025-01-01T10:00:05Z	WARN	db	Slow query: "SELECT * FROM users"
/// ```
class ToonFormatter implements LogFormatter {
  /// Creates a [ToonFormatter].
  ///
  /// - [delimiter]: The separator between values. Defaults to tab (`\t`) for
  ///   maximum token efficiency. Common alternatives: comma (`,`)
  ///   or pipe (`|`).
  /// - [arrayName]: The name of the array in the header (e.g., 'logs').
  /// - [keys]: The list of [LogField]s to include in the output columns.
  /// - [colorize]: Whether to emit semantic tags for coloring.
  ///   Defaults to `false`.
  ToonFormatter({
    this.delimiter = '\t',
    this.arrayName = 'logs',
    this.keys = const [
      LogField.timestamp,
      LogField.level,
      LogField.logger,
      LogField.message,
      LogField.error,
    ],
    this.colorize = false,
  });

  /// The character used to separate values.
  final String delimiter;

  /// The name of the array in the header (e.g., 'logs').
  final String arrayName;

  /// The keys/columns to include in the output.
  final List<LogField> keys;

  /// Whether to emit semantic tags for coloring.
  final bool colorize;

  /// Tracks if the header has been emitted for this instance.
  bool _headerEmitted = false;

  @override
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) {
    final lines = <LogLine>[];

    if (!_headerEmitted) {
      _headerEmitted = true;
      final headerStr =
          '$arrayName[]{${keys.map((final k) => k.name).join(',')}}:';

      if (colorize) {
        // Header is structural/metadata
        lines.add(
          LogLine([
            LogSegment(
              headerStr,
              tags: const {LogTag.header},
            ),
          ]),
        );
      } else {
        lines.add(LogLine.text(headerStr));
      }
    }

    if (colorize) {
      lines.add(_formatColorizedRow(entry));
    } else {
      lines.add(_formatPlainRow(entry));
    }

    return lines;
  }

  LogLine _formatPlainRow(final LogEntry entry) {
    final buffer = StringBuffer();
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) {
        buffer.write(delimiter);
      }
      buffer.write(_escapeAndQuote(keys[i].getValue(entry)));
    }
    return LogLine.text(buffer.toString());
  }

  LogLine _formatColorizedRow(final LogEntry entry) {
    final segments = <LogSegment>[];
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) {
        segments.add(
          LogSegment(
            delimiter,
            tags: const {LogTag.border},
          ),
        );
      }
      final key = keys[i];
      final value = _escapeAndQuote(key.getValue(entry));
      segments.add(LogSegment(value, tags: _tagsFor(key)));
    }
    return LogLine(segments);
  }

  Set<LogTag> _tagsFor(final LogField key) {
    switch (key) {
      case LogField.timestamp:
        return const {LogTag.timestamp};
      case LogField.level:
        return const {LogTag.level};
      case LogField.logger:
        return const {LogTag.loggerName};
      case LogField.origin:
        return const {LogTag.origin};
      case LogField.message:
        return const {LogTag.message};
      case LogField.error:
        return const {LogTag.error};
      case LogField.stackTrace:
        return const {LogTag.stackFrame};
    }
  }

  /// Escapes content if it contains the delimiter, newlines, or other control
  /// chars.
  /// TOON logic: Quote only if necessary.
  String _escapeAndQuote(final String value) {
    if (value.isEmpty) {
      return '';
    }

    final hasDelimiter = value.contains(delimiter);
    final hasNewline = value.contains('\n') || value.contains('\r');
    final hasQuote = value.contains('"');
    final hasColon = value
        .contains(':'); // TOON specifically mentions colons might need quoting

    if (!hasDelimiter && !hasNewline && !hasQuote && !hasColon) {
      return value;
    }

    final buffer = StringBuffer('"');
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char == '"') {
        buffer.write(r'\"');
      } else if (char == '\n') {
        buffer.write(r'\n');
      } else if (char == '\r') {
        buffer.write(r'\r');
      } else {
        buffer.write(char);
      }
    }
    buffer.write('"');
    return buffer.toString();
  }
}
