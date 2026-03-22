// Example: StyleDecorator - Visual Personality & Interaction
//
// Purpose:
// Demonstrates logd's fine-grained styling engine. It shows how to use
// predefined schemes, create high-contrast themes, and target specific
// semantic tags (LogTag.message, LogTag.timestamp) for custom visuals.
//
// Key Benchmarks:
// 1. Standard Palette (Standard level colors)
// 2. High-Visibility (Inverse video headers, bold emphasis)
// 3. Tag-Specific Specialist (Unique colors for individual data parts)

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / StyleDecorator Styling Matrix ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO 1: The "Pastel Programmer" (Standard Scheme)
  // ---------------------------------------------------------------------------
  print('TEST 1: Standard Pastel Scheme');
  const standardHandler = Handler(
    formatter: StructuredFormatter(),
    decorators: [
      StyleDecorator(theme: LogTheme(colorScheme: LogColorScheme.pastelScheme)),
    ],
    sink: ConsoleSink(),
  );

  Logger.configure('style.standard', handlers: [standardHandler]);
  Logger.get('style.standard')
    ..info('System online. Routine check complete.')
    ..warning('Disk usage reaching 80%.');

  print('~' * 60);

  // ---------------------------------------------------------------------------
  // SCENARIO 2: The "High-Contrast Admin" (Inverted Headers)
  // Goal: Use theme overrides to make headers instantly identifiable.
  // ---------------------------------------------------------------------------
  print('\nTEST 2: High-Contrast (Inverted Headers)');
  const adminHandler = Handler(
    formatter: StructuredFormatter(),
    decorators: [
      StyleDecorator(theme: _HighContrastTheme()),
    ],
    sink: ConsoleSink(),
  );

  Logger.configure('style.admin', handlers: [adminHandler]);
  Logger.get('style.admin')
    ..error('CRITICAL FAULT', error: 'Voltage regulator failure.')
    ..info('Attempting emergency bypass...');

  print('~' * 60);

  // ---------------------------------------------------------------------------
  // SCENARIO 3: The "Semantic Specialist" (Fine-Grained Tags)
  // Goal: Provide unique visuals for distinct metadata parts using LogTag.
  // ---------------------------------------------------------------------------
  print('\nTEST 3: Tag Specialist (Unique Metadata Colors)');
  const specialistHandler = Handler(
    formatter: StructuredFormatter(
      metadata: {LogMetadata.timestamp, LogMetadata.logger, LogMetadata.origin},
    ),
    decorators: [
      StyleDecorator(theme: _TagSpecialistTheme()),
    ],
    sink: ConsoleSink(),
  );

  Logger.configure('style.special', handlers: [specialistHandler]);
  Logger.get('style.special')
      .info('Note the distinct colors for Timestamp, Logger, and Origin.');

  print('\n=== Styling Matrix Complete ===');
}

/// A theme that inverts the header visuals for extreme visibility.
class _HighContrastTheme extends LogTheme {
  const _HighContrastTheme() : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final int tags) {
    final style = super.getStyle(level, tags);
    if (((tags & LogTag.header) != 0)) {
      return LogStyle(
        color: style.color,
        bold: true,
        inverse: true,
      );
    }
    return style;
  }
}

/// A theme that assigns unique visuals to every semantic part.
class _TagSpecialistTheme extends LogTheme {
  const _TagSpecialistTheme() : super(colorScheme: LogColorScheme.darkScheme);

  @override
  LogStyle getStyle(final LogLevel level, final int tags) {
    if (((tags & LogTag.timestamp) != 0)) {
      return const LogStyle(color: LogColor.yellow, dim: true);
    }
    if (((tags & LogTag.loggerName) != 0)) {
      return const LogStyle(color: LogColor.magenta, bold: true);
    }
    if (((tags & LogTag.origin) != 0)) {
      return const LogStyle(color: LogColor.cyan, italic: true);
    }
    if (((tags & LogTag.message) != 0)) {
      return const LogStyle(color: LogColor.white);
    }
    return super.getStyle(level, tags);
  }
}
