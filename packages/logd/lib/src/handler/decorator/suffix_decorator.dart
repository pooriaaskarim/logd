part of '../handler.dart';

/// A [LogDecorator] that appends a fixed string to each log line.
@immutable
final class SuffixDecorator extends ContentDecorator {
  /// Creates a [SuffixDecorator] with the given [suffix].
  ///
  /// - [suffix]: The string to append to each line.
  /// - [aligned]: Whether to align the suffix to the end of the available
  /// width. Defaults to true.
  /// - [style]: Optional style for the suffix.
  const SuffixDecorator(
    this.suffix, {
    this.aligned = true,
    this.style,
  });

  /// The suffix string to append.
  final String suffix;

  /// Whether to align the suffix to the right edge.
  final bool aligned;

  /// Optional style for the suffix.
  final LogStyle? style;

  @override
  Iterable<LogLine> decorate(
    final Iterable<LogLine> lines,
    final LogEntry entry,
    final LogContext context,
  ) {
    final suffixSegment =
        LogSegment(suffix, tags: const {LogTag.suffix}, style: style);

    if (!aligned) {
      return lines.map((final l) => LogLine([...l.segments, suffixSegment]));
    }

    return lines.map((final line) {
      final currentLen = line.visibleLength;
      final suffixLen = suffix.visibleLength;

      // We align to the end of the content area.
      // context.contentLimit is the width reserved for content (Fixed or
      // Flowing).
      final targetWidth = context.contentLimit;
      final paddingNeeded =
          (targetWidth - currentLen - suffixLen).clamp(0, 1000);

      return LogLine([
        ...line.segments,
        if (paddingNeeded > 0) LogSegment(' ' * paddingNeeded, tags: const {}),
        suffixSegment,
      ]);
    });
  }

  @override
  int paddingWidth(final LogEntry entry) => suffix.visibleLength;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is SuffixDecorator &&
          runtimeType == other.runtimeType &&
          suffix == other.suffix &&
          style == other.style &&
          aligned == other.aligned;

  @override
  int get hashCode => Object.hash(suffix, aligned, style);
}
