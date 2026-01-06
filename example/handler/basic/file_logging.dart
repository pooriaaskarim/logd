// Example: File Logging
//
// Demonstrates:
// - FileSink configuration
// - PlainFormatter for file output
// - File rotation
//
// Expected: Logs written to file with rotation support

import 'package:logd/logd.dart';

void main() async {
  // Configure file handler with rotation
  final fileHandler = Handler(
    formatter: const PlainFormatter(),
    sink: FileSink(
      'logs/example.log',
      fileRotation: SizeRotation(maxSize: '1 KB', backupCount: 3),
    ),
  );

  Logger.configure(
    'example.file',
    handlers: [fileHandler],
    logLevel: LogLevel.debug,
  );

  final logger = Logger.get('example.file');

  // Generate enough logs to trigger rotation
  for (int i = 0; i < 50; i++) {
    logger.info(
        'Log entry $i: This is a test message that will fill up the file');
  }

  print('Check logs/example.log for output');
  print('If file exceeded 1KB, check for rotated files');
}
