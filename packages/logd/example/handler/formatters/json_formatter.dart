// Example: JSON Formatting & Structural Inspection
//
// Purpose:
// Demonstrates how to use JsonFormatter and JsonPrettyFormatter for both
// machine consumption and human-friendly data inspection.

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / JSON Formatting Showcase ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO A: Single-Line Machine JSON (RAW)
  // Goal: Baseline test for single-line, machine-readable output.
  // ---------------------------------------------------------------------------
  const rawHandler = Handler(
    formatter: JsonFormatter(
      metadata: {LogMetadata.timestamp},
    ),
    sink: ConsoleSink(lineLength: 100),
  );

  // ---------------------------------------------------------------------------
  // SCENARIO B: The "JSON Inspector" (Pretty + Boxed)
  // Goal: Maximum human readability for complex data structures.
  // Composition:
  //   JsonPrettyFormatter -> Style -> HierarchyIndentation -> AlignedSuffix -> Box
  // ---------------------------------------------------------------------------
  final inspectorHandler = Handler(
    formatter: const JsonPrettyFormatter(
        color: true, // Enable semantic tagging for StyleDecorator
        metadata: {},
        indent: '  ',
        keyWrapThreshold: 51),
    decorators: [
      StyleDecorator(theme: JsonInspectorTheme()),
      const HierarchyDepthPrefixDecorator(indent: '│ '),
      const SuffixDecorator(' [AUDIT]', aligned: true),
      const BoxDecorator(borderStyle: BorderStyle.sharp),
    ],
    sink: const ConsoleSink(
        lineLength: 100), // Narrow enough to force internal wrapping of values
  );

  // Configure Global Loggers
  Logger.configure('data.raw', handlers: [rawHandler]);
  Logger.configure('data.inspect', handlers: [inspectorHandler]);

  print('TEST A: Raw JSON (Single Line)');
  Logger.get('data.raw.service')
      .info('User login successful', error: {'uid': '882', 'ip': '1.1.1.1'});

  print('\n${'=' * 60}\n');

  print('\nTEST B: JSON Boxed (Sharp Box + Hierarchy + Suffix)');
  final inspector = Logger.get('data.inspect.service.v1')
    ..warning(
      'Sub-optimal performance detected in cache layer.',
      error: {
        'cache_type': 'DistributedRedis',
        'hit_rate': 0.72,
        'latency_ms': 54.2,
        'nodes_failing': ['eu-west-1a', 'eu-west-1c'],
        'remediation': 'Scaling cluster size to 5 nodes.',
      },
    );

  print('\nTEST C: Stringified JSON Auto-expansion');
  inspector.info('{"system_status": "yellow", "load_avg": [1.5, 2.3, 2.1],'
      ' "tasks": {"pending": 45, "active": 202}}');

  print('\nTEST D: Alphabetical Sorting & Max Depth (80 chars)');
  final sortedHandler = Handler(
    formatter: const JsonPrettyFormatter(
      color: true,
      metadata: {},
      // sortKeys: true,
      maxDepth: 2, // Cut off deep nesting
    ),
    decorators: [
      StyleDecorator(theme: JsonInspectorTheme()),
      const BoxDecorator(borderStyle: BorderStyle.sharp),
    ],
    sink: const ConsoleSink(lineLength: 80),
  );
  Logger.configure('data.sorted', handlers: [sortedHandler]);
  Logger.get('data.sorted').info('Sorted overview', error: {
    'zebra': 'last',
    'alpha': 'first',
    'complex': {
      'nested_1': {
        'nested_2': {'nested_3': 'should be truncated'}
      }
    }
  });

  // ---------------------------------------------------------------------------
  // SCENARIO E: Narrow Terminal Adaptation
  // Goal: Demonstrate "Wise" representation when horizontal space is critical.
  // ---------------------------------------------------------------------------
  void demonstrateNarrow(final int width) {
    print('\nNARROW ADAPTATION TEST ($width chars)');
    final narrowHandler = Handler(
      formatter: const JsonPrettyFormatter(
        color: true,
        metadata: {},
      ),
      decorators: [
        StyleDecorator(theme: JsonInspectorTheme()),
        const BoxDecorator(borderStyle: BorderStyle.sharp),
      ],
      sink: ConsoleSink(lineLength: width),
    );
    Logger.configure('data.narrow.$width', handlers: [narrowHandler]);
    Logger.get('data.narrow.$width').info('Narrow layout', error: {
      'status': 'critical',
      'tags': ['web', 'mobile'], // Short list -> compact
      'details': {
        'retry_count': 3,
        'user_id': 1002,
      }, // Small map -> compact
      'long_key_to_force_stacking': {'a': 1}, // Long key -> stack
    });
  }

  demonstrateNarrow(40);
  demonstrateNarrow(25);

  print('\n=== JSON Showcase Complete ===');
}

/// Custom theme for the JSON inspector to make keys pop.
class JsonInspectorTheme extends LogTheme {
  const JsonInspectorTheme() : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final int tags) {
    if (((tags & LogTag.key) != 0)) {
      return const LogStyle(color: LogColor.cyan, bold: true);
    }
    if (((tags & LogTag.value) != 0)) {
      // Note: This matches both strings and numbers in this simplified tags model.
      return const LogStyle(color: LogColor.yellow);
    }
    return super.getStyle(level, tags);
  }
}
