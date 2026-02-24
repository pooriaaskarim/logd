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
  LogDocument format(
    final LogEntry entry,
    final LogArena arena,
  ) {
    final doc = arena.checkoutDocument();

    // 1. Header Flow (Level + Metadata)
    final headerSegments = <StyledText>[
      StyledText(
        '[${entry.level.name.toUpperCase()}]',
        tags: LogTag.level,
      ),
    ];

    for (final meta in metadata) {
      final value = meta.getValue(entry);
      if (value.isNotEmpty) {
        final text = meta != LogMetadata.timestamp ? ' [$value]' : ' $value';
        headerSegments.add(StyledText(text, tags: meta.tag));
      }
    }

    // Add spacer between header and message
    headerSegments.add(const StyledText(' ', tags: LogTag.none));

    final headerWidth = headerSegments.fold<int>(
      0,
      (final p, final s) => p + s.text.characters.length,
    );

    final msgNode = arena.checkoutMessage()
      ..segments.add(StyledText(entry.message, tags: LogTag.message));
    final decorated = arena.checkoutDecorated()
      ..leading = headerSegments
      ..leadingWidth = headerWidth
      ..repeatLeading = false
      ..alignTrailing = false
      ..children.add(msgNode);
    doc.nodes.add(decorated);

    // 2. Handle Error if present
    if (entry.error != null) {
      final errNode = arena.checkoutError()
        ..segments.add(StyledText('Error: ${entry.error}'));
      final para = arena.checkoutParagraph()..children.add(errNode);
      doc.nodes.add(para);
    }

    // 3. Handle Stack Trace if present
    if (entry.stackFrames != null && entry.stackFrames!.isNotEmpty) {
      for (final frame in entry.stackFrames!) {
        final text =
            'at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';
        final foot = arena.checkoutFooter()
          ..segments.add(StyledText(text, tags: LogTag.stackFrame));
        final para = arena.checkoutParagraph()..children.add(foot);
        doc.nodes.add(para);
      }
    } else if (entry.stackTrace != null) {
      final traceLines = entry.stackTrace.toString().split('\n');
      for (final line in traceLines) {
        if (line.trim().isNotEmpty) {
          final foot = arena.checkoutFooter()
            ..segments.add(StyledText(line, tags: LogTag.stackFrame));
          final para = arena.checkoutParagraph()..children.add(foot);
          doc.nodes.add(para);
        }
      }
    }

    return doc;
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
