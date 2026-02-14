part of '../handler.dart';

/// A [LogFormatter] that transforms log entries into HTML markup.
///
/// Generates semantic HTML with CSS classes for styling. Designed to be used
/// with [HTMLSink] to create styled HTML log files that can be viewed in
/// browsers.
///
/// Each log entry is wrapped in semantic HTML elements with appropriate CSS
/// classes that can be styled based on log level and component type.
@immutable
final class HTMLFormatter implements LogFormatter {
  /// Creates an [HTMLFormatter].
  ///
  /// - [metadata]: List of [LogMetadata] to include in the output.
  const HTMLFormatter({
    this.metadata = const {
      LogMetadata.timestamp,
      LogMetadata.logger,
      LogMetadata.origin,
    },
  });

  /// The contextual metadata to include.
  @override
  final Set<LogMetadata> metadata;

  @override
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    // Entry container
    yield LogLine([
      LogSegment(
        '<div class="log-entry log-${entry.level.name}">',
        tags: const {LogTag.border},
      ),
    ]);

    // Header section
    yield const LogLine([
      LogSegment('  <div class="log-header">', tags: {LogTag.header}),
    ]);

    // Timestamp
    if (metadata.contains(LogMetadata.timestamp)) {
      yield LogLine([
        LogSegment(
          '    <span class="log-timestamp">${_escapeHtml(entry.timestamp)}</span>',
          tags: const {LogTag.header, LogTag.timestamp},
        ),
      ]);
    }

    // Level
    yield LogLine([
      LogSegment(
        '    <span class="log-level">[${entry.level.name.toUpperCase()}]</span>',
        tags: const {LogTag.header, LogTag.level},
      ),
    ]);

    // Logger name
    if (metadata.contains(LogMetadata.logger)) {
      yield LogLine([
        LogSegment(
          '    <span class="log-logger">[${_escapeHtml(entry.loggerName)}]</span>',
          tags: const {LogTag.header, LogTag.loggerName},
        ),
      ]);
    }

    yield const LogLine([
      LogSegment('  </div>', tags: {LogTag.header}),
    ]);

    // Origin
    if (metadata.contains(LogMetadata.origin)) {
      yield LogLine([
        LogSegment(
          '  <div class="log-origin">${_escapeHtml(entry.origin)}</div>',
          tags: const {LogTag.origin},
        ),
      ]);
    }

    // Message
    yield LogLine([
      LogSegment(
        '  <div class="log-message">${_escapeHtml(entry.message)}</div>',
        tags: const {LogTag.message},
      ),
    ]);

    // Error
    if (entry.error != null) {
      yield LogLine([
        LogSegment(
          '  <div class="log-error">Error: '
          '${_escapeHtml(entry.error.toString())}</div>',
          tags: const {LogTag.error},
        ),
      ]);
    }

    // Stack trace
    if (entry.stackFrames != null && entry.stackFrames!.isNotEmpty) {
      yield const LogLine([
        LogSegment('  <div class="log-stacktrace">', tags: {LogTag.stackFrame}),
      ]);

      for (final frame in entry.stackFrames!) {
        final frameText =
            'at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';
        yield LogLine([
          LogSegment(
            '    <div class="stack-frame">${_escapeHtml(frameText)}</div>',
            tags: const {LogTag.stackFrame},
          ),
        ]);
      }

      yield const LogLine([
        LogSegment('  </div>', tags: {LogTag.stackFrame}),
      ]);
    } else if (entry.stackTrace != null) {
      yield const LogLine([
        LogSegment('  <div class="log-stacktrace">', tags: {LogTag.stackFrame}),
      ]);
      final traceLines = entry.stackTrace.toString().split('\n');
      for (final line in traceLines) {
        if (line.trim().isEmpty) {
          continue;
        }
        yield LogLine([
          LogSegment(
            '    <div class="stack-frame">${_escapeHtml(line)}</div>',
            tags: const {LogTag.stackFrame},
          ),
        ]);
      }
      yield const LogLine([
        LogSegment('  </div>', tags: {LogTag.stackFrame}),
      ]);
    }

    // Close entry container
    yield const LogLine([
      LogSegment('</div>', tags: {LogTag.border}),
    ]);
  }

  /// Escapes HTML special characters.
  String _escapeHtml(final String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is HTMLFormatter &&
          runtimeType == other.runtimeType &&
          setEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(metadata));
}
