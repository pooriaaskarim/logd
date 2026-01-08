import 'package:logd/logd.dart';

/// Example demonstrating JsonSemanticFormatter with tag preservation.
///
/// JsonSemanticFormatter outputs JSON that includes semantic tag information
/// for each field, enabling downstream systems to render or analyze logs
/// with knowledge of the semantic meaning of each part.
void main() {
  // Configure logger with semantic JSON formatter
  Logger.configure(
    'app',
    handlers: [
      const Handler(
        formatter: JsonSemanticFormatter(prettyPrint: true),
        sink: ConsoleSink(),
      ),
    ],
  );

  final logger = Logger.get('app');

  print('=== JsonSemanticFormatter Demo ===\n');

  logger.info('Server started on port 8080');
  logger.warning('High memory usage detected');
  logger.error('Database connection failed');

  print('''

Output includes semantic tags for each field:
- timestamp: ["header", "timestamp"]
- level: ["header", "level"]
- logger: ["header", "loggerName"]
- message: ["message"]
- error: ["error"]

This allows downstream systems to:
1. Apply different styling/colors based on tags
2. Filter or search by semantic meaning
3. Build analytics on specific log components
''');
}
