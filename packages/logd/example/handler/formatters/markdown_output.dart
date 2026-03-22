// Example: Markdown Encoder - Universal Documentation Generation
//
// Purpose:
// Demonstrates how to use logd to generate high-quality, professional
// GFM (GitHub Flavored Markdown) documentation from standard log formatters.
// Since Markdown is now an Encoder, any formatter (Structured, JSON, TOON)
// can be used to generate the semantic structure.
//
// Scenarios:
// 1. Technical Report (StructuredFormatter -> MarkdownEncoder)
// 2. Machine Summary (JsonFormatter -> MarkdownEncoder)

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / Universal Markdown Showcase ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO 1: The "Rich Technical Report"
  // Using StructuredFormatter to provide a detailed, block-based layout.
  // ---------------------------------------------------------------------------
  final technicalHandler = Handler(
    formatter: const StructuredFormatter(
      metadata: {LogMetadata.timestamp, LogMetadata.logger, LogMetadata.origin},
    ),
    sink: FileSink(
      'logs/tech_report.md',
      encoder: const MarkdownEncoder(),
    ),
  );

  // ---------------------------------------------------------------------------
  // SCENARIO 2: The "JSON Insight Report"
  // Using JsonFormatter to embed machine-readable data in a Markdown wrapper.
  // ---------------------------------------------------------------------------
  final jsonHandler = Handler(
    formatter: const JsonFormatter(),
    sink: FileSink(
      'logs/json_report.md',
      encoder: const MarkdownEncoder(),
    ),
  );

  // Configure loggers
  Logger.configure('doc.tech', handlers: [technicalHandler]);
  Logger.configure('doc.json', handlers: [jsonHandler]);

  final tech = Logger.get('doc.tech');
  final jsonLog = Logger.get('doc.json');

  // --- Run Scenarios ---

  print('SCENARIO 1: Generating technical report in logs/tech_report.md...');
  tech
    ..info('Kernel initialization cycle started.')
    ..debug('Sub-system "NetworkStack" calibrated: 1.2ms latency.');

  try {
    throw StateError('Memory leak detected in ObjectPool<T>. Bytes: 1048576');
  } catch (e, s) {
    tech.error('Severe Resource Fault!', error: e, stackTrace: s);
  }

  print('SCENARIO 2: Generating JSON report in logs/json_report.md...');
  jsonLog
    ..info('Deployment of v2.5.0-alpha successful.')
    ..warning('Resource usage peaking at 85% on node-7.');

  print('\n=== Professional Markdown Generation Complete ===');
  print('Check the "logs/" directory for .md output.');
}
