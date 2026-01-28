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
  final standardHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const StyleDecorator(
          theme: LogTheme(colorScheme: LogColorScheme.pastelScheme)),
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('style.standard', handlers: [standardHandler]);
  final std = Logger.get('style.standard');
  std.info('System online. Routine check complete.');
  std.warning('Disk usage reaching 80%.');

  print('~' * 60);

  // ---------------------------------------------------------------------------
  // SCENARIO 2: The "High-Contrast Admin" (Inverted Headers)
  // Goal: Use theme overrides to make headers instantly identifiable.
  // ---------------------------------------------------------------------------
  print('\nTEST 2: High-Contrast (Inverted Headers)');
  final adminHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const StyleDecorator(theme: _HighContrastTheme()),
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('style.admin', handlers: [adminHandler]);
  final admin = Logger.get('style.admin');
  admin.error('CRITICAL FAULT', error: 'Voltage regulator failure.');
  admin.info('Attempting emergency bypass...');

  print('~' * 60);

  // ---------------------------------------------------------------------------
  // SCENARIO 3: The "Semantic Specialist" (Fine-Grained Tags)
  // Goal: Provide unique visuals for distinct metadata parts using LogTag.
  // ---------------------------------------------------------------------------
  print('\nTEST 3: Tag Specialist (Unique Metadata Colors)');
  final specialistHandler = Handler(
    formatter: const StructuredFormatter(
      metadata: {LogMetadata.timestamp, LogMetadata.logger, LogMetadata.origin},
    ),
    decorators: [
      const StyleDecorator(theme: _TagSpecialistTheme()),
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('style.special', handlers: [specialistHandler]);
  final special = Logger.get('style.special');
  special.info('Note the distinct colors for Timestamp, Logger, and Origin.');

  print('\n=== Styling Matrix Complete ===');
}

/// A theme that inverts the header visuals for extreme visibility.
class _HighContrastTheme extends LogTheme {
  const _HighContrastTheme() : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    var style = super.getStyle(level, tags);
    if (tags.contains(LogTag.header)) {
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
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    if (tags.contains(LogTag.timestamp)) {
      return const LogStyle(color: LogColor.yellow, dim: true);
    }
    if (tags.contains(LogTag.loggerName)) {
      return const LogStyle(color: LogColor.magenta, bold: true);
    }
    if (tags.contains(LogTag.origin)) {
      return const LogStyle(color: LogColor.cyan, italic: true);
    }
    if (tags.contains(LogTag.message)) {
      return const LogStyle(color: LogColor.white);
    }
    return super.getStyle(level, tags);
  }
}
