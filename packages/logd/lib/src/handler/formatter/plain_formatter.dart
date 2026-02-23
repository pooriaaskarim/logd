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
  ) {
    final nodes = <LogNode>[];

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

    nodes.add(
      DecoratedNode(
        leading: headerSegments,
        leadingWidth: headerWidth,
        repeatLeading: false,
        alignTrailing: false,
        children: [
          MessageNode(
            segments: [
              StyledText(entry.message, tags: LogTag.message),
            ],
          ),
        ],
      ),
    );

    // 2. Handle Error if present
    if (entry.error != null) {
      nodes.add(
        ParagraphNode(
          children: [
            ErrorNode(
              segments: [StyledText('Error: ${entry.error}')],
            ),
          ],
        ),
      );
    }

    // 3. Handle Stack Trace if present
    if (entry.stackFrames != null && entry.stackFrames!.isNotEmpty) {
      for (final frame in entry.stackFrames!) {
        final text =
            'at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';
        nodes.add(
          ParagraphNode(
            children: [
              FooterNode(
                segments: [
                  StyledText(text, tags: LogTag.stackFrame),
                ],
              ),
            ],
          ),
        );
      }
    } else if (entry.stackTrace != null) {
      final traceLines = entry.stackTrace.toString().split('\n');
      for (final line in traceLines) {
        if (line.trim().isNotEmpty) {
          nodes.add(
            ParagraphNode(
              children: [
                FooterNode(
                  segments: [
                    StyledText(line, tags: LogTag.stackFrame),
                  ],
                ),
              ],
            ),
          );
        }
      }
    }

    return LogDocument(
      nodes: nodes,
    );
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
