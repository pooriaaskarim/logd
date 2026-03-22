part of '../handler.dart';

/// Abstract base class for outputting logs to a destination.
///
/// Sinks define the final destination of log data, such as the system console,
/// a local file, or a remote network endpoint.
abstract base class LogSink<T> {
  /// Creates a [LogSink].
  ///
  /// If [enabled] is `false`, the [output] method
  /// should not perform any action.
  const LogSink({
    this.enabled = true,
  });

  /// Whether this sink is currently active.
  final bool enabled;

  /// Outputs the [data] to the destination.
  ///
  /// The [entry] is the original log entry that produced this data.
  ///
  /// The [level] indicates the severity of the log entry that produced this
  /// data, which can be used by the sink for destination-specific logic (e.g.,
  /// using different output streams for errors).
  Future<void> output(
    final T data,
    final LogEntry entry,
    final LogLevel level,
  );

  /// Performs cleanup, such as closing file handles or network connections.
  ///
  /// This should be called when the sink is no longer needed.
  Future<void> dispose() async {}
}
