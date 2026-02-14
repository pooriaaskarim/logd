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
// 3. Mobile Container (Squeezed 45-char width for responsiveness)

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / HTML Reporting Matrix ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO 1: The "Technical Dashboard" (Dark Mode)
  // ---------------------------------------------------------------------------
  const darkSink =
      HTMLSink(filePath: 'logs/dashboard_dark.html', darkMode: true);
  const darkHandler = Handler(
    formatter: HTMLFormatter(),
    sink: darkSink,
  );

  // ---------------------------------------------------------------------------
  // SCENARIO 2: The "Printable Report" (Light Mode)
  // ---------------------------------------------------------------------------
  const lightSink =
      HTMLSink(filePath: 'logs/report_light.html', darkMode: false);
  const lightHandler = Handler(
    formatter: HTMLFormatter(),
    sink: lightSink,
  );

  // ---------------------------------------------------------------------------
  // SCENARIO 3: "Mobile Viewport" (Narrrow Wrapping)
  // Goal: Test that HTML blocks wrap correctly when width is restricted.
  // ---------------------------------------------------------------------------
  const mobileSink =
      HTMLSink(filePath: 'logs/mobile_view.html', darkMode: true);
  const mobileHandler = Handler(
    formatter: HTMLFormatter(),
    sink: mobileSink,
    lineLength: 45, // Mobile-width simulation
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
      'HTML output because the handler restricted the width to 45 characters.');

  // IMPORTANT: Close sinks to finalize files
  await darkSink.close();
  await lightSink.close();
  await mobileSink.close();

  print('\n=== HTML Reporting Benchmark Complete ===');
  print('Check the logs/ directory to see your professional web reports!');
}
