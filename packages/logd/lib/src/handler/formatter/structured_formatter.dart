part of 'formatter.dart';

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
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    // 1. Header (Combined single line)
    final segments = factory.checkoutDataList<StyledText>();

    // Timestamp
    if (metadata.contains(LogMetadata.timestamp)) {
      segments
        ..add(
          StyledText(
            entry.timestamp,
            tags: LogTag.timestamp | LogTag.header,
          ),
        )
        ..add(RenderTokens.styledSpace);
    }

    // Level & Logger
    segments.add(RenderTokens.getLevelToken(entry.level));
    if (metadata.contains(LogMetadata.logger)) {
      segments
        ..add(RenderTokens.styledSpace)
        ..add(RenderTokens.styledOpenBracket)
        ..add(
          StyledText(
            entry.loggerName,
            tags: LogTag.loggerName | LogTag.header,
          ),
        )
        ..add(RenderTokens.styledCloseBracket);
    }

    // Origin
    if (metadata.contains(LogMetadata.origin)) {
      segments
        ..add(RenderTokens.styledSpace)
        ..add(RenderTokens.styledOpenBracket)
        ..add(
          StyledText(
            entry.origin,
            tags: LogTag.origin | LogTag.header,
          ),
        )
        ..add(RenderTokens.styledCloseBracket);
    }

    _writeHeader(document, factory, segments);
    factory.release(segments);

    // 2. Body (----| Message)
    final msgNode = factory.checkoutMessage()
      ..segments.add(StyledText(entry.message));
    final msgPara = factory.checkoutParagraph()..children.add(msgNode);
    final msgDecorated = factory.checkoutDecorated()
      ..leadingWidth = 5
      ..leadingHint = DecorationHint.structuredMessage
      ..leading = (factory.checkoutDataList<StyledText>()
        ..add(RenderTokens.styledMessagePrefix))
      ..children.add(msgPara);
    document.writeNode(msgDecorated);

    // 3. Error
    if (entry.error != null) {
      final errNode = factory.checkoutError()
        ..segments.add(StyledText('Error: ${entry.error}'));
      final errPara = factory.checkoutParagraph()..children.add(errNode);
      final errDecorated = factory.checkoutDecorated()
        ..leadingWidth = 5
        ..leadingHint = DecorationHint.structuredMessage
        ..leading = (factory.checkoutDataList<StyledText>()
          ..add(RenderTokens.styledMessagePrefix))
        ..children.add(errPara);
      document.writeNode(errDecorated);
    }

    // 4. Stack Trace
    if (entry.stackFrames != null && entry.stackFrames!.isNotEmpty) {
      for (final frame in entry.stackFrames!) {
        final text =
            'at ${frame.fullMethod} (${frame.filePath}:${frame.lineNumber})';
        final foot = factory.checkoutFooter()
          ..segments.add(StyledText(text, tags: LogTag.stackFrame));
        final para = factory.checkoutParagraph()..children.add(foot);
        final d = factory.checkoutDecorated()
          ..leadingWidth = 5
          ..leadingHint = DecorationHint.structuredMessage
          ..leading = (factory.checkoutDataList<StyledText>()
            ..add(RenderTokens.styledMessagePrefix))
          ..children.add(para);
        document.writeNode(d);
      }
    } else if (entry.stackTrace != null) {
      final rawLines = entry.stackTrace.toString().split('\n');
      for (final raw in rawLines) {
        if (raw.trim().isEmpty) {
          continue;
        }
        final foot = factory.checkoutFooter()
          ..segments.add(StyledText(raw, tags: LogTag.stackFrame));
        final para = factory.checkoutParagraph()..children.add(foot);
        final d = factory.checkoutDecorated()
          ..leadingWidth = 5
          ..leadingHint = DecorationHint.structuredMessage
          ..leading = (factory.checkoutDataList<StyledText>()
            ..add(const StyledText('----|', tags: LogTag.header)))
          ..children.add(para);
        document.writeNode(d);
      }
    }
  }

  void _writeHeader(
    final LogDocument document,
    final LogPipelineFactory factory,
    final List<StyledText> segments,
  ) {
    document.startDecorated(
      leading: (factory.checkoutDataList<StyledText>()
        ..add(RenderTokens.styledHeaderPrefix)),
      leadingWidth: 4,
      leadingHint: DecorationHint.structuredHeader,
    );
    final header = factory.checkoutHeader()..segments.addAll(segments);
    final filler = factory.checkoutFiller()
      ..char = '_'
      ..tags = LogTag.header;
    final row = factory.checkoutRow()
      ..children.add(header)
      ..children.add(filler);
    document
      ..writeNode(row)
      ..endDecorated();
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
