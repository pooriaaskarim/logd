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
  LogDocument format(final LogEntry entry, final LogContext context) =>
      LogDocument(
        nodes: [
          DecoratedNode(
            leadingWidth: 4,
            leadingHint: 'structured_separator',
            children: [_buildHeader(entry, context)],
          ),
          DecoratedNode(
            leadingWidth: 5,
            leadingHint: 'structured_content',
            children: [_buildMessage(entry.message, context)],
          ),
          if (entry.error != null)
            DecoratedNode(
              leadingWidth: 5,
              leadingHint: 'structured_content',
              children: [_buildError(entry.error!)],
            ),
          if (entry.stackFrames != null)
            DecoratedNode(
              leadingWidth: 5,
              leadingHint: 'structured_content',
              children: [_buildStackTrace(entry.stackFrames!, context)],
            ),
        ],
      );

  ContentNode _buildHeader(final LogEntry entry, final LogContext context) {
    // Reserve 4 chars for '____' prefix
    final innerWidth = (context.availableWidth - 4).clamp(1, 1000);

    final segments = <StyledText>[];

    // Line 1: [Logger][Level][Origin]
    final line1Segments = <StyledText>[
      StyledText(
        '[${entry.loggerName}]',
        tags: const {LogTag.header, LogTag.loggerName},
      ),
      StyledText(
        '[${entry.level.name.toUpperCase()}]',
        tags: const {LogTag.header, LogTag.level},
      ),
    ];

    if (metadata.contains(LogMetadata.origin)) {
      line1Segments
        ..add(const StyledText(' ', tags: {LogTag.header}))
        ..add(
          StyledText(
            '[${entry.origin}]',
            tags: const {LogTag.header, LogTag.origin},
          ),
        );
    }

    // Line 2: Timestamp
    final line2Segments = <StyledText>[];
    if (metadata.contains(LogMetadata.timestamp)) {
      line2Segments.add(
        StyledText(
          entry.timestamp,
          tags: const {LogTag.header, LogTag.timestamp},
        ),
      );
    }

    final allLines = [line1Segments, line2Segments];

    for (final lineSegments in allLines) {
      if (lineSegments.isEmpty) {
        continue;
      }

      // Flatten for wrapping
      final flat = lineSegments.map((final s) => (s.text, s)).toList();
      final wrapped = wrapWithData(flat, innerWidth);

      for (final wLine in wrapped) {
        for (final chunk in wLine) {
          segments.add(chunk.$2.copyWith(text: chunk.$1));
        }
        segments.add(const StyledText('\n', tags: {LogTag.header}));
      }
    }

    // Remove trailing newline if present to prevent double spacing
    if (segments.isNotEmpty && segments.last.text == '\n') {
      segments.removeLast();
    }

    return HeaderNode(
      segments: segments,
    );
  }

  MessageNode _buildMessage(final String content, final LogContext context) {
    if (content.isEmpty) {
      return const MessageNode(segments: []);
    }

    // Reserve 5 chars for '----|' prefix
    final innerWidth = (context.availableWidth - 5).clamp(1, 1000);
    final segments = <StyledText>[];

    final explicitLines = content.split('\n');

    for (int i = 0; i < explicitLines.length; i++) {
      final lineContent = explicitLines[i];

      // Wrap this explicit line
      final wrappedLine = wrapWithData(
        [
          (lineContent, const StyledText('', tags: {LogTag.message})),
        ],
        innerWidth,
      ).toList();

      for (int j = 0; j < wrappedLine.length; j++) {
        final wLine = wrappedLine[j];

        for (final chunk in wLine) {
          segments.add(chunk.$2.copyWith(text: chunk.$1));
        }

        // Add newline unless it's the very last line of everything
        if (i < explicitLines.length - 1 || j < wrappedLine.length - 1) {
          segments.add(const StyledText('\n'));
        }
      }
    }

    return MessageNode(segments: segments);
  }

  FooterNode _buildError(final Object error) => FooterNode(
        segments: [
          StyledText('Error: $error', tags: const {LogTag.error}),
        ],
      );

  FooterNode _buildStackTrace(
    final List<CallbackInfo> frames,
    final LogContext context,
  ) {
    // Reserve 5 chars for '----|' prefix
    final innerWidth = (context.availableWidth - 5).clamp(1, 1000);
    final segments = <StyledText>[];

    // Header "Stack Trace:"
    final headerWrap = wrapWithData(
      [
        ('Stack Trace:', const StyledText('', tags: {LogTag.stackFrame})),
      ],
      innerWidth,
    ).toList();

    for (final wLine in headerWrap) {
      for (final chunk in wLine) {
        segments.add(chunk.$2.copyWith(text: chunk.$1));
      }
      segments.add(const StyledText('\n', tags: {LogTag.stackFrame}));
    }

    for (final frame in frames) {
      final text =
          ' at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';
      final wrappedFrame = wrapWithData(
        [
          (text, const StyledText('', tags: {LogTag.stackFrame})),
        ],
        innerWidth,
      ).toList();

      for (final line in wrappedFrame) {
        for (final chunk in line) {
          segments.add(chunk.$2.copyWith(text: chunk.$1));
        }
        segments.add(const StyledText('\n'));
      }
    }

    // Remove trailing newline
    if (segments.isNotEmpty && segments.last.text == '\n') {
      segments.removeLast();
    }

    return FooterNode(
      segments: segments,
    );
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is StructuredFormatter &&
          runtimeType == other.runtimeType &&
          setEquals(metadata, other.metadata);

  @override
  int get hashCode => runtimeType.hashCode;
}
