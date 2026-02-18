part of '../handler.dart';

/// A lightweight formatter that outputs log entries as simple, readable text.
///
/// It strictly includes crucial log content (level, message, error, stackTrace)
/// and allows customization of contextual [metadata] (timestamp, logger,
/// origin).
@immutable
final class PlainFormatter implements LogFormatter {
  /// Creates a [PlainFormatter].
  ///
  /// - [metadata]: Contextual metadata to include.
  ///   Crucial fields (level, message, etc.) are always included.
  const PlainFormatter({
    this.metadata = const {
      LogMetadata.timestamp,
      LogMetadata.logger,
    },
  });

  /// The contextual metadata to include in the output.
  @override
  final Set<LogMetadata> metadata;

  @override
  Iterable<LogLine> format(
    final LogEntry entry,
    final LogContext context,
  ) sync* {
    final width = context.availableWidth;

    // 1. Collect all entry segments (Level, Metadata, Message)
    final parts = <(String text, LogTag? tag)>[
      ('[${entry.level.name.toUpperCase()}]', LogTag.level),
    ];

    for (final meta in metadata) {
      final value = meta.getValue(entry);
      if (value.isNotEmpty) {
        final text = meta != LogMetadata.timestamp ? '[$value]' : value;
        parts
          ..add((' ', null))
          ..add((text, meta.tag));
      }
    }

    parts
      ..add((' ', null))
      ..add((entry.message, LogTag.message));

    // 2. Emit the entry flow
    yield* _wrapFlow(parts, width);

    // 3. Handle Error if present
    if (entry.error != null) {
      const errorPrefix = 'Error: ';
      final errorContent = entry.error.toString();
      yield* _wrapFlow(
        [(errorPrefix + errorContent, LogTag.error)],
        width,
      );
    }

    // 4. Handle Stack Trace if present
    if (entry.stackFrames != null && entry.stackFrames!.isNotEmpty) {
      for (final frame in entry.stackFrames!) {
        final text =
            'at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';
        yield* _wrapFlow([(text, LogTag.stackFrame)], width);
      }
    } else if (entry.stackTrace != null) {
      final lines = entry.stackTrace.toString().split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          yield* _wrapFlow([(line, LogTag.stackFrame)], width);
        }
      }
    }
  }

  Iterable<LogLine> _wrapFlow(
    final List<(String text, LogTag? tag)> parts,
    final int width,
  ) sync* {
    final line = LogLine(
      parts
          .map((final p) => LogSegment(p.$1, tags: {if (p.$2 != null) p.$2!}))
          .toList(),
    );

    yield* line.wrap(width);
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is PlainFormatter &&
          runtimeType == other.runtimeType &&
          setEquals(metadata, other.metadata);

  @override
  int get hashCode => runtimeType.hashCode;
}
