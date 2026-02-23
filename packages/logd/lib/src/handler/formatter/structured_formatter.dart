part of '../handler.dart';

/// A [LogFormatter] that formats log entries in a structured layout.
///
/// This formatter provides detailed output by organizing the log message
/// and its metadata (timestamp, level, origin) in a structured format with
/// clear visual separators. It supports auto-wrapping for long content.
///
/// Uses fine-grained semantic tags ([LogTag.timestamp], [LogTag.level],
/// [LogTag.loggerName]) within headers to enable tag-specific color overrides.
@immutable
final class StructuredFormatter implements LogFormatter {
  const StructuredFormatter({
    this.metadata = const {
      LogMetadata.origin,
      LogMetadata.timestamp,
      LogMetadata.logger,
    },
  });

  @override
  final Set<LogMetadata> metadata;
  @override
  LogDocument format(
    final LogEntry entry,
  ) {
    final nodes = <LogNode>[];

    // 1. Phased Header (Legacy 1.0 Style: 3 separate lines)

    // Phase 1: Timestamp
    if (metadata.contains(LogMetadata.timestamp)) {
      nodes.add(
        _buildHeaderNode([
          StyledText(
            entry.timestamp,
            tags: LogTag.timestamp | LogTag.header,
          ),
        ]),
      );
    }

    // Phase 2: Level & Logger
    final levelLoggerSegments = [
      StyledText(
        '[${entry.level.name.toUpperCase()}]',
        tags: LogTag.level | LogTag.header,
      ),
    ];
    if (metadata.contains(LogMetadata.logger)) {
      levelLoggerSegments
        ..add(const StyledText(' ', tags: LogTag.header))
        ..add(
          StyledText(
            '[${entry.loggerName}]',
            tags: LogTag.loggerName | LogTag.header,
          ),
        );
    }
    nodes.add(_buildHeaderNode(levelLoggerSegments));

    // Phase 3: Origin
    if (metadata.contains(LogMetadata.origin)) {
      nodes.add(
        _buildHeaderNode([
          StyledText(
            '[${entry.origin}]',
            tags: LogTag.origin | LogTag.header,
          ),
        ]),
      );
    }

    // 2. Body (----| Message)
    nodes.add(
      DecoratedNode(
        leadingWidth: 5,
        leadingHint: DecorationHint.structuredMessage,
        leading: const [
          StyledText('----|', tags: LogTag.header),
        ],
        children: [
          ParagraphNode(
            children: [
              MessageNode(segments: [StyledText(entry.message)]),
            ],
          ),
        ],
      ),
    );

    // 3. Error
    if (entry.error != null) {
      nodes.add(
        DecoratedNode(
          leadingWidth: 5,
          leadingHint: DecorationHint.structuredMessage,
          leading: const [
            StyledText('----|', tags: LogTag.header),
          ],
          children: [
            ParagraphNode(
              children: [
                ErrorNode(segments: [StyledText('Error: ${entry.error}')]),
              ],
            ),
          ],
        ),
      );
    }

    // 4. Stack Trace
    if (entry.stackFrames != null && entry.stackFrames!.isNotEmpty) {
      for (final frame in entry.stackFrames!) {
        final text =
            'at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';
        nodes.add(
          DecoratedNode(
            leadingWidth: 5,
            leadingHint: DecorationHint.structuredMessage,
            leading: const [
              StyledText('----|', tags: LogTag.header),
            ],
            children: [
              ParagraphNode(
                children: [
                  FooterNode(
                    segments: [
                      StyledText(text, tags: LogTag.stackFrame),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }
    } else if (entry.stackTrace != null) {
      final rawLines = entry.stackTrace.toString().split('\n');
      for (final raw in rawLines) {
        if (raw.trim().isEmpty) {
          continue;
        }
        nodes.add(
          DecoratedNode(
            leadingWidth: 5,
            leadingHint: DecorationHint.structuredMessage,
            leading: const [
              StyledText('----|', tags: LogTag.header),
            ],
            children: [
              ParagraphNode(
                children: [
                  FooterNode(
                    segments: [
                      StyledText(raw, tags: LogTag.stackFrame),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }

    return LogDocument(
      nodes: nodes,
    );
  }

  LogNode _buildHeaderNode(final List<StyledText> segments) => DecoratedNode(
        leadingWidth: 4,
        leadingHint: DecorationHint.structuredHeader,
        leading: const [
          StyledText('____', tags: LogTag.header),
        ],
        children: [
          RowNode(
            children: [
              HeaderNode(segments: segments),
              const FillerNode('_', tags: LogTag.header),
            ],
          ),
        ],
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is StructuredFormatter &&
          runtimeType == other.runtimeType &&
          setEquals(metadata, other.metadata);

  @override
  int get hashCode => runtimeType.hashCode;
}
