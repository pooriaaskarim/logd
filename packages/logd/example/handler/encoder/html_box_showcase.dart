import 'dart:io';
import 'package:logd/logd.dart';

void main() async {
  final logsDir = Directory('logs');
  if (!logsDir.existsSync()) logsDir.createSync();

  final darkFile = File('logs/html_boxed_dark.html');
  final lightFile = File('logs/html_boxed_light.html');

  if (darkFile.existsSync()) darkFile.deleteSync();
  if (lightFile.existsSync()) lightFile.deleteSync();

  // Scenarios
  final darkSink = FileSink(
    darkFile.path,
    encoder: const HtmlEncoder(),
    strategy: WrappingStrategy.document,
  );
  final lightSink = FileSink(
    lightFile.path,
    encoder: const HtmlEncoder(
      darkMode: false,
      title: 'Light Boxed Logs',
    ),
    strategy: WrappingStrategy.document,
  );

  final darkHandler = Handler(
    formatter: const StructuredFormatter(),
    sink: darkSink,
    decorators: [const BoxDecorator()],
  );

  final lightHandler = Handler(
    formatter: const StructuredFormatter(),
    sink: lightSink,
    decorators: [const BoxDecorator(borderStyle: BoxBorderStyle.double)],
  );

  print('=== Logd Boxed HTML Showcase ===');

  Logger.configure('box.dark', handlers: [darkHandler]);
  Logger.configure('box.light', handlers: [lightHandler]);

  final dark = Logger.get('box.dark');
  final light = Logger.get('box.light');

  dark.info('This is a message inside a box with a structured header.');

  dark.warning('Another entry to see how they stack inside boxes.');

  light.error('Critical error in light mode with double borders!',
      error: 'connection_reset');

  // Finalize
  await darkSink.dispose();
  await lightSink.dispose();

  print('Showcase complete. Check:');
  print(' - logs/html_boxed_dark.html');
  print(' - logs/html_boxed_light.html');
}
