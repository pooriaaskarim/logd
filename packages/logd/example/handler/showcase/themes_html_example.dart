import 'dart:io';

import 'package:logd/logd.dart';

/// Showcase example generating native `logd` HTML documents across all themes.
///
/// Run this example in your terminal:
/// ```powershell
/// dart run example/handler/showcase/themes_html_example.dart
/// ```
///
/// Output:
/// Generates self-contained, fully styled `logd` HTML log files in `logs/html/`:
/// - `logs/html/1_dark_theme.html` (LogTheme.dark)
/// - `logs/html/2_light_theme.html` (LogTheme.light)
/// - `logs/html/3_pastel_theme.html` (LogColorScheme.pastelScheme)
/// - `logs/html/4_custom_theme.html` (Tailored LogTheme overrides)
void main() async {
  print(
      '╔═════════════════════════════════════════════════════════════════════╗');
  print(
      '║                 LOGD: HTML THEMES GALLERY SHOWCASE                  ║');
  print(
      '╚═════════════════════════════════════════════════════════════════════╝\n');

  final logsDir = Directory('logs/html');
  if (!logsDir.existsSync()) {
    logsDir.createSync(recursive: true);
  }

  print('Generating native HTML log documents in: ${logsDir.path}\n');

  await _generateDarkHtml(logsDir.path);
  await _generateLightHtml(logsDir.path);
  await _generatePastelHtml(logsDir.path);
  await _generateCustomHtml(logsDir.path);
  await _runRealtimeHtmlDashboard();

  print('✔ All HTML themes generated successfully in: ${logsDir.path}');
}

/// 1. Dark Theme HTML Document
Future<void> _generateDarkHtml(final String dir) async {
  final fileSink = FileSink(
    '$dir/1_dark_theme.html',
    encoder: const HtmlEncoder(
      title: 'logd — Dark Theme Showcase',
    ),
  );

  final handler = Handler(
    formatter: const StructuredFormatter(),
    decorators: const [StyleDecorator(DarkTheme()), BoxDecorator()],
    sink: fileSink,
  );

  Logger.configure('html.dark', logLevel: LogLevel.trace, handlers: [handler]);
  final logger = Logger.get('html.dark.service');
  _logSampleEntries(logger, 'Dark Theme HTML');
  await Future.delayed(const Duration(milliseconds: 300));
  await fileSink.dispose();
  print('  ✔ Created $dir/1_dark_theme.html');
}

/// 2. Light Theme HTML Document
Future<void> _generateLightHtml(final String dir) async {
  final fileSink = FileSink(
    '$dir/2_light_theme.html',
    encoder: const HtmlEncoder(
      title: 'logd — Light Theme Showcase',
    ),
  );

  final handler = Handler(
    formatter: const StructuredFormatter(),
    decorators: const [StyleDecorator(LightTheme()), BoxDecorator()],
    sink: fileSink,
  );

  Logger.configure('html.light', logLevel: LogLevel.trace, handlers: [handler]);
  final logger = Logger.get('html.light.service');
  _logSampleEntries(logger, 'Light Theme HTML');
  await Future.delayed(const Duration(milliseconds: 300));
  await fileSink.dispose();
  print('  ✔ Created $dir/2_light_theme.html');
}

/// 3. Pastel Theme HTML Document
Future<void> _generatePastelHtml(final String dir) async {
  final fileSink = FileSink(
    '$dir/3_pastel_theme.html',
    encoder: const HtmlEncoder(
      title: 'logd — Pastel Theme Showcase',
    ),
  );

  final handler = Handler(
    formatter: const StructuredFormatter(),
    decorators: const [StyleDecorator(PastelTheme()), BoxDecorator()],
    sink: fileSink,
  );

  Logger.configure('html.pastel',
      logLevel: LogLevel.trace, handlers: [handler]);
  final logger = Logger.get('html.pastel.service');
  _logSampleEntries(logger, 'Pastel Theme HTML');
  await Future.delayed(const Duration(milliseconds: 300));
  await fileSink.dispose();
  print('  ✔ Created $dir/3_pastel_theme.html');
}

/// 4. Custom Theme HTML Document
Future<void> _generateCustomHtml(final String dir) async {
  const customTheme = LogTheme(
    colorScheme: LogColorScheme(
      trace: LogColor.green,
      debug: LogColor.cyan,
      info: LogColor.brightBlue,
      warning: LogColor.yellow,
      error: LogColor.brightRed,
    ),
    timestampStyle: LogStyle(color: LogColor.magenta, bold: true),
    loggerNameStyle: LogStyle(color: LogColor.brightCyan, italic: true),
  );

  final fileSink = FileSink(
    '$dir/4_custom_theme.html',
    encoder: const HtmlEncoder(
      title: 'logd — Custom Theme Showcase',
    ),
  );

  final handler = Handler(
    formatter: const StructuredFormatter(),
    decorators: const [StyleDecorator(customTheme), BoxDecorator()],
    sink: fileSink,
  );

  Logger.configure('html.custom',
      logLevel: LogLevel.trace, handlers: [handler]);
  final logger = Logger.get('html.custom.service');
  _logSampleEntries(logger, 'Custom Theme HTML');
  await Future.delayed(const Duration(milliseconds: 300));
  await fileSink.dispose();
  print('  ✔ Created $dir/4_custom_theme.html\n');
}

/// 5. Live Web Dashboard with HttpServerSink
Future<void> _runRealtimeHtmlDashboard() async {
  print('Launching Real-time HttpServerSink Web Dashboard...');

  final serverSink = HttpServerSink(
    port: 8080,
    encoder: const HtmlEncoder(
      title: 'logd Real-time Live Dashboard',
    ),
  );

  final handler = Handler(
    formatter: const StructuredFormatter(),
    decorators: const [StyleDecorator(DarkTheme()), BoxDecorator()],
    sink: serverSink,
  );

  Logger.configure('dashboard', logLevel: LogLevel.trace, handlers: [handler]);
  final logger = Logger.get('dashboard');

  await serverSink.ready;
  final url = 'http://localhost:${serverSink.boundPort}';
  print('  🚀 Live HTML Web Dashboard active at: $url\n');

  _logSampleEntries(logger, 'Live Server Dashboard Event');
  await serverSink.dispose();
}

void _logSampleEntries(final Logger logger, final String contextLabel) {
  logger.trace('TRACE: Low-level diagnostic details ($contextLabel)');
  logger.debug('DEBUG: Application state updated ($contextLabel)');
  logger.info('INFO: Operation executed successfully');
  logger.warning('WARNING: High memory usage threshold reached');
  logger.error(
    'ERROR: Operational failure in authentication service',
    error: StateError('OAuth token refresh failed'),
    stackTrace: StackTrace.current,
  );
}
