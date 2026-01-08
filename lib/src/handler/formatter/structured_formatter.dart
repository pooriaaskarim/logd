part of '../handler.dart';

/// A [LogFormatter] that formats log entries in a structured layout.
///
/// This formatter provides detailed output by organizing the log message
/// and its metadata (timestamp, level, origin) in a structured format with
/// clear visual separators. It supports auto-wrapping for long content.
///
/// Uses fine-grained semantic tags ([LogTag.timestamp], [LogTag.level],
/// [LogTag.loggerName]) within headers to enable tag-specific color overrides.
@immutable
final class StructuredFormatter implements LogFormatter {
  /// Creates a [StructuredFormatter] with customizable constraints.
  ///
  /// - [lineLength]: The maximum width for content wrapping.
  /// If provided, overrides [LogContext.availableWidth].
  const StructuredFormatter({
    this.lineLength,
  });

  /// The maximum line length for wrapping.
  final int? lineLength;

  @override
  Iterable<LogLine> format(final LogEntry entry, final LogContext context) {
    // Determine effective width: Config -> Context -> Default(80)
    final width = lineLength ?? context.availableWidth;
    final innerWidth = (width - 4).clamp(1, double.infinity).toInt();

    return <LogLine>[
      ..._buildHeader(entry, width),
      ..._buildOrigin(entry.origin, innerWidth),
      ..._buildMessage(entry.message, innerWidth),
      if (entry.error != null) ..._buildError(entry.error!, innerWidth),
      if (entry.stackFrames != null)
        ..._buildStackTrace(entry.stackFrames!, innerWidth),
    ];
  }

  List<LogLine> _buildHeader(final LogEntry entry, final int width) {
    const prefix = '____';

    final out = <LogLine>[];

    // First line: [loggerName][LEVEL] with fine-grained tags
    final loggerText = entry.loggerName;
    final levelText = entry.level.name.toUpperCase();

    // Calculate visible content: '[loggerName][LEVEL]'
    final contentLen =
        1 + loggerText.visibleLength + 2 + levelText.visibleLength + 1;
    // Total underscores to fill: width - prefix.length - contentLen
    final totalUnderscores = width - prefix.length - contentLen;

    final line1Segments = <LogSegment>[
      LogSegment(prefix, tags: {LogTag.header}),
      LogSegment('[', tags: {LogTag.header}),
      LogSegment(loggerText, tags: {LogTag.header, LogTag.loggerName}),
      LogSegment(']', tags: {LogTag.header}),
      LogSegment('[', tags: {LogTag.header}),
      LogSegment(levelText, tags: {LogTag.header, LogTag.level}),
      LogSegment(']', tags: {LogTag.header}),
    ];

    if (totalUnderscores > 0) {
      line1Segments.add(
        LogSegment('_' * totalUnderscores, tags: {LogTag.header}),
      );
    }

    out.add(LogLine(line1Segments));

    // Second line: timestamp with fine-grained tag
    final timestampText = entry.timestamp;
    final tsLen = timestampText.visibleLength;
    final tsUnderscores = width - prefix.length - tsLen;

    final line2Segments = <LogSegment>[
      LogSegment(prefix, tags: {LogTag.header}),
      LogSegment(timestampText, tags: {LogTag.header, LogTag.timestamp}),
    ];

    if (tsUnderscores > 0) {
      line2Segments.add(
        LogSegment('_' * tsUnderscores, tags: {LogTag.header}),
      );
    }

    out.add(LogLine(line2Segments));

    return out;
  }

  List<LogLine> _buildOrigin(final String origin, final int innerWidth) {
    const prefix = '--';
    final wrapWidth = innerWidth.clamp(1, double.infinity).toInt();
    final wrapped = _wrap(origin, wrapWidth);
    return wrapped.asMap().entries.map((final e) {
      final p = e.key == 0 ? prefix : ' ' * prefix.length;
      return LogLine([
        LogSegment(p + e.value, tags: {LogTag.origin}),
      ]);
    }).toList();
  }

  List<LogLine> _buildMessage(final String content, final int innerWidth) {
    final raw =
        content.split('\n').where((final l) => l.trim().isNotEmpty).toList();
    const prefix = '----|';
    final wrapWidth =
        (innerWidth - prefix.length + 1).clamp(1, double.infinity).toInt();
    final out = <LogLine>[];
    for (final line in raw) {
      final wrapped = _wrap(line, wrapWidth);
      for (int i = 0; i < wrapped.length; i++) {
        final p = i == 0 ? prefix : ' ' * prefix.length;
        out.add(LogLine([
          LogSegment(p + wrapped[i], tags: {LogTag.message}),
        ]));
      }
    }
    return out;
  }

  List<LogLine> _buildError(
    final Object error,
    final int innerWidth,
  ) {
    final raw = error
        .toString()
        .split('\n')
        .where((final l) => l.trim().isNotEmpty)
        .toList();
    const prefix = '----|';
    final wrapWidth =
        (innerWidth - prefix.length + 1).clamp(1, double.infinity).toInt();
    final lines = <LogLine>[
      ..._wrap('Error:', wrapWidth).map(
        (final l) => LogLine([
          LogSegment(
            prefix + l,
            tags: {LogTag.error},
          ),
        ]),
      ),
    ];
    for (final line in raw) {
      final wrapped = _wrap(line, wrapWidth);

      for (int i = 0; i < wrapped.length; i++) {
        final p = i == 0 ? prefix : ' ' * prefix.length;
        lines.add(LogLine([
          LogSegment(p + wrapped[i], tags: {LogTag.error}),
        ]));
      }
    }
    return lines;
  }

  List<LogLine> _buildStackTrace(
    final List<CallbackInfo> frames,
    final int innerWidth,
  ) {
    const prefix = '----|';
    final wrapWidth =
        (innerWidth - prefix.length + 1).clamp(1, double.infinity).toInt();
    final lines = <LogLine>[
      ..._wrap('Stack Trace:', wrapWidth).map(
        (final l) => LogLine([
          LogSegment(prefix + l, tags: {LogTag.stackFrame}),
        ]),
      ),
    ];
    for (final frame in frames) {
      final line =
          ' at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';
      final wrapped = _wrap(line, wrapWidth);
      for (int i = 0; i < wrapped.length; i++) {
        final p = i == 0 ? prefix : ' ' * prefix.length;
        lines.add(LogLine([
          LogSegment(p + wrapped[i], tags: {LogTag.stackFrame}),
        ]));
      }
    }
    return lines;
  }

  List<String> _wrap(final String text, final int maxWidth) =>
      text.wrapVisiblePreserveAnsi(maxWidth).toList();

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is StructuredFormatter &&
          runtimeType == other.runtimeType &&
          lineLength == other.lineLength;

  @override
  int get hashCode => lineLength.hashCode;
}
