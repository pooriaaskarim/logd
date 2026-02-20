part of '../handler.dart';

/// Abstract interface for formatting a [LogEntry] into a sequence of
/// text lines.
///
/// Formatters are responsible for the structural representation of a log entry,
/// such as converting it to JSON, a boxed layout, or a simple plain text line.
abstract interface class LogFormatter {
  const LogFormatter({required this.metadata});

  /// Contextual metadata to include in the output.
  final Set<LogMetadata> metadata;

  LogDocument format(final LogEntry entry);
}
