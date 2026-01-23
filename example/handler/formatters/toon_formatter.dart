import 'package:logd/logd.dart';

void main() async {
  print('--- TOON Formatter Example ---\n');

  // Example 1: Standard TOON (best for LLMs)
  // - Tab delimited (default)
  // - Minimal quoting
  // - No color tags
  final llmHandler = Handler(
    formatter: ToonFormatter(), // Default: keys=std, delimiter=TAB
    sink: ConsoleSink(),
  );

  print('Scenario 1: Feeding to an LLM (Standard)');
  // Configure 'llm_feed' logger
  Logger.configure('llm_feed', handlers: [llmHandler]);
  final llmLogger = Logger.get('llm_feed');

  llmLogger.info('User logged in');
  llmLogger.warning('Database high latency: "db_primary"');
  llmLogger.error(
    'Transaction failed',
    error: 'ConnectionTimeout',
    stackTrace: StackTrace.current,
  );

  print('\n------------------------------------------------\n');

  // Example 2: Colorized TOON (for human debugging)
  // - Comma delimited
  // - Colorized tags enabled
  // - Processed by StyleDecorator
  final debugHandler = Handler(
    formatter: ToonFormatter(
      delimiter: ', ', // Readable usage
      keys: [LogField.timestamp, LogField.level, LogField.message],
      colorize: true, // Enable tags for styling
    ),
    decorators: [
      StyleDecorator(
        theme: LogTheme(
          colorScheme: LogColorScheme.defaultScheme,
          // Custom style for TOON punctuation
          hierarchyStyle: const LogStyle(color: LogColor.brightBlack),
        ),
      ),
    ],
    sink: ConsoleSink(),
  );

  print('Scenario 2: Debugging Context (Colorized)');
  // Configure 'debug_feed' logger
  Logger.configure('debug_feed', handlers: [debugHandler]);
  final debugLogger = Logger.get('debug_feed');

  debugLogger.trace('Loading configuration from env');
  debugLogger.info('System initialization started');
  debugLogger.debug('Database connection established');
  debugLogger.warning('Optional config missing');
  debugLogger.error('Fatal error occurred');
}
