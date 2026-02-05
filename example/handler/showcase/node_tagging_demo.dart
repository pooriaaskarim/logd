import 'package:logd/logd.dart';

void main() {
  // 1. Setup a standard handler with a LogTheme
  // The Handler now centralizes style resolution using its themeResolver.
  final handler = Handler(
    formatter: const StructuredFormatter(),
    sink: const ConsoleSink(
      theme: LogTheme(
        colorScheme: LogColorScheme.darkScheme,
        // Custom style for anything tagged 'error'
        errorStyle: LogStyle(color: LogColor.brightRed, bold: true),
      ),
    ),
  );

  final entry = LogEntry(
    loggerName: 'demo.tags',
    origin: 'main',
    level: LogLevel.info,
    message: 'Node Tagging Showcase',
    timestamp: '2024-05-10 10:00:00',
  );

  final context = LogContext(
    availableWidth: 80,
    totalWidth: 80,
    contentLimit: 80,
  );

  print('--- Semantic Node Tagging Demo ---');
  print('');

  // Example 1: A BoxNode with 'error' tag
  // In previous versions, we needed a specialized ErrorBoxNode.
  // Now, we just use a generic BoxNode and tag it.
  final errorBox = BoxNode(
    title: 'SEMANTIC ERROR BOX',
    tags: {LogTag.error}, // This tag triggers the errorStyle in LogTheme
    children: [
      const MessageNode(segments: [
        StyledText(
            'Something went wrong, but the box knows how to style itself.'),
      ]),
    ],
  );

  final doc1 = LogDocument(nodes: [errorBox]);
  _printDocument(handler, doc1, entry, context);

  print('');

  // Example 2: Normal BoxNode (no special tags)
  final normalBox = BoxNode(
    title: 'NORMAL BOX',
    children: [
      const MessageNode(segments: [
        StyledText(
            'This box inherits the default level color (blue for info).'),
      ]),
    ],
  );

  final doc2 = LogDocument(nodes: [normalBox]);
  _printDocument(handler, doc2, entry, context);

  print('');
}

void _printDocument(
  Handler handler,
  LogDocument doc,
  LogEntry entry,
  LogContext context,
) {
  // Apply decorators (like StyleDecorator)
  LogDocument finalDoc = doc;
  for (final decorator in handler.decorators) {
    finalDoc = decorator.decorate(finalDoc, entry, context);
  }

  // Encode and print
  const encoder = AnsiEncoder();
  print(encoder.encode(finalDoc, entry.level));
}
