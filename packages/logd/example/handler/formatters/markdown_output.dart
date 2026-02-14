// Example: MarkdownFormatter - Profound Documentation Generation
//
// Purpose:
// Demonstrates how to use logd to generate high-quality, professional
// documentation from log data. This is perfect for CI/CD reports,
// GitHub issues, or technical knowledge bases.
//
// Key Benchmarks:
// 1. The "Rich Technical Report" (Detailed, Interactive)
// 2. The "Executive Summary" (Minimalist, Concise)

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / Profound Markdown Showcase ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO 1: The "Rich Technical Report"
  // Goal: Provide a comprehensive layout with interactive stack traces.
  // ---------------------------------------------------------------------------
  final technicalHandler = Handler(
    formatter: const MarkdownFormatter(
      metadata: {LogMetadata.timestamp, LogMetadata.logger, LogMetadata.origin},
      headingLevel: 3,
    ),
    sink: FileSink('logs/tech_report.md'),
  );

  // ---------------------------------------------------------------------------
  // SCENARIO 2: The "High-Level Executive Summary"
  // Goal: Clean, large-heading logs with zero technical clutter.
  // ---------------------------------------------------------------------------
  final summaryHandler = Handler(
    formatter: const MarkdownFormatter(
      metadata: {}, // Purely level + message
      headingLevel: 2,
    ),
    sink: FileSink('logs/summary.md'),
  );

  // Configure
  Logger.configure('doc.tech', handlers: [technicalHandler]);
  Logger.configure('doc.exec', handlers: [summaryHandler]);

  final tech = Logger.get('doc.tech');
  final exec = Logger.get('doc.exec');

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

  print('SCENARIO 2: Generating executive summary in logs/summary.md...');
  exec
    ..info('Deployment of v2.5.0-alpha successful on cluster-green.')
    ..warning('Minor degradation observed in legacy Auth module.');

  print('\n=== Professional Markdown Generation Complete ===');
}
