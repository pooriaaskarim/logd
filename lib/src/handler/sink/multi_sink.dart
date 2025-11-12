part of '../handler.dart';

/// A special [LogSink] to output to multiple [LogSink]s.
class MultiSink implements LogSink {
  MultiSink(
    this.sinks, {
    this.enabled = true,
  })  : assert(sinks.isNotEmpty, 'Provide at least on Sink'),
        assert(
          !sinks.any((final sink) => sink is MultiSink),
          'Recursive MultiSink is not allowed.',
        );

  @override
  final bool enabled;

  /// List of child sinks to output to.
  ///
  /// **NOTE**:A recursion of [MultiSink]s is not allowed!
  final List<LogSink> sinks;

  @override
  Future<void> output(final List<String> lines, final LogLevel level) async {
    if (lines.isNotEmpty) {
      await Future.wait(sinks.map((final sink) => sink.output(lines, level)));
    }
  }
}
