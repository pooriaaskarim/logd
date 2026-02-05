part of '../handler.dart';

/// Abstract interface for formatting a [LogEntry] into [LogDocument].
///
/// Formatters are responsible for Structuring the output produced from
/// a log entry. Determine the data and how it should be shown.
abstract interface class LogFormatter {
  const LogFormatter({required this.metadata});

  /// Contextual metadata to include in the output.
  final Set<LogMetadata> metadata;

  /// Formats the [entry] into a [LogDocument].
  LogDocument format(final LogEntry entry, final LogContext context);
}
