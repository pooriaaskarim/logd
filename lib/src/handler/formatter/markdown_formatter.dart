part of '../handler.dart';

/// A [LogFormatter] that transforms log entries into GitHub-Flavored Markdown.
///
/// Generates well-structured Markdown suitable for documentation, GitHub
/// issues,
/// or knowledge bases. Includes syntax highlighting, tables,
/// and semantic structure.
///
/// The formatter creates readable markdown with:
/// - Headings for log levels
/// - Metadata tables
/// - Code blocks for messages
/// - Proper formatting for errors and stack traces
@immutable
final class MarkdownFormatter implements LogFormatter {
  /// Creates a [MarkdownFormatter].
  ///
  /// - [useCodeBlocks]: Whether to wrap messages in code blocks
  /// (default: true).
  /// - [headingLevel]: Heading level for log entries (1-6, default: 3).
  const MarkdownFormatter({
    this.metadata = const {
      LogMetadata.logger,
      LogMetadata.timestamp,
      LogMetadata.origin,
    },
    this.useCodeBlocks = true,
    this.headingLevel = 3,
  });

  @override
  final Set<LogMetadata> metadata;

  /// Whether to wrap log messages in code blocks.
  final bool useCodeBlocks;

  /// Heading level for log entries (1-6).
  final int headingLevel;

  @override
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    final h = '#' * headingLevel.clamp(1, 6);
    final levelIcon = _getLevelIcon(entry.level);

    // 1. Identity Header: [Icon] LEVEL | Logger | Timestamp
    final headerParts = <String>[
      '$levelIcon ${entry.level.name.toUpperCase()}',
      if (metadata.contains(LogMetadata.logger)) entry.loggerName,
      if (metadata.contains(LogMetadata.timestamp)) entry.timestamp,
    ];

    yield LogLine([
      LogSegment(
        '$h ${headerParts.join(' | ')}',
        tags: const {LogTag.header, LogTag.level},
      ),
    ]);

    // 2. Origin (Italicized on its own line if selected)
    if (metadata.contains(LogMetadata.origin)) {
      yield LogLine([
        LogSegment(
          '*Origin: ${entry.origin}*',
          tags: const {LogTag.origin},
        ),
      ]);
    }

    yield const LogLine([LogSegment('', tags: {})]);

    // 3. Message (Blockquoted for impact)
    final messageLines = entry.message.split('\n');
    for (int i = 0; i < messageLines.length; i++) {
      yield LogLine([
        LogSegment(
          '> ${messageLines[i]}',
          tags: const {LogTag.message},
        ),
      ]);
    }

    // 4. Error (Bolded blockquote)
    if (entry.error != null) {
      yield const LogLine([LogSegment('', tags: {})]);
      final errorLines = entry.error.toString().split('\n');
      for (final line in errorLines) {
        yield LogLine([
          LogSegment(
            '> **Error:** $line',
            tags: const {LogTag.error},
          ),
        ]);
      }
    }

    // 5. Stack trace (Collapsible for cleanliness)
    if (entry.stackFrames != null && entry.stackFrames!.isNotEmpty) {
      yield const LogLine([LogSegment('', tags: {})]);
      yield const LogLine([
        LogSegment('<details>', tags: {LogTag.stackFrame}),
      ]);
      yield const LogLine([
        LogSegment(
          '<summary>Stack Trace</summary>',
          tags: {LogTag.stackFrame},
        ),
      ]);
      yield const LogLine([LogSegment('', tags: {})]);
      yield const LogLine([
        LogSegment('```', tags: {LogTag.stackFrame}),
      ]);

      for (final frame in entry.stackFrames!) {
        final frameText =
            'at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';
        yield LogLine([
          LogSegment(frameText, tags: const {LogTag.stackFrame}),
        ]);
      }

      yield const LogLine([
        LogSegment('```', tags: {LogTag.stackFrame}),
      ]);
      yield const LogLine([
        LogSegment('</details>', tags: {LogTag.stackFrame}),
      ]);
    }

    // 6. Separator
    yield const LogLine([LogSegment('', tags: {})]);
    yield const LogLine([
      LogSegment('---', tags: {LogTag.border}),
    ]);
  }

  /// Gets an emoji icon for the log level.
  String _getLevelIcon(final LogLevel level) {
    switch (level) {
      case LogLevel.trace:
        return '🔍';
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is MarkdownFormatter &&
          runtimeType == other.runtimeType &&
          useCodeBlocks == other.useCodeBlocks &&
          headingLevel == other.headingLevel &&
          setEquals(
            metadata,
            other.metadata,
          );

  @override
  int get hashCode => Object.hash(useCodeBlocks, headingLevel);
}
