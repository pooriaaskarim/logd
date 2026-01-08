// Example: Decorator Composition
//
// Demonstrates:
// - Multiple decorators working together
// - Auto-sorting behavior
// - Color + Box composition
// - Hierarchy indentation
// - Order independence (auto-sort)
//
// Expected: Decorators compose correctly regardless of order

import 'package:logd/logd.dart';

void main() async {
  // Color then Box (correct order)
  final colorThenBox = Handler(
    formatter: const PlainFormatter(),
    decorators: [
      const ColorDecorator(),
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
      ),
    ],
    sink: const ConsoleSink(),
    lineLength: 60,
  );

  // Box then Color (auto-sorted)
  final boxThenColor = Handler(
    formatter: const PlainFormatter(),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
      ),
      const ColorDecorator(
          config: ColorConfig(
        colorBorder: false,
        colorTimestamp: true,
        colorLevel: true,
        colorLoggerName: true,
        colorMessage: false,
        headerBackground: true,
      )),
    ],
    sink: const ConsoleSink(),
    lineLength: 60,
  );

  // Box then Color (auto-sorted)

  // Color + Box + Hierarchy
  final fullComposition = Handler(
    formatter: const PlainFormatter(),
    decorators: [
      const ColorDecorator(),
      BoxDecorator(
        borderStyle: BorderStyle.sharp,
      ),
      const HierarchyDepthPrefixDecorator(indent: '│ '),
    ],
    sink: const ConsoleSink(),
    lineLength: 60,
  );

  // Multiple color decorators (should deduplicate)
  final duplicateColors = Handler(
    formatter: const PlainFormatter(),
    decorators: const [
      ColorDecorator(),
      ColorDecorator(), // Duplicate
      ColorDecorator(), // Duplicate
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('example.colorthenbox', handlers: [colorThenBox]);
  Logger.configure('example.boxthencolor', handlers: [boxThenColor]);
  Logger.configure('example.full', handlers: [fullComposition]);
  Logger.configure('example.duplicate', handlers: [duplicateColors]);

  final logger1 = Logger.get('example.colorthenbox');
  final logger2 = Logger.get('example.boxthencolor');
  final logger3 = Logger.get('example.full');
  final logger4 = Logger.get('example.duplicate');

  print('=== Color Then Box (Explicit Order) ===');
  logger1.info('Message with color then box');

  print('\n=== Box Then Color (Auto-Sorted) ===');
  logger2.info('Message with box then color (should be same as above)');

  print('\n=== Full Composition (Color + Box + Hierarchy) ===');
  logger3.info('Root level message');
  final childLogger = Logger.get('example.full.child');
  childLogger.info('Child level message (should be indented)');

  print('\n=== Duplicate Decorators (Should Deduplicate) ===');
  logger4.info('Message with duplicate color decorators');
}
