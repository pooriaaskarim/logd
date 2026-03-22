import 'package:logd/logd.dart';
import 'dart:io';

void main() async {
  print('=== Logd Enhanced HTML Showcase ===');

  // Ensure logs directory exists
  Directory('logs').createSync(recursive: true);

  // 1. Dark Theme (High-end terminal feel)
  final darkSink = FileSink(
    'logs/html_enhanced_dark.html',
    encoder: const HtmlEncoder(
      darkMode: true,
      title: 'Dark Performance Dashboard',
    ),
    strategy: WrappingStrategy.document,
  );

  // 2. Custom Pastel Theme
  final pastelTheme = const LogTheme(
    colorScheme: LogColorScheme.pastelScheme,
    messageStyle: LogStyle(italic: true),
  );
  final lightSink = FileSink(
    'logs/html_enhanced_light.html',
    encoder: HtmlEncoder(
      theme: pastelTheme,
      title: 'Light Pastel Report',
    ),
    strategy: WrappingStrategy.document,
  );

  final darkHandler = Handler(
    formatter: StructuredFormatter(),
    sink: darkSink,
  );

  final lightHandler = Handler(
    formatter: StructuredFormatter(),
    sink: lightSink,
  );

  Logger.configure('showcase.dark', handlers: [darkHandler]);
  Logger.configure('showcase.light', handlers: [lightHandler]);

  final dark = Logger.get('showcase.dark');
  final light = Logger.get('showcase.light');

  // Log some content
  for (final l in [dark, light]) {
    l.info('Logging system initialized.');
    l.debug('Analyzing cluster topology...');
    l.warning('Latency threshold exceeded: 250ms');
    l.error('Failed to commit transaction.',
        error: 'OptimisticLockingException');

    // Test structured features
    l.info('User session started',
        error: {'user_id': '12345', 'role': 'admin', 'ip': '192.168.1.1'});
  }

  await darkSink.dispose();
  await lightSink.dispose();

  print('\nShowcase complete. Check:');
  print(' - logs/html_enhanced_dark.html');
  print(' - logs/html_enhanced_light.html');
}
