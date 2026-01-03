part of '../handler.dart';

/// Abstract interface for formatting a [LogEntry] into a sequence of
/// text lines.
///
/// Formatters are responsible for the structural representation of a log entry,
/// such as converting it to JSON, a boxed layout, or a simple plain text line.
abstract interface class LogFormatter {
  const LogFormatter();

  /// Formats the [entry] into an [Iterable] of [LogLine]s.
  ///
  /// Using [Iterable] enables lazy evaluation and efficient processing when
  /// chaining multiple formatters or applying decorators.
  Iterable<LogLine> format(final LogEntry entry);
}
