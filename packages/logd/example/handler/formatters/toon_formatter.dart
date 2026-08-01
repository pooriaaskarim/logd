// Example: ToonFormatter - Real-World Machine & Pipeline Showcase
//
// Purpose:
// Demonstrates ToonFormatter configured for real-world machine consumption,
// including LLM prompt streams, DuckDB strict ingestion, and recursive depth control.

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / TOON Formatter Showcase ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO A: Compact Machine Stream (LLM Context & Prompt Injection)
  // Goal: Maximum token efficiency for machine parsers or LLM context windows.
  // ---------------------------------------------------------------------------
  const compactHandler = Handler(
    formatter: ToonFormatter(
      metadata: {LogMetadata.timestamp},
      dialect: ToonDialect.compact,
    ),
    sink: ConsoleSink(encoder: ToonEncoder(), lineLength: 120),
  );

  // ---------------------------------------------------------------------------
  // SCENARIO B: Strict Data Pipeline Ingestion (DuckDB, Loki, awk)
  // Goal: Unambiguous nulls (\N) and version headers (-- TOON/1.0).
  // ---------------------------------------------------------------------------
  const strictHandler = Handler(
    formatter: ToonFormatter(
      dialect: ToonDialect.strict,
      metadata: {LogMetadata.timestamp, LogMetadata.logger},
    ),
    sink: ConsoleSink(encoder: ToonEncoder(), lineLength: 120),
  );

  // ---------------------------------------------------------------------------
  // SCENARIO C: Structural Recursion Controls (sortKeys + maxDepth)
  // Goal: Deterministic map sorting and bounded recursion depth.
  // ---------------------------------------------------------------------------
  const auditHandler = Handler(
    formatter: ToonFormatter(
      sortKeys: true,
      maxDepth: 2,
      metadata: {LogMetadata.timestamp},
    ),
    sink: ConsoleSink(encoder: ToonEncoder(), lineLength: 100),
  );

  // ---------------------------------------------------------------------------
  // SCENARIO D: Typed Schema (Explicit Type Hints)
  // Goal: Zero-shot type guidance for LLMs and schema validation.
  // ---------------------------------------------------------------------------
  const typedHandler = Handler(
    formatter: ToonFormatter(
      explicitSchema: true,
      metadata: {LogMetadata.timestamp, LogMetadata.origin},
    ),
    sink: ConsoleSink(encoder: ToonEncoder(), lineLength: 120),
  );

  // Configure Loggers
  Logger.configure('toon.compact', handlers: [compactHandler]);
  Logger.configure('toon.strict', handlers: [strictHandler]);
  Logger.configure('toon.audit', handlers: [auditHandler]);
  Logger.configure('toon.typed', handlers: [typedHandler]);

  final sampleData = {
    'system': 'Alpha-7',
    'status': 'degraded',
    'sensors': {'temp': 120, 'load': 0.85, 'pressure': 1013},
    'tags': ['active', 'critical', 'thermal-alert'],
  };

  print('TEST A: Compact TOON (LLM Context)');
  Logger.get('toon.compact.io').info('Telemetry Sync', error: sampleData);

  print('\n${'-' * 40}\n');

  print('TEST B: Strict Dialect (DuckDB / Pipeline Ingestion with \\N nulls)');
  final strictLogger = Logger.get('toon.strict.ingest');
  strictLogger.info('Service boot sequence initiated.');
  strictLogger.warning('Coil heat spike', error: sampleData);

  print('\n${'-' * 40}\n');

  print('TEST C: Structural Control (sortKeys: true, maxDepth: 2)');
  Logger.get('toon.audit').error(
    'Critical breach in nested subsystems!',
    error: {
      'primary': 'breached',
      'secondary': {
        'pumps': {'p1': 'offline', 'p2': 'nominal'},
        'coolant': 'low',
      },
      'tertiary': 'clamped_by_depth',
    },
  );

  print('\n${'-' * 40}\n');

  print('TEST D: Explicit Schema (Typed Headers)');
  Logger.get('toon.typed').info('System initialized with explicit schema.');

  print('\n=== TOON Showcase Complete ===');
}
