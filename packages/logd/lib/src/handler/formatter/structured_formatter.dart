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
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogNodeFactory factory,
  ) {
    // 1. Phased Header (Legacy 1.0 Style: 3 separate lines)

    // Phase 1: Timestamp
    if (metadata.contains(LogMetadata.timestamp)) {
      document.nodes.add(
        _buildHeaderNode(factory, [
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
    document.nodes.add(_buildHeaderNode(factory, levelLoggerSegments));

    // Phase 3: Origin
    if (metadata.contains(LogMetadata.origin)) {
      document.nodes.add(
        _buildHeaderNode(factory, [
          StyledText(
            '[${entry.origin}]',
            tags: LogTag.origin | LogTag.header,
          ),
        ]),
      );
    }

    // 2. Body (----| Message)
    final msgNode = factory.checkoutMessage()
      ..segments.add(StyledText(entry.message));
    final msgPara = factory.checkoutParagraph()..children.add(msgNode);
    final msgDecorated = factory.checkoutDecorated()
      ..leadingWidth = 5
      ..leadingHint = DecorationHint.structuredMessage
      ..leading = const [StyledText('----|', tags: LogTag.header)]
      ..children.add(msgPara);
    document.nodes.add(msgDecorated);

    // 3. Error
    if (entry.error != null) {
      final errNode = factory.checkoutError()
        ..segments.add(StyledText('Error: ${entry.error}'));
      final errPara = factory.checkoutParagraph()..children.add(errNode);
      final errDecorated = factory.checkoutDecorated()
        ..leadingWidth = 5
        ..leadingHint = DecorationHint.structuredMessage
        ..leading = const [StyledText('----|', tags: LogTag.header)]
        ..children.add(errPara);
      document.nodes.add(errDecorated);
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
          ..leading = const [StyledText('----|', tags: LogTag.header)]
          ..children.add(para);
        document.nodes.add(d);
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
          ..leading = const [StyledText('----|', tags: LogTag.header)]
          ..children.add(para);
        document.nodes.add(d);
      }
    }
  }

  LogNode _buildHeaderNode(
    final LogNodeFactory factory,
    final List<StyledText> segments,
  ) {
    final header = factory.checkoutHeader()..segments.addAll(segments);
    final filler = factory.checkoutFiller()
      ..char = '_'
      ..tags = LogTag.header;
    final row = factory.checkoutRow()
      ..children.add(header)
      ..children.add(filler);
    return factory.checkoutDecorated()
      ..leadingWidth = 4
      ..leadingHint = DecorationHint.structuredHeader
      ..leading = const [StyledText('____', tags: LogTag.header)]
      ..children.add(row);
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
