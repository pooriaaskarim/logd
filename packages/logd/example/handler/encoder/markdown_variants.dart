import 'package:logd/logd.dart';
import 'dart:io';

void main() async {
  print('=== Logd / Markdown Encoder Variants Showcase ===\n');

  final logFile = File('logs/markdown_variants.md');
  if (logFile.existsSync()) logFile.deleteSync();

  final logDir = logFile.parent;
  if (!logDir.existsSync()) logDir.createSync(recursive: true);

  // 1. Setup Handlers
  final structuredHandler = Handler(
    formatter: const StructuredFormatter(),
    sink: FileSink(logFile.path, encoder: const MarkdownEncoder()),
  );

  final jsonHandler = Handler(
    formatter: const JsonFormatter(),
    sink: FileSink(logFile.path, encoder: const MarkdownEncoder()),
  );

  final plainHandler = Handler(
    formatter: const PlainFormatter(),
    sink: FileSink(logFile.path, encoder: const MarkdownEncoder()),
  );

  final toonHandler = Handler(
    formatter: const ToonFormatter(),
    sink: FileSink(logFile.path, encoder: const MarkdownEncoder()),
  );

  // 2. Logging via different formatters
  print('Logging via StructuredFormatter...');
  Logger.configure('showcase.structured', handlers: [structuredHandler]);
  Logger.get('showcase.structured')
      .info('Universal Markdown (Structured) test.');

  print('Logging via JsonFormatter...');
  Logger.configure('showcase.json', handlers: [jsonHandler]);
  Logger.get('showcase.json').info('Universal Markdown (JSON) test.');

  print('Logging via PlainFormatter...');
  Logger.configure('showcase.plain', handlers: [plainHandler]);
  Logger.get('showcase.plain').info('Universal Markdown (Plain) test.');

  print('Logging via ToonFormatter...');
  Logger.configure('showcase.toon', handlers: [toonHandler]);
  Logger.get('showcase.toon').info('Universal Markdown (Toon) test.');

  print('\n=== Professional Markdown Generation Complete ===');
  print('Results persisted in logs/markdown_variants.md');

  await structuredHandler.sink.dispose();
  await jsonHandler.sink.dispose();
  await plainHandler.sink.dispose();
  await toonHandler.sink.dispose();
}
