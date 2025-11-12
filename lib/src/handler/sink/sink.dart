part of '../handler.dart';

/// Abstract base for outputting formatted log lines to a destination.
///
/// Handles where lines are outputted (console, file, network).
//todo: Async needed.
abstract class LogSink {
  const LogSink({
    this.enabled = true,
  });

  /// Whether this sink is enabled (if false, output is skipped).
  final bool enabled;

  /// Output the lines to the destination.
  Future<void> output(
    final List<String> lines,
    final LogLevel level,
  );
}
