import 'dart:io' as io;
import 'package:logd/logd.dart';

/// The ultimate showcase for Logd Handler module.
///
/// Demonstrates the full power of:
/// - Multiple backends (Console, HTML, Markdown, JSON Semantic)
/// - Fine-grained coloring and structural decoration
/// - Hierarchical context and indention
/// - Error handling and stack trace formatting
void main() async {
  print('🎭 LOGD THEATRE: Final Showcase 🎭');
  print('===================================\n');

  const basePath = 'logs/showcase';

  // Ensure directories exist
  _prepareDirectories(basePath);

  // 1. Setup the Multi-Backend Theatre
  final consoleHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const StyleDecorator(
        theme: _HeaderBackgroundTheme(),
      ),
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
      ),
    ],
    sink: const ConsoleSink(),
    lineLength: 80,
  );

  final htmlSink =
      HTMLSink(filePath: '$basePath/dashboard.html', darkMode: true);
  final htmlHandler = Handler(
    formatter: const HTMLFormatter(),
    sink: htmlSink,
  );

  final markdownHandler = Handler(
    formatter: const MarkdownFormatter(headingLevel: 2),
    sink: FileSink('$basePath/report.md'),
  );

  final semanticHandler = Handler(
    formatter: const JsonPrettyFormatter(),
    sink: FileSink('$basePath/telemetry.json'),
  );

  final toonHandler = Handler(
    formatter: ToonFormatter(),
    sink: FileSink('$basePath/llm_context.toon'),
  );

  // Configure everything
  Logger.configure(
    'theatre',
    handlers: [
      consoleHandler,
      htmlHandler,
      markdownHandler,
      semanticHandler,
      toonHandler,
    ],
    logLevel: LogLevel.trace,
  );

  final logger = Logger.get('theatre');
  final netLogger = Logger.get('theatre.network');
  final dbLogger = Logger.get('theatre.database');

  // Scene 1: System Startup
  print('🎬 Scene 1: System Startup');
  logger.info('Initializing Logd Theatre Core...');
  logger.debug('Loading theater scenes from assets/scripts/v1.json');

  // Scene 2: Network Activity
  print('\n🎬 Scene 2: Network Activity');
  netLogger.info('Connecting to Global Backend Service...');
  netLogger.trace('GET /api/v1/auth/tokens - 200 OK (45ms)');
  netLogger.warning('High latency detected in us-east region: 450ms');

  // Scene 3: The Incident
  print('\n🎬 Scene 3: The Incident');
  dbLogger.info('Synchronizing actor database...');
  try {
    _performInvalidDatabaseOperation();
  } catch (e, s) {
    dbLogger.error('Critical database corruption detected!',
        error: e, stackTrace: s);
  }

  // Scene 4: Multi-line Telemetry
  print('\n🎬 Scene 4: Multi-line Telemetry');
  final buffer = logger.infoBuffer;
  buffer?.writeln('Production Report:');
  buffer?.writeln('  📊 CPU Usage: 42%');
  buffer?.writeln('  🌡️ Temperature: 68°C');
  buffer?.writeln('  💾 Available Memory: 12.4 GB');
  buffer?.sink();

  // Scene 5: Hierarchy Isolation
  print('\n🎬 Scene 5: Hierarchy Isolation');
  final subLogger = Logger.get('theatre.sub.deep');
  subLogger.info('This prefix should not be colored even if level is colored.');

  // Scene 6: Closing down
  print('\n🎬 Scene 6: Curtain Call');
  logger.info('Theatre closing... Writing all logs.');

  // Give some time for async loggers to finish
  await Future.delayed(const Duration(milliseconds: 500));

  // Finalize sinks
  await htmlSink.close();

  print('\n✅ Showcase Complete!');
  print('-----------------------------------------');
  print('Check the following files for results:');
  print('  🖥️  Terminal: Structured & Boxed output');
  print('  🌐  HTML Dashboard: $basePath/dashboard.html');
  print('  📝  Markdown Report: $basePath/report.md');
  print('  🧬  JSON Telemetry: $basePath/telemetry.json');
  print('  🤖  LLM Context:    $basePath/llm_context.toon');
  print('-----------------------------------------');
}

void _prepareDirectories(String path) {
  final dir = io.Directory(path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
}

void _performInvalidDatabaseOperation() {
  throw io.FileSystemException('Permission denied', '/var/db/actors.db');
}

class _HeaderBackgroundTheme extends LogTheme {
  const _HeaderBackgroundTheme()
      : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    var style = super.getStyle(level, tags);
    if (tags.contains(LogTag.header)) {
      style = LogStyle(
        color: style.color,
        bold: style.bold,
        dim: style.dim,
        inverse: true, // Force inverse
      );
    }
    return style;
  }
}
