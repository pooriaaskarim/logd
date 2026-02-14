// Example: StructuredFormatter - Exhaustive Combinatorial Stress Matrix
//
// Purpose:
// Demonstrates the StructuredFormatter's tiered framing layout under
// extreme combinatorial pressure. We combine multi-stage headers with
// Boxes, Hierarchy, and fine-grained LogTag color overrides.
//
// Key Benchmarks:
// 1. Dashboard Elite (Structured + Custom Tag Theme + Rounded Box + 80 Width)
// 2. The Framing Squeeze (Structured + Style + Box + Hierarchy + 40 Width)

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / StructuredFormatter: Extreme Combinations ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO A: "Dashboard Elite"
  // Goal: Create a high-impact developer dashboard with unique semantic visual
  // identities for metadata.
  // ---------------------------------------------------------------------------
  const dashboardHandler = Handler(
    formatter: StructuredFormatter(),
    decorators: [
      StyleDecorator(theme: _EliteDashboardTheme()),
      BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: ConsoleSink(),
    lineLength: 80,
  );

  // ---------------------------------------------------------------------------
  // SCENARIO B: "The Framing Squeeze"
  // Goal: The absolute stress test for tiered framing. We stack Hierarchy
  // depth, rounded boxes, and styled metadata into a tiny 40-char window.
  // ---------------------------------------------------------------------------
  const squeezeHandler = Handler(
    formatter: StructuredFormatter(
      metadata: {LogMetadata.timestamp, LogMetadata.logger, LogMetadata.origin},
    ),
    decorators: [
      StyleDecorator(theme: LogTheme(colorScheme: LogColorScheme.pastelScheme)),
      BoxDecorator(borderStyle: BorderStyle.rounded),
      HierarchyDepthPrefixDecorator(indent: '┃ '),
    ],
    sink: ConsoleSink(),
    lineLength: 40, // Extreme squeeze for Framed Header + Box + Indent
  );

  // Configure loggers
  Logger.configure('ui.elite', handlers: [dashboardHandler]);
  Logger.configure('ui.squeeze', handlers: [squeezeHandler]);

  // --- Run Scenario A: Dashboard Elite ---
  print('TEST A: Dashboard Elite (80 Width + Custom Tag Styling)');
  Logger.get('ui.elite')
    ..info('Service cluster "Athena" reporting nominal performance.')
    ..warning('Throughput at soft-limit for node-west-4.');
  print('=' * 40);

  // --- Run Scenario B: Framing Squeeze ---
  print('\nTEST B: The Framing Squeeze (40 Width + Box + Indent + Style)');
  Logger.get('ui.squeeze').info('Top level activity.');

  Logger.get('ui.squeeze.sub.module.feature')
    ..debug('Checking state...')
    ..error(
      'Resource Fault!',
      error: 'OutOfMemoryError: Heap limit exceeded in GarbageCollector.',
    );

  print('\n=== Structured Combinatorial Matrix Complete ===');
}

/// A specialized theme that uses [LogTag] to create a "Dashboard" visual
/// layout.
class _EliteDashboardTheme extends LogTheme {
  const _EliteDashboardTheme() : super(colorScheme: LogColorScheme.darkScheme);

  @override
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    // Make headers stand out with bold/yellow
    if (tags.contains(LogTag.header) && !tags.contains(LogTag.level)) {
      return const LogStyle(color: LogColor.yellow, bold: true);
    }
    // Make Level names inverse for a "Status Indicator" feel
    if (tags.contains(LogTag.level)) {
      return LogStyle(color: _levelColor(level), inverse: true, bold: true);
    }
    // Make specific logger names magenta
    if (tags.contains(LogTag.loggerName)) {
      return const LogStyle(color: LogColor.magenta);
    }
    // Dimmish borders
    if (tags.contains(LogTag.border)) {
      return const LogStyle(color: LogColor.blue, dim: true);
    }
    return super.getStyle(level, tags);
  }

  LogColor _levelColor(final LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return LogColor.red;
      case LogLevel.warning:
        return LogColor.yellow;
      case LogLevel.info:
        return LogColor.blue;
      default:
        return LogColor.cyan;
    }
  }
}
