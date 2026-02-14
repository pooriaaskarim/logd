// Example: ToonFormatter - Exhaustive Combinatorial Stress Matrix
//
// Purpose:
// Demonstrates the ToonFormatter's character-based personality under
// extreme structural pressure. We combine Toon layouts with Boxes,
// Hierarchy Indentation, ANSI Styling, and narrow terminal limits.
//
// Key Benchmarks:
// 1. Comic Relay (Toon + Style + Deep Hierarchy)
// 2. Toon Boxed (Toon + Rounded Box + 40 Width + Custom Tag Style)

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / ToonFormatter: Extreme Combinations ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO A: The "Comic Relay"
  // Goal: Demonstrate multi-level narrative indentation with toon characters.
  // ---------------------------------------------------------------------------
  const relayHandler = Handler(
    formatter: ToonFormatter(
      metadata: {LogMetadata.logger},
    ),
    decorators: [
      StyleDecorator(
        theme: LogTheme(colorScheme: LogColorScheme.pastelScheme),
      ),
      HierarchyDepthPrefixDecorator(indent: '┃ '),
      SuffixDecorator(' [v8]', aligned: true),
    ],
    sink: ConsoleSink(),
    lineLength: 75,
  );

  // ---------------------------------------------------------------------------
  // SCENARIO B: "Toon Boxed" (The Action Panel)
  // Goal: The ultimate layout stress test. We force a complex character layout
  // (Toon) inside a Rounded Box at an aggressively narrow 40-char width.
  // ---------------------------------------------------------------------------
  const panelHandler = Handler(
    formatter: ToonFormatter(
      metadata: {LogMetadata.timestamp, LogMetadata.logger},
      multiline: true, // Allow real newlines for high-detail visuals
    ),
    decorators: [
      StyleDecorator(theme: _ToonPanelTheme()),
      BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: ConsoleSink(),
    lineLength: 40, // Aggressively narrow for Toon + Box
  );

  // Configure Global Loggers
  Logger.configure('relay.narration', handlers: [relayHandler]);
  Logger.configure('panel.alert', handlers: [panelHandler]);

  // --- Run Scenario A: Comic Relay ---
  print('TEST A: Comic Relay (Style + Deep Hierarchy)');
  Logger.get('relay.narration').info('Chapter 1: The Server Awakens.');

  Logger.get('relay.narration.engine.v8')
    ..debug('JIT compiler warming up: optimization level 4.')
    ..warning('Speculative execution threshold reached (80%).');
  print('〰' * 40);

  // --- Run Scenario B: Toon Boxed ---
  print('\nTEST B: Toon Boxed (Action Panel: Box + Style + 40 Width)');
  final alert = Logger.get('panel.alert')
    ..info('Establishing secure uplink to cluster-primary-alpha.');

  try {
    _detonate();
  } catch (e, s) {
    alert.error('CAPSULE BREACHED!', error: e, stackTrace: s);
  }

  print('\n=== Toon Combinatorial Matrix Complete ===');
}

void _detonate() {
  throw StateError('Simulated reactor meltdown in test environment.');
}

/// A custom theme for the Action Panel to make the Level and Borders pop.
class _ToonPanelTheme extends LogTheme {
  const _ToonPanelTheme() : super(colorScheme: LogColorScheme.darkScheme);

  @override
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    // Make Toon borders/frames bright white for the "Action" feel
    if (tags.contains(LogTag.border)) {
      return const LogStyle(color: LogColor.white, bold: true);
    }
    // Make levels inverse for high-impact status
    if (tags.contains(LogTag.level)) {
      return LogStyle(color: _levelColor(level), bold: true, inverse: true);
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
