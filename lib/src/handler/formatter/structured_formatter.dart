part of '../handler.dart';

/// A [LogFormatter] that formats log entries in a structured layout.
///
/// This formatter provides detailed output by organizing the log message
/// and its metadata (timestamp, level, origin) in a structured format with
/// clear visual separators. It supports auto-wrapping for long content.
///
@immutable
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
      // const LogLine('\n'),
    ];
  }

  List<LogLine> _buildHeader(final LogEntry entry, final int width) {
    final logger = '[${entry.loggerName}]';
    final level = '[${entry.level.name.toUpperCase()}]';
    final ts = entry.timestamp;
    final header = '$logger$level\n$ts';
    const prefix = '____';
    final wrapWidth = (width - prefix.length).clamp(1, double.infinity).toInt();
    final raw =
        header.split('\n').where((final l) => l.trim().isNotEmpty).toList();
    final out = <LogLine>[];
    for (final line in raw) {
      final wrapped = _wrap(line, wrapWidth);
      for (int i = 0; i < wrapped.length; i++) {
        out.add(
          LogLine([
            LogSegment(
              prefix +
                  wrapped[i]
                      .padRightVisiblePreserveAnsi(wrapWidth, '_')
                      .padLeft(16, '_'),
              tags: {LogTag.header},
            ),
          ]),
        );
      }
    }
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
