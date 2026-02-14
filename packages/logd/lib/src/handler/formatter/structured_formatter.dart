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
  const StructuredFormatter({
    this.metadata = const {
      LogMetadata.origin,
      LogMetadata.timestamp,
      LogMetadata.logger,
    },
  });

  @override
  final Set<LogMetadata> metadata;
  @override
  Iterable<LogLine> format(final LogEntry entry, final LogContext context) {
    final width = context.availableWidth;
    final innerWidth = (width - 4).clamp(1, double.infinity).toInt();

    return <LogLine>[
      ..._buildHeader(entry, width),
      ..._buildMessage(entry.message, innerWidth),
      if (entry.error != null) ..._buildError(entry.error!, innerWidth),
      if (entry.stackFrames != null)
        ..._buildStackTrace(entry.stackFrames!, innerWidth),
    ];
  }

  List<LogLine> _buildHeader(final LogEntry entry, final int width) => [
        // Phase 1: Timestamp
        if (metadata.contains(LogMetadata.timestamp))
          ..._buildHeaderSection([(entry.timestamp, LogTag.timestamp)], width),

        // Phase 2: Level & Logger
        ..._buildHeaderSection(
          [
            ('[${entry.level.name.toUpperCase()}]', LogTag.level),
            if (metadata.contains(LogMetadata.logger))
              ('[${entry.loggerName}]', LogTag.loggerName),
          ],
          width,
        ),

        // Phase 3: Origin
        if (metadata.contains(LogMetadata.origin))
          ..._buildHeaderSection(
            [('[${entry.origin}]', LogTag.origin)],
            width,
          ),
      ];

  Iterable<LogLine> _buildHeaderSection(
    final List<(String text, LogTag? tag)> parts,
    final int width,
  ) sync* {
    if (parts.isEmpty) {
      return;
    }
    const prefix = '____';
    final contentWidth = (width - prefix.length).clamp(1, 1000);

    // 1. Build initial coarse segments, splitting by internal newlines
    final logicalLines = <List<LogSegment>>[[]];
    for (int i = 0; i < parts.length; i++) {
      final p = parts[i];
      if (i > 0 && logicalLines.last.isNotEmpty) {
        logicalLines.last.add(const LogSegment(' ', tags: {LogTag.header}));
      }

      final subLines = p.$1.split('\n');
      for (int j = 0; j < subLines.length; j++) {
        if (j > 0) {
          logicalLines.add([]);
        }
        logicalLines.last.add(
          LogSegment(
            subLines[j],
            tags: {
              LogTag.header,
              if (p.$2 != null) p.$2!,
            },
          ),
        );
      }
    }

    // 2. Wrap each logical line into the framing structure
    for (final logicalLine in logicalLines) {
      if (logicalLine.isEmpty) {
        continue;
      }

      var currentOutputLine = <LogSegment>[
        const LogSegment(prefix, tags: {LogTag.header}),
      ];
      var currentX = 0;

      for (final seg in logicalLine) {
        final textLines =
            LogLine([LogSegment(seg.text, tags: seg.tags)]).wrap(contentWidth);

        // If the first part of this segment doesn't fit on the current line,
        // force a new line immediately.
        if (currentX > 0 &&
            textLines.first.visibleLength > (contentWidth - currentX)) {
          yield* _finishLine(currentOutputLine, width);
          currentOutputLine = [
            const LogSegment(prefix, tags: {LogTag.header}),
          ];
          currentX = 0;
        }

        var isFirstSubLine = true;
        for (final textLine in textLines) {
          if (!isFirstSubLine) {
            // New line needed for subsequent wrapped parts
            yield* _finishLine(currentOutputLine, width);
            currentOutputLine = [
              const LogSegment(prefix, tags: {LogTag.header}),
            ];
            currentX = 0;
          }

          // Append segments from this text line
          for (final s in textLine.segments) {
            currentOutputLine.add(s);
            currentX += s.text.visibleLength;
          }
          isFirstSubLine = false;
        }
      }

      if (currentOutputLine.length > 1) {
        yield* _finishLine(currentOutputLine, width);
      }
    }
  }

  Iterable<LogLine> _finishLine(
    final List<LogSegment> line,
    final int totalWidth,
  ) sync* {
    final currentLen =
        line.fold(0, (final sum, final s) => sum + s.text.visibleLength);
    final fillerLen = totalWidth - currentLen;
    if (fillerLen > 0) {
      line.add(LogSegment('_' * fillerLen, tags: const {LogTag.header}));
    }
    yield LogLine(line);
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
        out.add(
          LogLine([
            LogSegment(p + wrapped[i], tags: const {LogTag.message}),
          ]),
        );
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
            tags: const {LogTag.error},
          ),
        ]),
      ),
    ];
    for (final line in raw) {
      final wrapped = _wrap(line, wrapWidth);

      for (int i = 0; i < wrapped.length; i++) {
        final p = i == 0 ? prefix : ' ' * prefix.length;
        lines.add(
          LogLine([
            LogSegment(p + wrapped[i], tags: const {LogTag.error}),
          ]),
        );
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
          LogSegment(prefix + l, tags: const {LogTag.stackFrame}),
        ]),
      ),
    ];
    for (final frame in frames) {
      final line =
          ' at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';
      final wrapped = _wrap(line, wrapWidth);
      for (int i = 0; i < wrapped.length; i++) {
        final p = i == 0 ? prefix : ' ' * prefix.length;
        lines.add(
          LogLine([
            LogSegment(p + wrapped[i], tags: const {LogTag.stackFrame}),
          ]),
        );
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
          setEquals(metadata, other.metadata);

  @override
  int get hashCode => runtimeType.hashCode;
}
