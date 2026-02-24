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

  /// Formats [entry] into a [LogDocument], using [arena] to check out nodes.
  ///
  /// The returned document and all nodes it contains are owned by [arena].
  /// The caller is responsible for calling [LogDocument.releaseRecursive]
  /// after the pipeline completes.
  LogDocument format(final LogEntry entry, final LogArena arena);
}
