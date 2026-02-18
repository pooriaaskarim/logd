// Example: PlainFormatter - Exhaustive Combinatorial Stress Matrix
//
// Purpose:
// Demonstrates the PlainFormatter's robust layout engine under extreme
// structural pressure. We combine Plain text flows with Double Boxes,
// Deep Hierarchy, ANSI Styling, and ultra-narrow width constraints.
//
// Key Benchmarks:
// 1. Deep Indent Stress (Plain + Style + Depth 4 Hierarchy + 45 Width)
// 2. The Micro-Box (Plain + Style + Double Box + 35 Width)

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / PlainFormatter: Extreme Combinations ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO A: "Deep Indent Stress"
  // Goal: Test multi-line wrapping when the available width is eaten up by
  // deep hierarchy indentation.
  // ---------------------------------------------------------------------------
  const indentHandler = Handler(
    formatter: PlainFormatter(
      metadata: {LogMetadata.timestamp, LogMetadata.logger, LogMetadata.origin},
    ),
    decorators: [
      StyleDecorator(theme: LogTheme(colorScheme: LogColorScheme.pastelScheme)),
      HierarchyDepthPrefixDecorator(indent: '│ '), // Wide indent
      PrefixDecorator(' [SYSTEM] '),
    ],
    sink: ConsoleSink(),
    lineLength: 45, // Tight width after indentation
  );

  // ---------------------------------------------------------------------------
  // SCENARIO B: "The Micro-Box"
  // Goal: Stress-test multi-line metadata wrapping inside a Double-Line Box
  // in an ultra-restricted terminal space.
  // ---------------------------------------------------------------------------
  const boxHandler = Handler(
    formatter: PlainFormatter(
      metadata: {LogMetadata.timestamp, LogMetadata.logger},
    ),
    decorators: [
      StyleDecorator(),
      BoxDecorator(borderStyle: BorderStyle.double),
    ],
    sink: ConsoleSink(),
    lineLength: 35, // Extremely tight!
  );

  // Configure Global Loggers
  Logger.configure('sys.indent', handlers: [indentHandler]);
  Logger.configure('sys.box', handlers: [boxHandler]);

  // --- Run Scenario A: Deep Indent ---
  print('TEST A: Deep Indent Stress (45 Width + Depth 3)');
  Logger.get('sys.indent').info('Starting top-level operation.');

  Logger.get('sys.indent.sub.feature.module').debug(
      'This is a very long message that must wrap multiple times because the '
      'indentation has consumed most of the 45-character width.');
  print('-' * 40);

  // --- Run Scenario B: Micro-Box ---
  print('\nTEST B: The Micro-Box (35 Width + Double Borders)');
  final boxed = Logger.get('sys.box')
    ..info('System online.')
    ..warning('Pressure warning: available space is reaching critical levels.');

  try {
    _crash();
  } catch (e, s) {
    boxed.error('FAILURE', error: e, stackTrace: s);
  }

  print('\n=== Plain Combinatorial Matrix Complete ===');
}

void _crash() {
  throw StateError('Simulated kernel panic in restricted memory space.');
}
