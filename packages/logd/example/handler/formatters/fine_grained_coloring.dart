// Example: Fine-Grained Coloring & Custom Themes
//
// Purpose:
// Demonstrates how to use semantic tagging and StyleDecorator to achieve
// high-fidelity visual styling in the terminal.

import 'package:logd/logd.dart';

void main() async {
  print('=== Logd / Fine-Grained Coloring & Custom Themes ===\n');

  // ---------------------------------------------------------------------------
  // SCENARIO: The "Profound Console"
  // Goal: Use a custom theme to highlight specific log elements (timestamps, logger names).
  // ---------------------------------------------------------------------------
  print('=== Logd / Plain Formatter Fine Grained Coloring Benchmark ===\n');
  final plainHandler = Handler(
    formatter: const PlainFormatter(
      metadata: {
        LogMetadata.timestamp,
        LogMetadata.logger,
      },
    ),
    decorators: [
      BoxDecorator(borderStyle: BorderStyle.rounded),
      StyleDecorator(theme: _ProfoundConsoleTheme()),
    ],
    sink: const ConsoleSink(lineLength: 75),
  );

  Logger.configure('plain.console', handlers: [plainHandler]);

  Logger.get('plain.console.core')
    ..info('System core initialized. Environment: Sandbox-Alpha.')
    ..debug('Verifying cryptographic checksums for module "Kernel"...')
    ..warning('Throughput approaching 10k req/s. Auto-scaling pending.')
    ..error(
      'Authentication Fault!',
      error: 'ChecksumMismatch: Expected 0xAF43, found 0x0000.',
    );

  print('\n=== Logd / Plain Formatter Fine Grained Coloring Benchmark Complete ===\n');

  const structuredHandler = Handler(
    formatter: StructuredFormatter(),
    decorators: [
      BoxDecorator(borderStyle: BorderStyle.rounded),
      StyleDecorator(theme: _ProfoundConsoleTheme()),
    ],
    sink: ConsoleSink(
      lineLength: 75,
    ),
  );

  Logger.configure('structured.console', handlers: [structuredHandler]);
  final log = Logger.get('structured.console');

  print(
      '=== Logd / Structured Formatter Fine Grained Coloring Benchmark ===\n');

  log
    ..info('System core initialized. Environment: Sandbox-Alpha.')
    ..debug('Verifying cryptographic checksums for module "Kernel"...')
    ..warning('Throughput approaching 10k req/s. Auto-scaling pending.')
    ..error(
      'Authentication Fault!',
      error: 'ChecksumMismatch: Expected 0xAF43, found 0x0000.',
    );

  print(
      '\n=== Structured Formatter Fine Grained Coloring Benchmark Complete ===');
}

/// A custom theme that overrides specific semantic colors.
class _ProfoundConsoleTheme extends LogTheme {
  const _ProfoundConsoleTheme()
      : super(colorScheme: LogColorScheme.defaultScheme);

  @override
  LogStyle getStyle(final LogLevel level, final int tags) {
    if (((tags & LogTag.timestamp) != 0)) {
      return const LogStyle(color: LogColor.blue, dim: true);
    }
    if (((tags & LogTag.loggerName) != 0)) {
      return const LogStyle(color: LogColor.magenta, bold: true);
    }

    switch (level) {
      case LogLevel.info:
        if (((tags & LogTag.level) != 0)) {
          return const LogStyle(color: LogColor.green, bold: true);
        }
        break;
      case LogLevel.warning:
        if (((tags & LogTag.level) != 0)) {
          return const LogStyle(color: LogColor.yellow, italic: true);
        }
        break;
      case LogLevel.error:
        if (((tags & LogTag.level) != 0)) {
          return const LogStyle(
            backgroundColor: LogColor.red,
            color: LogColor.white,
            bold: true,
          );
        }
        break;
      default:
        break;
    }

    return super.getStyle(level, tags);
  }
}
