part of '../handler.dart';

/// Abstract interface for transforming a [LogEntry] into a semantic
/// [LogDocument].
///
/// Formatters are responsible for the structural representation of a log entry,
/// such as producing a hierarchical data structure or an unadorned structural
/// payload, decoupled from specific serialization.
abstract interface class LogFormatter {
  const LogFormatter({required this.metadata});

  /// Contextual metadata to include in the output.
  final Set<LogMetadata> metadata;

  LogDocument format(final LogEntry entry);
}
