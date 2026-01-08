import 'package:logd/logd.dart';

/// Example demonstrating MarkdownFormatter for generating GitHub-Flavored Markdown logs.
///
/// This creates markdown output suitable for:
/// - GitHub/GitLab issues
/// - Documentation
/// - Knowledge bases (Obsidian, Notion, etc.)
void main() {
  // Configure logger with Markdown output
  Logger.configure(
    'app',
    handlers: [
      Handler(
        formatter: const MarkdownFormatter(
          useCodeBlocks: true,
          headingLevel: 3,
        ),
        sink: FileSink('logs/example.md'),
      ),
    ],
  );

  final logger = Logger.get('app');

  print('=== MarkdownFormatter Demo ===\n');
  print('Writing logs to logs/example.md...\n');

  // Generate various log entries
  logger.trace('Entering main function');
  logger.debug('Configuration loaded from config.yaml');
  logger.info('Server started on port 8080');
  logger.warning('High memory usage detected: 85%');
  logger.error('Database connection failed');

  print('''
Markdown log file created successfully!

The markdown output includes:
- Emoji icons for log levels (🔍 trace, 🐛 debug, ℹ️ info, ⚠️ warning, ❌ error)
- Metadata tables with timestamp and origin
- Code blocks for messages (syntax highlighting ready)
- Proper formatting for errors and stack traces
- Horizontal rules between entries

Use cases:
1. **GitHub Issues**: Attach logs as markdown for readability
2. **Documentation**: Embed logs in documentation systems
3. **Knowledge Bases**: Import into Obsidian, Notion, etc.
4. **Team Communication**: Share formatted logs in Slack/Discord

View the file: logs/example.md
''');
}
