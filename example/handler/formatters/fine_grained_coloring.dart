// Example: StructuredFormatter - Fine-Grained Semantic Styling
//
// Purpose:
// Demonstrates how to use semantic tagging (LogTag) to create a highly refined
// visual identity. We target specific parts of the log entry (Timestamp,
// LoggerName, Borders) with unique colors and font styles.
//
// Key Benchmarks:
// 1. Semantic Tagging (Unique colors per metadata type)
// 2. Structural Framing (Rounded box with dimmed borders)
// 3. Status Inversion (High-impact level indicators)

import 'package:logd/logd.dart';

void main() {
  // ---------------------------------------------------------------------------
  // THE "VISUAL CONSOLE" HANDLER
  // Goal: Maximize semantic clarity using the Styles engine.
  // ---------------------------------------------------------------------------
  final visualHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      BoxDecorator(borderStyle: BorderStyle.rounded),
      const StyleDecorator(theme: _ProfoundConsoleTheme()),
    ],
    sink: const ConsoleSink(),
    lineLength: 75,
  );

  Logger.configure('visual.console', handlers: [visualHandler]);
  final log = Logger.get('visual.console');

  print('=== Logd / Fine-Grained Styling Benchmark ===\n');

  log.info('System core initialized. Environment: Sandbox-Alpha.');

  log.debug('Verifying cryptographic checksums for module "Kernel"...');

  log.warning('Throughput approaching 10k req/s. Auto-scaling pending.');

  log.error('Authentication Fault!',
      error: 'ChecksumMismatch: Expected 0xAF43, found 0x0000.');

  print('\n=== Visual Styling Benchmark Complete ===');
}

/// A "Profound" theme that targets every LogTag with a specific visual intent.
class _ProfoundConsoleTheme extends LogTheme {
  const _ProfoundConsoleTheme() : super(colorScheme: LogColorScheme.darkScheme);

  @override
  LogStyle getStyle(final LogLevel level, final Set<LogTag> tags) {
    // 1. Headers: Bold Yellow (Context focus)
    if (tags.contains(LogTag.header) && !tags.contains(LogTag.level)) {
      return const LogStyle(color: LogColor.yellow, bold: true);
    }

    // 2. Timestamps: Dimmed White (Background data)
    if (tags.contains(LogTag.timestamp)) {
      return const LogStyle(color: LogColor.white, dim: true);
    }

    // 3. Logger Names: Bold Magenta (Identity focus)
    if (tags.contains(LogTag.loggerName)) {
      return const LogStyle(color: LogColor.magenta, bold: true);
    }

    // 4. Borders: Dimmed Blue (Structural separation)
    if (tags.contains(LogTag.border)) {
      return const LogStyle(color: LogColor.blue, dim: true);
    }

    // 5. Level Status: Inverted bold (Status focus)
    if (tags.contains(LogTag.level)) {
      return LogStyle(color: _levelColor(level), inverse: true, bold: true);
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
