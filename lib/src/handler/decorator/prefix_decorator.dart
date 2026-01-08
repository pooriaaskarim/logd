part of '../handler.dart';

/// A [LogDecorator] that prepends a fixed string to each log line.
@immutable
final class PrefixDecorator extends TransformDecorator {
  /// Creates a [PrefixDecorator] with the given [prefix].
  const PrefixDecorator(this.prefix);

  /// The prefix to prepend.
  final String prefix;

  @override
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
    final LogContext context,
  ) {
    final prefixSegment = LogSegment(prefix, tags: {LogTag.header});
    return lines.map((final l) => LogLine([prefixSegment, ...l.segments]));
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is PrefixDecorator &&
          runtimeType == other.runtimeType &&
          prefix == other.prefix;

  @override
  int get hashCode => prefix.hashCode;
}
