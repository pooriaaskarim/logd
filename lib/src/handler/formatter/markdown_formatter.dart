part of '../handler.dart';

/// A [LogFormatter] that transforms log entries into GitHub-Flavored Markdown.
///
/// Generates well-structured Markdown suitable for documentation, GitHub issues,
/// or knowledge bases. Includes syntax highlighting, tables, and semantic structure.
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
  /// - [useCodeBlocks]: Whether to wrap messages in code blocks (default: true).
  /// - [headingLevel]: Heading level for log entries (1-6, default: 3).
  const MarkdownFormatter({
    this.useCodeBlocks = true,
    this.headingLevel = 3,
  });

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

    // Heading: Level + Logger
    yield LogLine([
      LogSegment(
        '$h $levelIcon ${entry.level.name.toUpperCase()} - ${entry.loggerName}',
        tags: const {LogTag.header, LogTag.level, LogTag.loggerName},
      ),
    ]);

    yield const LogLine([LogSegment('', tags: {})]);

    // Metadata table
    yield const LogLine([
      LogSegment('| Field | Value |', tags: {LogTag.header}),
    ]);
    yield const LogLine([
      LogSegment('|-------|-------|', tags: {LogTag.header}),
    ]);
    yield LogLine([
      LogSegment(
        '| **Timestamp** | `${entry.timestamp}` |',
        tags: const {LogTag.header, LogTag.timestamp},
      ),
    ]);
    yield LogLine([
      LogSegment(
        '| **Origin** | `${entry.origin}` |',
        tags: const {LogTag.origin},
      ),
    ]);

    yield const LogLine([LogSegment('', tags: {})]);

    // Message
    if (useCodeBlocks) {
      yield const LogLine([
        LogSegment('```', tags: {LogTag.message}),
      ]);
    }

    // Split message into lines for proper markdown
    final messageLines = entry.message.split('\n');
    for (final line in messageLines) {
      yield LogLine([
        LogSegment(line, tags: const {LogTag.message}),
      ]);
    }

    if (useCodeBlocks) {
      yield const LogLine([
        LogSegment('```', tags: {LogTag.message}),
      ]);
    }

    // Error
    if (entry.error != null) {
      yield const LogLine([LogSegment('', tags: {})]);
      yield const LogLine([
        LogSegment('**Error:**', tags: {LogTag.error}),
      ]);
      yield const LogLine([
        LogSegment('```', tags: {LogTag.error}),
      ]);

      final errorLines = entry.error.toString().split('\n');
      for (final line in errorLines) {
        yield LogLine([
          LogSegment(line, tags: const {LogTag.error}),
        ]);
      }

      yield const LogLine([
        LogSegment('```', tags: {LogTag.error}),
      ]);
    }

    // Stack trace
    if (entry.stackFrames != null && entry.stackFrames!.isNotEmpty) {
      yield const LogLine([LogSegment('', tags: {})]);
      yield const LogLine([
        LogSegment('**Stack Trace:**', tags: {LogTag.stackFrame}),
      ]);
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
    }

    // Separator
    yield const LogLine([LogSegment('', tags: {})]);
    yield const LogLine([
      LogSegment('---', tags: {LogTag.border}),
    ]);
    yield const LogLine([LogSegment('', tags: {})]);
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
          headingLevel == other.headingLevel;

  @override
  int get hashCode => Object.hash(useCodeBlocks, headingLevel);
}
