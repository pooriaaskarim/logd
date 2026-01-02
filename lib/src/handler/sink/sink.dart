part of '../handler.dart';

/// Abstract base class for outputting formatted log lines to a destination.
///
/// Sinks define the final destination of log data, such as the system console,
/// a local file, or a remote network endpoint.
abstract base class LogSink {
  /// Creates a [LogSink].
  ///
  /// If [enabled] is `false`, the [output] method
  /// should not perform any action.
  const LogSink({
    this.enabled = true,
  });

  /// Whether this sink is currently active.
  final bool enabled;

  /// Outputs the [lines] to the destination.
  ///
  /// The [level] indicates the severity of the log entry that produced these
  /// lines, which can be used by the sink for destination-specific logic (e.g.,
  /// using different output streams for errors).
  Future<void> output(
    final Iterable<String> lines,
    final LogLevel level,
  );
}
