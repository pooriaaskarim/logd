// Example: BoxDecorator - Structural Framing & Pressure Testing
//
// Purpose:
// Demonstrates how the BoxDecorator provides highly visual boundaries for logs.
// It exercises border style selection and tests how the box adapts to
// internal wrapping (from formatters) and external indentation
// (from hierarchy).

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / BoxDecorator Structural Matrix ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO 1: Style Matrix
  // Goal: Quick comparison of available boundary characters.
  // ---------------------------------------------------------------------------
  print('TEST 1: Border Style Matrix');

  await _showBorder(BorderStyle.rounded, 'Rounded (Modern)');
  await _showBorder(BorderStyle.sharp, 'Sharp (Classic)');
  await _showBorder(BorderStyle.double, 'Double (Emphasis)');

  print('=' * 60);

  // ---------------------------------------------------------------------------
  // SCENARIO 2: The "Full Stack" (Indented Box)
  // Goal: Verify that Box and Hierarchy indents play nicely without collision.
  // ---------------------------------------------------------------------------
  print('\nTEST 2: The Full Stack (Depth 2 Indentation)');

  const fullStackHandler = Handler(
    formatter: StructuredFormatter(),
    decorators: [
      StyleDecorator(),
      BoxDecorator(borderStyle: BorderStyle.rounded),
      HierarchyDepthPrefixDecorator(indent: '┃ '),
    ],
    sink: ConsoleSink(),
    lineLength: 60,
  );

  Logger.configure('box.full', handlers: [fullStackHandler]);
  // ---------------------------------------------------------------------------

  Logger.get('box.full.sub.feature').info('Feature initialization starting...');

  print('=' * 60);

  // ---------------------------------------------------------------------------
  // SCENARIO 3: Pressure Test (Narrow Wrapping)
  // Goal: Force internal wrapping inside the box to test width calculation.
  // ---------------------------------------------------------------------------
  print('\nTEST 3: Pressure Test (35 chars + Boxes)');

  const pressureHandler = Handler(
    formatter: PlainFormatter(
      metadata: {LogMetadata.timestamp, LogMetadata.logger},
    ),
    decorators: [
      StyleDecorator(),
      BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: ConsoleSink(),
    lineLength: 35, // Very tight for metadata + box
  );

  Logger.configure('box.pressure', handlers: [pressureHandler]);
  Logger.get('box.pressure').info(
    'This message is long enough to force internal wrapping inside the '
    'rounded box borders.',
  );

  print('\n=== BoxDecorator Matrix Complete ===');
}

Future<void> _showBorder(final BorderStyle style, final String label) async {
  final handler = Handler(
    formatter: const PlainFormatter(metadata: {}),
    decorators: [BoxDecorator(borderStyle: style)],
    sink: const ConsoleSink(),
    lineLength: 50,
  );
  // Using a unique logger for style matrix comparison
  final name = 'style.${style.name}';
  Logger.configure(name, handlers: [handler]);
  Logger.get(name).info('Testing $label');
}
