part of '../handler.dart';

/// A lightweight formatter that outputs log entries as simple, readable text.
///
/// By default, it includes the log level, timestamp, logger name, and the
/// message. These components can be toggled via constructor parameters.
///
/// Example output:
/// `[INFO] 2025-01-01 10:00:00 [main] Hello, World!`
@immutable
final class PlainFormatter implements LogFormatter {
  /// Creates a [PlainFormatter] with customizable output components.
  const PlainFormatter({
    this.includeLevel = true,
    this.includeTimestamp = true,
    this.includeLoggerName = true,
  });

  /// Whether to include the uppercase [LogLevel] name (e.g., `[INFO]`).
  final bool includeLevel;

  /// Whether to include the formatted timestamp from the [LogEntry].
  final bool includeTimestamp;

  /// Whether to include the name of the logger (e.g., `[main]`).
  final bool includeLoggerName;

  @override
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    final segments = <LogSegment>[];

    if (includeLevel) {
      segments
        ..add(
          LogSegment(
            '[${entry.level.name.toUpperCase()}]',
            tags: const {LogTag.header, LogTag.level},
          ),
        )
        ..add(
          const LogSegment(
            ' ',
          ),
        );
    }

    if (includeTimestamp) {
      segments
        ..add(
          LogSegment(
            entry.timestamp,
            tags: const {LogTag.header, LogTag.timestamp},
          ),
        )
        ..add(
          const LogSegment(
            ' ',
          ),
        );
    }

    if (includeLoggerName) {
      segments
        ..add(
          LogSegment(
            '[${entry.loggerName}]',
            tags: const {LogTag.header, LogTag.loggerName},
          ),
        )
        ..add(
          const LogSegment(
            ' ',
          ),
        );
    }

    final messageLines = entry.message.split('\n');
    if (messageLines.isNotEmpty) {
      final firstLineSegments = [
        ...segments,
        LogSegment(
          messageLines.first,
          tags: const {LogTag.message},
        ),
      ];
      yield LogLine(firstLineSegments);

      for (int i = 1; i < messageLines.length; i++) {
        yield LogLine([
          LogSegment(messageLines[i], tags: const {LogTag.message}),
        ]);
      }
    } else {
      yield LogLine(segments);
    }

    if (entry.error != null) {
      yield LogLine([
        LogSegment('Error: ${entry.error}', tags: const {LogTag.error}),
      ]);
    }

    if (entry.stackTrace != null) {
      final traceLines = entry.stackTrace.toString().split('\n');
      for (final line in traceLines) {
        if (line.trim().isNotEmpty) {
          yield LogLine([
            LogSegment(line, tags: const {LogTag.stackFrame}),
          ]);
        }
      }
    }
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is PlainFormatter &&
          runtimeType == other.runtimeType &&
          includeLevel == other.includeLevel &&
          includeTimestamp == other.includeTimestamp &&
          includeLoggerName == other.includeLoggerName;

  @override
  int get hashCode =>
      Object.hash(includeLevel, includeTimestamp, includeLoggerName);
}
