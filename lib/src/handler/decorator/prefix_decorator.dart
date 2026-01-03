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
  ) =>
      lines.map((final l) => LogLine('$prefix${l.text}', tags: l.tags));

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is PrefixDecorator &&
          runtimeType == other.runtimeType &&
          prefix == other.prefix;

  @override
  int get hashCode => prefix.hashCode;
}
