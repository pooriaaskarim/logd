part of '../handler.dart';

/// A [LogFormatter] that produces a semantic [LogDocument] optimized for
/// Markdown output.
///
/// It structures log entries into semantic sections (Header, Message, Error,
/// StackTrace) and marks supplementary information (like stack traces) as
/// [LogTag.collapsible] to allow [MarkdownEncoder] to render them as GFM
/// \<details\> blocks.
@immutable
final class MarkdownFormatter implements LogFormatter {
  /// Creates a [MarkdownFormatter].
  ///
  /// - [metadata]: Contextual metadata to include.
  const MarkdownFormatter({
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

    // 1. Header (Level + Metadata)
    final headerSegments = <StyledText>[
      StyledText(
        '${_levelEmoji(entry.level)} ${entry.level.name.toUpperCase()}',
        tags: LogTag.level,
      ),
    ];

    for (final meta in metadata) {
      final value = meta.getValue(entry);
      if (value.isNotEmpty) {
        headerSegments.add(StyledText(' [$value]', tags: meta.tag));
      }
    }

    nodes
      ..add(HeaderNode(segments: headerSegments))

      // 2. Message
      ..add(
        MessageNode(
          segments: [
            StyledText(entry.message, tags: LogTag.message),
          ],
        ),
      );

    // 3. Error
    if (entry.error != null) {
      nodes.add(
        ErrorNode(
          segments: [StyledText(entry.error.toString())],
        ),
      );
    }

    // 4. Stack Trace (Collapsible)
    if (entry.stackFrames != null && entry.stackFrames!.isNotEmpty) {
      final frameSegments = <StyledText>[];
      for (final frame in entry.stackFrames!) {
        frameSegments.add(
          StyledText(
            'at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})\n',
            tags: LogTag.stackFrame,
          ),
        );
      }
      nodes.add(
        FooterNode(
          segments: frameSegments,
          tags: LogTag.stackFrame | LogTag.collapsible,
        ),
      );
    } else if (entry.stackTrace != null) {
      nodes.add(
        FooterNode(
          segments: [
            StyledText(
              entry.stackTrace.toString(),
              tags: LogTag.stackFrame,
            ),
          ],
          tags: LogTag.stackFrame | LogTag.collapsible,
        ),
      );
    }

    return LogDocument(
      nodes: nodes,
    );
  }

  String _levelEmoji(final LogLevel level) => switch (level) {
        LogLevel.trace => '🧬',
        LogLevel.debug => '🔍',
        LogLevel.info => 'ℹ️',
        LogLevel.warning => '⚠️',
        LogLevel.error => '❌',
      };

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is MarkdownFormatter &&
          runtimeType == other.runtimeType &&
          setEquals(metadata, other.metadata);

  @override
  int get hashCode => runtimeType.hashCode;
}
