// Example: JsonFormatter - Exhaustive Combinatorial Stress Matrix
//
// Purpose:
// Demonstrates how machine-parseable data can be transformed into human-friendly
// visual "Inspections" using the Logd pipeline. We combine JSON output
// with sharp borders, semantic styling, and multi-line wrapping.
//
// Key Benchmarks:
// 1. Raw Data Stream (Standard JSON for ingestors)
// 2. JSON Boxed (Pretty-print + Semantic Style + Sharp Box + 50 Width)

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / JSON: Extreme Combinations ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO A: The "Production Pipe" (Raw JSON)
  // Goal: Baseline test for single-line, machine-readable output.
  // ---------------------------------------------------------------------------
  final rawHandler = Handler(
    formatter: const JsonFormatter(
      metadata: {LogMetadata.timestamp},
    ),
    sink: const ConsoleSink(),
    lineLength: 100,
  );

  // ---------------------------------------------------------------------------
  // SCENARIO B: "JSON Boxed" (The Inspector)
  // Goal: Use JsonPrettyFormatter (with colors enabled) inside a Sharp Box
  // to create a "Technical Property Inspector" feel.
  // Constraints: 50-char width + customized punctuation colors.
  // ---------------------------------------------------------------------------
  final inspectorHandler = Handler(
    formatter: const JsonPrettyFormatter(
      color: true, // Enable semantic tagging for StyleDecorator
      metadata: {...LogMetadata.values},
      indent: '  ',
    ),
    decorators: [
      const StyleDecorator(theme: _JsonInspectorTheme()),
      const HierarchyDepthPrefixDecorator(indent: '│ '),
      const PrefixDecorator(
        ' [AUDIT]',
      ),
      const SuffixDecorator(' [AUDIT]', aligned: true),
      BoxDecorator(borderStyle: BorderStyle.sharp),
    ],
    sink: const ConsoleSink(),
    lineLength: 50, // Narrow enough to force internal wrapping of values
  );

  // Configure Global Loggers
  Logger.configure('data.raw', handlers: [rawHandler]);
  Logger.configure('data.inspect', handlers: [inspectorHandler]);

  // --- Run Scenario A: Raw Stream ---
  print('TEST A: Raw JSON Data Stream (100 Width)');
  final raw = Logger.get('data.raw');
  raw.info('Event: transaction_complete | id=TX-5512 | state=success');
  print('-' * 40);

  print('\nTEST B: JSON Boxed (Sharp Box + Hierarchy + Suffix)');
  final inspector = Logger.get('data.inspect.service.v1');
  inspector.warning('Sub-optimal performance detected in cache layer.', error: {
    'cache_type': 'DistributedRedis',
    'hit_rate': 0.72,
    'latency_ms': 54.2,
    'nodes_failing': ['eu-west-1a', 'eu-west-1c'],
    'remediation': 'Scaling cluster size to 5 nodes.'
  });

  print('\nTEST C: Stringified JSON Auto-expansion');
  inspector.info('{"system_status": "yellow", "load_avg": [1.5, 2.3, 2.1],'
      ' "details": {"source": "background_worker", "pid": 12345}}');

  print('\n=== JSON Combinatorial Matrix Complete ===');
}

/// A specialized theme for the JSON Inspector that makes keys and values pop.
class _JsonInspectorTheme extends LogTheme {
  const _JsonInspectorTheme() : super(colorScheme: LogColorScheme.darkScheme);

  @override
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    // Make JSON keys bold/magenta
    if (tags.contains(LogTag.key)) {
      return const LogStyle(color: LogColor.magenta, bold: true);
    }
    // Make JSON punctuation (brackets, colons) blue and dim
    if (tags.contains(LogTag.punctuation)) {
      return const LogStyle(color: LogColor.blue, dim: true);
    }
    // Make JSON values (strings/nums) cyan
    if (tags.contains(LogTag.value)) {
      return const LogStyle(color: LogColor.cyan);
    }
    // Keep borders dim blue
    if (tags.contains(LogTag.border)) {
      return const LogStyle(color: LogColor.blue, dim: true);
    }
    return super.getStyle(level, tags);
  }
}
