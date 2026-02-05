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
    final LogContext context,
  ) {
    // 1. Collect all entry segments (Level, Metadata, Message)
    final segments = <StyledText>[
      StyledText(
        '[${entry.level.name.toUpperCase()}]',
        tags: const {LogTag.level},
      ),
    ];

    for (final meta in metadata) {
      final value = meta.getValue(entry);
      if (value.isNotEmpty) {
        final text = meta != LogMetadata.timestamp ? '[$value]' : value;
        segments
          ..add(const StyledText(' ', tags: {}))
          ..add(StyledText(text, tags: {meta.tag}));
      }
    }

    segments.add(const StyledText(' ', tags: {}));

    // Calculate generic header width so far to offset wrapping
    var headerWidth = 0;
    for (final s in segments) {
      headerWidth += s.text.visibleLength;
    }

    // Wrap the message
    // First line must fit in (availableWidth - headerWidth)
    // Subsequent lines use full availableWidth
    final firstLineWidth =
        (context.availableWidth - headerWidth).clamp(1, 1000);

    final messageSegments = [
      (entry.message, const StyledText('', tags: {LogTag.message})),
    ];
    final wrappedMessage = wrapWithData(
      messageSegments,
      firstLineWidth,
      subsequentWidth: context.availableWidth,
    );

    var firstLine = true;
    for (final line in wrappedMessage) {
      if (!firstLine) {
        segments.add(const StyledText('\n', tags: {}));
      }
      for (final chunk in line) {
        segments.add(
          StyledText(
            chunk.$1,
            tags: const {LogTag.message},
          ),
        );
      }
      firstLine = false;
    }

    // 2. Handle Error if present
    if (entry.error != null) {
      const errorPrefix = 'Error: ';
      final errorContent = entry.error.toString();
      segments
        ..add(const StyledText('\n', tags: {}))
        ..add(
          StyledText(
            errorPrefix + errorContent,
            tags: const {LogTag.error},
          ),
        );
    }

    // 3. Handle Stack Trace if present
    if (entry.stackFrames != null && entry.stackFrames!.isNotEmpty) {
      for (final frame in entry.stackFrames!) {
        final text =
            'at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';

        final wrappedStack = wrapWithData(
          [
            (text, const StyledText('', tags: {LogTag.stackFrame})),
          ],
          context.availableWidth,
        );

        for (final line in wrappedStack) {
          segments.add(const StyledText('\n', tags: {}));
          for (final chunk in line) {
            segments.add(
              StyledText(chunk.$1, tags: const {LogTag.stackFrame}),
            );
          }
        }
      }
    } else if (entry.stackTrace != null) {
      final lines = entry.stackTrace.toString().split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          final wrappedStack = wrapWithData(
            [
              (line, const StyledText('', tags: {LogTag.stackFrame})),
            ],
            context.availableWidth,
          );

          for (final stackLine in wrappedStack) {
            segments.add(const StyledText('\n', tags: {}));
            for (final chunk in stackLine) {
              segments.add(
                StyledText(chunk.$1, tags: const {LogTag.stackFrame}),
              );
            }
          }
        }
      }
    }

    return LogDocument(
      nodes: [
        MessageNode(
          segments: segments,
        ),
      ],
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
