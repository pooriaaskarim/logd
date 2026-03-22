// Example: ToonFormatter - Exhaustive Showcase
//
// Purpose:
// Demonstrates the ToonFormatter's personality under various structural
// requirements, contrasting Raw (Machine) and Pretty (Narrative) models.

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / TOON Formatter Showcase ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO A: The Machine Pipeline (RAW TOON)
  // Goal: Maximum token efficiency for machine parsers or LLM context.
  // Characteristics: No color, raw toString() for objects, flat rows.
  // ---------------------------------------------------------------------------
  const machineHandler = Handler(
    formatter: ToonFormatter(
      metadata: {LogMetadata.timestamp},
    ),
    sink: ConsoleSink(lineLength: 120),
  );

  // ---------------------------------------------------------------------------
  // SCENARIO B: The Visual Narrator (PRETTY TOON)
  // Goal: Human-readable narrative logs with structured object inspection.
  // Characteristics: Color, recursive object notation, sorted keys.
  // ---------------------------------------------------------------------------
  const narratorHandler = Handler(
    formatter: ToonPrettyFormatter(
      color: true,
      sortKeys: true,
      metadata: {LogMetadata.logger},
    ),
    decorators: [
      StyleDecorator(theme: LogTheme(colorScheme: LogColorScheme.pastelScheme)),
      HierarchyDepthPrefixDecorator(indent: '┃ '),
      SuffixDecorator(' [v8]', aligned: true),
    ],
    sink: ConsoleSink(lineLength: 80),
  );

  // ---------------------------------------------------------------------------
  // SCENARIO C: Deep Structural Audit
  // Goal: Prevent runaway output while allowing nested inspection.
  // Characteristics: maxDepth clamping, sorted keys.
  // ---------------------------------------------------------------------------
  const auditHandler = Handler(
    formatter: ToonPrettyFormatter(
      maxDepth: 2,
      sortKeys: true,
      metadata: {},
    ),
    decorators: [
      StyleDecorator(theme: JsonInspectorTheme()),
      BoxDecorator(borderStyle: BorderStyle.sharp),
    ],
    sink: ConsoleSink(lineLength: 60),
  );

  // Configure Loggers
  Logger.configure('toon.raw', handlers: [machineHandler]);
  Logger.configure('toon.pretty', handlers: [narratorHandler]);
  Logger.configure('toon.audit', handlers: [auditHandler]);

  final sampleData = {
    'system': 'Alpha-7',
    'status': 'degraded',
    'sensors': {'temp': 120, 'load': 0.85, 'pressure': 1013},
    'tags': ['active', 'critical', 'thermal-alert']
  };

  print('TEST A: Raw TOON (Machine Optimized)');
  Logger.get('toon.raw.io').info('Telemetry Sync', error: sampleData);

  print('\n${'-' * 40}\n');

  print('TEST B: Pretty TOON (Narrative Style)');
  final narrator = Logger.get('toon.pretty.engine.v8');
  narrator.info('Chapter 1: The Reactor Ignition.');
  narrator.warning('Heat spike detected in secondary coil.', error: sampleData);

  print('\n${'-' * 40}\n');

  print('TEST C: Deep Audit (maxDepth: 2)');
  Logger.get('toon.audit')
      .error('Critical breach in nested subsystems!', error: {
    'primary': 'breached',
    'secondary': {
      'pumps': {'p1': 'offline', 'p2': 'nominal'},
      'coolant': 'low',
    },
    'tertiary': 'clamped_by_depth'
  });

  print('\n${'-' * 40}\n');

  // ---------------------------------------------------------------------------
  // SCENARIO D: Narrow Adaptation (Stress Test)
  // Goal: Demonstrate layout resilience at 30 character width.
  // ---------------------------------------------------------------------------
  print('TEST D: Narrow Terminal Adaptation (30 chars)');
  final narrowHandler = Handler(
    formatter: const ToonPrettyFormatter(metadata: {}),
    decorators: [
      StyleDecorator(theme: JsonInspectorTheme()),
      const BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: const ConsoleSink(lineLength: 30),
  );
  Logger.configure('toon.narrow', handlers: [narrowHandler]);
  Logger.get('toon.narrow').warning('Warning: System resources extremely low.',
      error: {'cpu': '98%', 'mem': '99%'});

  print('\n=== TOON Showcase Complete ===');
}

/// A custom theme for the TOON Inspector.
class JsonInspectorTheme extends LogTheme {
  const JsonInspectorTheme() : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final int tags) {
    if (((tags & LogTag.header) != 0)) {
      return const LogStyle(color: LogColor.blue, bold: true, dim: true);
    }
    if (((tags & LogTag.level) != 0)) {
      return LogStyle(color: _levelColor(level), bold: true);
    }
    return super.getStyle(level, tags);
  }

  LogColor _levelColor(final LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return LogColor.red;
      case LogLevel.warning:
        return LogColor.yellow;
      default:
        return LogColor.blue;
    }
  }
}
