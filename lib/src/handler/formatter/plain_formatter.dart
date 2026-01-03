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
  Iterable<String> format(final LogEntry entry) sync* {
    final buffer = StringBuffer();

    if (includeLevel) {
      buffer.write('[${entry.level.name.toUpperCase()}] ');
    }

    if (includeTimestamp) {
      buffer.write('${entry.timestamp} ');
    }

    if (includeLoggerName) {
      buffer.write('[${entry.loggerName}] ');
    }

    buffer.write(entry.message);

    yield buffer.toString();

    if (entry.error != null) {
      yield 'Error: ${entry.error}';
    }

    if (entry.stackTrace != null) {
      yield entry.stackTrace.toString();
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
