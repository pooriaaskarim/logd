// Example: Advanced Decorator Ensembles & Global Orchestration
//
// Purpose:
// Demonstrates logd's "Composition over Configuration" philosophy by creating
// distinct, complex logging pipelines for real-world scenarios.
//
// Scenarios:
// 1. Service Orchestrator: Human-readable, structured, boxed, and styled for
// terminal dashboards.
// 2. Security Audit: JSON output for machine ingestion, tagged with strict
// suffixes.
// 3. Raw Debug Stream: Unboxed, high-speed TOON format for grep/regex analysis.

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / Advanced Decorator Composition ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO 1: The Service Orchestrator
  // Goal: Beautiful, highly visible dashboard logs.
  // Composition:
  //   StructuredFormatter -> Prefix -> Box -> Hierarchy -> Style
  // ---------------------------------------------------------------------------
  const dashboardHandler = Handler(
    formatter: StructuredFormatter(),
    decorators: [
      // Content Decoration
      PrefixDecorator(' [SVC] '),

      // Structural Decoration (Inner)
      BoxDecorator(borderStyle: BorderStyle.rounded),

      // Structural Decoration (Outer)
      HierarchyDepthPrefixDecorator(indent: '  '),

      // Visual Decoration
      StyleDecorator(
        theme: LogTheme(
          colorScheme: LogColorScheme.pastelScheme,
        ),
      ),
    ],
    sink: ConsoleSink(lineLength: 70),
  );

  Logger.configure('orchestrator', handlers: [dashboardHandler]);
  await _simulateMicroservice();

  print('\n${'=' * 60}\n');

  // ---------------------------------------------------------------------------
  // SCENARIO 2: The Security Audit Trail
  // Goal: Machine-parseable JSON, guaranteed integrity suffix.
  // Composition:
  //   JsonFormatter -> Suffix -> Box (Sharp borders for serious look)
  // ---------------------------------------------------------------------------
  const auditHandler = Handler(
    formatter: JsonFormatter(),
    decorators: [
      // Tag every line to ensure if file is concatenated, boundaries are clear
      SuffixDecorator(' <AUDIT-END>', aligned: true),
      BoxDecorator(borderStyle: BorderStyle.sharp),
    ],
    sink: ConsoleSink(lineLength: 60),
  );

  Logger.configure('auth.service', handlers: [auditHandler]);
  print('--- Security Audit Trail (JSON) ---');
  Logger.get('auth.service').warning(
    'User authentication failed',
    error: 'Invalid credentials',
  );

  print('\n${'=' * 60}\n');

  // ---------------------------------------------------------------------------
  // SCENARIO 3: The machine-readable Stream
  // Goal: High-density, grep-friendly output (TOON format).
  // Composition:
  //   ToonFormatter -> Prefix (Machine ID)
  // ---------------------------------------------------------------------------
  const debugHandler = Handler(
    formatter: ToonFormatter(),
    decorators: [
      PrefixDecorator('worker-01|'),
    ],
    sink: ConsoleSink(),
  );

  Logger.configure('worker', handlers: [debugHandler]);
  print('--- Worker Debug Stream (TOON) ---');
  Logger.get('worker').debug('Processing batch #402');

  print('\n=== Advanced Composition Complete ===');
}

Future<void> _simulateMicroservice() async {
  print('--- Service Orchestrator (Dashboard Style) ---');

  // Root level
  Logger.get('orchestrator').info('System Initialization');

  // Depth 1: Subsystem
  Logger.get('orchestrator.gateway')
    ..info('Booting Gateway...')
    ..info('Gateway Ready on :8080');

  // Depth 1: Database
  Logger.get('orchestrator.database').info('Connecting to Postgres...');

  // Depth 2: DB Details
  Logger.get('orchestrator.database.migrations')
    ..info('Applying Migrations [12/12]')
    ..info('Indexing "users" table');

  // Back to Root
  Logger.get('orchestrator').info('All Systems Go.');
}
