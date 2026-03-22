import 'dart:io';
import 'package:logd/logd.dart';

void main() async {
  print(
      '╔═════════════════════════════════════════════════════════════════════╗');
  print(
      '║                      LOGD: HTML SHOWCASE GALLERY                    ║');
  print(
      '╚═════════════════════════════════════════════════════════════════════╝\n');

  final outputDir = Directory('logs/html');
  if (outputDir.existsSync()) {
    outputDir.deleteSync(recursive: true);
  }
  outputDir.createSync(recursive: true);

  print('Generating HTML logs in: ${outputDir.path}\n');

  // ===========================================================================
  // 1. MINIMAL LIGHT (Plain + No Decorators + Light Mode)
  // ===========================================================================
  final minimalHandler = Handler(
    formatter: const PlainFormatter(),
    sink: FileSink(
      '${outputDir.path}/1_minimal_light.html',
      encoder: const HtmlEncoder(darkMode: false, title: 'Minimal Light Logs'),
      strategy: WrappingStrategy.document,
    ),
  );

  Logger.configure('minimal',
      logLevel: LogLevel.trace, handlers: [minimalHandler]);
  final minimalLog = Logger.get('minimal.root');
  _logAllLevels(minimalLog, 'Minimal Light Showcase');

  // ===========================================================================
  // 2. DARK ARCHITECT (Structured + StyleDecorator + StackTrace)
  // ===========================================================================
  final darkHandler = Handler(
    formatter: const StructuredFormatter(
      metadata: {LogMetadata.timestamp, LogMetadata.logger, LogMetadata.origin},
    ),
    decorators: [
      const StyleDecorator(
        theme: LogTheme(colorScheme: LogColorScheme.darkScheme),
      ),
    ],
    sink: FileSink(
      '${outputDir.path}/2_dark_architect.html',
      encoder: const HtmlEncoder(darkMode: true, title: 'Dark Architect Logs'),
      strategy: WrappingStrategy.document,
    ),
  );

  Logger.configure('dark', logLevel: LogLevel.trace, handlers: [darkHandler]);
  final darkLog = Logger.get('dark.system.kernel');
  _logAllLevels(darkLog, 'Dark Architect Showcase');
  darkLog.error('Kernel Panic!',
      error: 'Fatal memory corruption', stackTrace: StackTrace.current);

  // ===========================================================================
  // 3. JSON INSPECTOR (JsonPretty + Box + color:true)
  // ===========================================================================
  final jsonInspectorHandler = Handler(
    formatter: const JsonPrettyFormatter(
      metadata: {LogMetadata.timestamp},
      color: true,
    ),
    decorators: [
      const StyleDecorator(),
      const BoxDecorator(borderStyle: BoxBorderStyle.rounded),
    ],
    sink: FileSink(
      '${outputDir.path}/3_json_inspector.html',
      encoder: const HtmlEncoder(darkMode: true, title: 'JSON Inspector'),
      strategy: WrappingStrategy.document,
    ),
  );

  Logger.configure('json_pretty',
      logLevel: LogLevel.trace, handlers: [jsonInspectorHandler]);
  final jsonLog = Logger.get('json_pretty.orders');
  jsonLog.info('Order Processed', error: {
    'id': 'ord_882',
    'status': 'verified',
    'items': [
      {'sku': 'apple_01', 'qty': 5},
      {'sku': 'pear_02', 'qty': 2}
    ],
    'meta': {'latency': '45ms', 'server': 'us-east-1'}
  });

  // ===========================================================================
  // 4. JSON COMPACT (JsonFormatter + Simple strategy)
  // ===========================================================================
  final jsonCompactHandler = Handler(
    formatter: const JsonFormatter(
      metadata: {LogMetadata.timestamp},
    ),
    sink: FileSink(
      '${outputDir.path}/4_json_compact.html',
      encoder: const HtmlEncoder(darkMode: true, title: 'Compact JSON'),
      strategy: WrappingStrategy.document,
    ),
  );

  Logger.configure('json_compact',
      logLevel: LogLevel.trace, handlers: [jsonCompactHandler]);
  final compactLog = Logger.get('json_compact.db.query');
  compactLog.debug('SELECT * FROM users', error: {
    'id': 123,
    'fields': ['name', 'email']
  });

  // ===========================================================================
  // 5. TOON STREAM (ToonPretty + Suffix + Hierarchy)
  // ===========================================================================
  final toonHandler = Handler(
    formatter: const ToonPrettyFormatter(),
    decorators: [
      const StyleDecorator(),
      const SuffixDecorator(
        ' [NODE_99] ',
        style: LogStyle(color: LogColor.green, italic: true),
      ),
      const HierarchyDepthPrefixDecorator(indent: '  │ '),
    ],
    sink: FileSink(
      '${outputDir.path}/5_toon_stream.html',
      encoder:
          const HtmlEncoder(darkMode: true, title: 'Toon Stream Telemetry'),
      strategy: WrappingStrategy.document,
    ),
  );

  Logger.configure('toon', logLevel: LogLevel.trace, handlers: [toonHandler]);
  final toonLog = Logger.get('toon.telemetry');
  _logAllLevels(toonLog, 'Toon Telemetry Data');
  toonLog.warning('Voltage fluctuation',
      error: ['sensor_01: low', 'sensor_02: critical']);

  // ===========================================================================
  // 6. FULL STACK (Maximum Composition)
  // ===========================================================================
  final fullHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const StyleDecorator(theme: _CustomGalleryTheme()),
      const PrefixDecorator(
        ' [LOGD] ',
        style: LogStyle(
            backgroundColor: LogColor.blue, color: LogColor.white, bold: true),
      ),
      const BoxDecorator(borderStyle: BoxBorderStyle.double),
      const SuffixDecorator(
        ' (verified) ',
        style: LogStyle(color: LogColor.green, italic: true),
      ),
      const HierarchyDepthPrefixDecorator(),
    ],
    sink: FileSink(
      '${outputDir.path}/6_full_stack.html',
      encoder: const HtmlEncoder(darkMode: true, title: 'Full Stack Showcase'),
      strategy: WrappingStrategy.document,
    ),
  );

  Logger.configure('full', logLevel: LogLevel.trace, handlers: [fullHandler]);
  final fullLog = Logger.get('full.auth');
  _logAllLevels(fullLog, 'Full Stack Experience');
  fullLog.error('Auth failure',
      error: {'user_id': 101, 'reason': 'token_expired'},
      stackTrace: StackTrace.current);

  print('Finalizing logs and closing sinks...');
  final allHandlers = [
    ...minimalLog.handlers,
    ...darkLog.handlers,
    ...jsonLog.handlers,
    ...compactLog.handlers,
    ...toonLog.handlers,
    ...fullLog.handlers,
  ];

  for (final handler in allHandlers) {
    await handler.sink.dispose();
  }

  print('\nSuccess! Open the following files in your browser:');
  for (final file in outputDir.listSync()) {
    if (file is File && file.path.endsWith('.html')) {
      print(' - ${file.path}');
    }
  }
}

void _logAllLevels(final Logger logger, final String message) {
  logger.trace('$message (TRACE)');
  logger.debug('$message (DEBUG)');
  logger.info('$message (INFO)');
  logger.warning('$message (WARNING)');
  logger.error('$message (ERROR)');
}

class _CustomGalleryTheme extends LogTheme {
  const _CustomGalleryTheme() : super(colorScheme: LogColorScheme.darkScheme);

  @override
  LogStyle getStyle(final LogLevel level, final int tags) {
    if (((tags & LogTag.level) != 0)) {
      return switch (level) {
        LogLevel.error =>
          const LogStyle(color: LogColor.red, bold: true, underline: true),
        LogLevel.warning =>
          const LogStyle(color: LogColor.yellow, bold: true, italic: true),
        _ => super.getStyle(level, tags),
      };
    }
    if (((tags & LogTag.loggerName) != 0)) {
      return const LogStyle(color: LogColor.cyan, italic: true);
    }
    return super.getStyle(level, tags);
  }
}
