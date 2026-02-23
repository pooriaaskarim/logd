// Example: HTMLFormatter - Profound Web-Based Reporting
//
// Purpose:
// Demonstrates how logd generates professional, styled HTML reports.
// We showcase Dark vs. Light mode, and test how the HTML layout adapts
// to narrow container widths (simulating mobile web views).
//
// Key Benchmarks:
// 1. Modern Dark (Default technical dashboard)
// 2. Paper Light (High-legibility printable report)
// 3. Mobile Container (Squeezed 1200-char width for responsiveness)

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / HTML Reporting Matrix ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO 1: The "Technical Dashboard" (Dark Mode)
  // ---------------------------------------------------------------------------
  final darkSink = FileSink(
    'logs/dashboard_dark.html',
    encoder: const HtmlEncoder(darkMode: true),
    strategy: WrappingStrategy.document,
  );
  final darkHandler = Handler(
    formatter: StructuredFormatter(),
    sink: darkSink,
  );

  // ---------------------------------------------------------------------------
  // SCENARIO 2: The "Printable Report" (Light Mode)
  // ---------------------------------------------------------------------------
  final lightSink = FileSink(
    'logs/report_light.html',
    encoder: const HtmlEncoder(darkMode: false),
    strategy: WrappingStrategy.document,
  );
  final lightHandler = Handler(
    formatter: StructuredFormatter(),
    sink: lightSink,
  );

  // ---------------------------------------------------------------------------
  // SCENARIO 3: "Mobile Viewport" (Narrrow Wrapping)
  // Goal: Test that HTML blocks wrap correctly when width is restricted.
  // ---------------------------------------------------------------------------
  final mobileSink = FileSink(
    'logs/mobile_view.html',
    encoder: const HtmlEncoder(darkMode: true),
    strategy: WrappingStrategy.document,
    lineLength: 40,
  );
  final mobileHandler = Handler(
    formatter: StructuredFormatter(),
    sink: mobileSink,
  );

  // Configure
  Logger.configure('sys.dark', handlers: [darkHandler]);
  Logger.configure('sys.light', handlers: [lightHandler]);
  Logger.configure('sys.mobile', handlers: [mobileHandler]);

  final dark = Logger.get('sys.dark');
  final light = Logger.get('sys.light');
  final mobile = Logger.get('sys.mobile');

  // --- execution ---

  print('Generating Dark Dashboard in logs/dashboard_dark.html...');
  dark
    ..info('Service cluster operational. Nodes synced: 15/15.')
    ..warning('Latency spikes detected in region af-south-1.');

  print('Generating Light Report in logs/report_light.html...');
  light
    ..info('Monthly maintenance cycle complete.')
    ..error(
      'Deployment failure on node-v7.',
      error: 'FileSystemException: No space left.',
    );

  print('Generating Mobile View in logs/mobile_view.html...');
  mobile.info(
      'This is a very long log message that must wrap beautifully even in the '
      'HTML output.');

  // IMPORTANT: Dispose sinks to finalize files
  await darkSink.dispose();
  await lightSink.dispose();
  await mobileSink.dispose();

  print('\n=== HTML Reporting Benchmark Complete ===');
  print('Check the logs/ directory to see your professional web reports!');
}
