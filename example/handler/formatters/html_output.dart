import 'package:logd/logd.dart';

/// Example demonstrating HTMLFormatter and HTMLSink for generating styled HTML logs.
///
/// This creates a complete HTML document with embedded CSS that can be opened
/// in a browser for viewing formatted logs.
void main() async {
  // Create HTML sink
  final htmlSink = HTMLSink(
    filePath: 'logs/example.html',
    darkMode: true, // Use dark mode styling
  );

  // Configure logger with HTML output
  Logger.configure(
    'app',
    handlers: [
      Handler(
        formatter: const HTMLFormatter(),
        sink: htmlSink,
      ),
    ],
  );

  final logger = Logger.get('app');

  print('=== HTMLFormatter Demo ===\n');
  print('Writing logs to logs/example.html...\n');

  // Generate various log entries
  logger.trace('Application initialization started');
  logger.debug('Loading configuration from config.yaml');
  logger.info('Server started on port 8080');
  logger.warning('High memory usage detected: 85%');
  logger.error('Database connection failed');

  // IMPORTANT: Close the sink to write the HTML footer
  await htmlSink.close();

  print('''
HTML log file created successfully!

To view the logs:
1. Open logs/example.html in your web browser
2. Logs are styled with:
   - Dark mode theme
   - Color-coded log levels
   - Readable monospace font
   - Structured layout

The HTML file includes:
- Embedded CSS for styling
- Semantic HTML markup
- Level-based color coding
- Proper escaping of HTML characters
''');
}
