import 'package:logd/logd.dart';

/// Example demonstrating fine-grained tag-specific coloring with StructuredFormatter.
///
/// The enhanced StructuredFormatter now emits separate LogSegments for:
/// - Logger name (LogTag.loggerName)
/// - Level indicator (LogTag.level)
/// - Timestamp (LogTag.timestamp)
///
/// This allows ColorScheme to apply different colors to each part.
void main() {
  // Configure logger with tag-specific coloring
  Logger.configure(
    'app',
    handlers: [
      Handler(
        formatter: const StructuredFormatter(),
        decorators: [
          BoxDecorator(
            borderStyle: BorderStyle.rounded,
          ),
          ColorDecorator(
            colorScheme: ColorScheme(
              trace: LogColor.green,
              debug: LogColor.white,
              info: LogColor.blue,
              warning: LogColor.yellow,
              error: LogColor.red,
              // Tag-specific color overrides
              timestampColor: LogColor.brightBlack, // Dimmed timestamps
              loggerNameColor: LogColor.cyan, // Cyan logger names
              levelColor: LogColor.brightBlue, // Bright blue level indicators
            ),
            config: ColorConfig.all,
          ),
        ],
        sink: const ConsoleSink(),
      ),
    ],
  );

  final logger = Logger.get('app');

  print('=== Fine-Grained Coloring Demo ===\n');

  logger.debug('Application initialized');
  logger.info('Server listening on port 8080');
  logger.warning('High memory usage detected: 85%');
  logger.error('Failed to connect to database');

  print('''

Tag-specific colors applied:
- Logger name ([app]): Cyan
- Level indicator ([INFO]): Bright Blue (bold)
- Timestamp: Bright Black (dimmed)
- Borders: Bright Black (dimmed)
- Message content: Base level color
''');
}
