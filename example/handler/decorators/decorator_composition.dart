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
    formatter: PlainFormatter(),
    decorators: [
      const AnsiColorDecorator(
        useColors: true,
      ),
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
        lineLength: 60,
        useColors: false, // Explicitly disable colors to prevent auto-detection
      ),
    ],
    sink: const ConsoleSink(),
  );

  // Box then Color (auto-sorted)
  final boxThenColor = Handler(
    formatter: PlainFormatter(),
    decorators: [
      BoxDecorator(
        borderStyle: BorderStyle.rounded,
        lineLength: 60,
      ),
      // Note: useColors defaults to null (auto-detect), which may color borders
      // BoxDecorator's useColors: false setting only applies to border coloring
      // ANSI ColorDecorator will handle content coloring independently
      const AnsiColorDecorator(useColors: true),
    ],
    sink: const ConsoleSink(),
  );

  // Box then Color (auto-sorted)

  // Color + Box + Hierarchy
  final fullComposition = Handler(
    formatter: PlainFormatter(),
    decorators: [
      const AnsiColorDecorator(useColors: true),
      BoxDecorator(
        borderStyle: BorderStyle.sharp,
        lineLength: 60,
        useColors: false,
      ),
      const HierarchyDepthPrefixDecorator(indent: '│ '),
    ],
    sink: const ConsoleSink(),
  );

  // Multiple color decorators (should deduplicate)
  final duplicateColors = Handler(
    formatter: PlainFormatter(),
    decorators: const [
      AnsiColorDecorator(useColors: true),
      AnsiColorDecorator(useColors: true), // Duplicate
      AnsiColorDecorator(useColors: true), // Duplicate
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
