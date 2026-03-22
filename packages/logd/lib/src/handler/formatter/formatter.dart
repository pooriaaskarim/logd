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

  /// Formats [entry] into the provided [document], using [factory] to check out
  /// new nodes.
  ///
  /// The [document] and all nodes created by the [factory] are pool-managed.
  /// The orchestrator is responsible for releasing the document after the
  /// pipeline completes.
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogNodeFactory factory,
  );
}
