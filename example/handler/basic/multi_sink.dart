// Example: Multi-Sink Logging
//
// Demonstrates:
// - MultiSink to output to multiple destinations
// - Different formatters for different sinks
// - Console + File simultaneously
//
// Expected: Logs appear in both console and file

import 'package:logd/logd.dart';

void main() async {
  // Create a multi-sink handler
  final multiHandler = Handler(
    formatter: const StructuredFormatter(),
    sink: MultiSink([
      const ConsoleSink(), // Console with structured format
      FileSink(
        'logs/multi_sink.log',
        fileRotation: SizeRotation(maxSize: '10 KB'),
      ), // File with same format
    ]),
    lineLength: 80,
  );

  Logger.configure(
    'example.multi',
    handlers: [multiHandler],
    logLevel: LogLevel.info,
  );

  final logger = Logger.get('example.multi');

  logger.info('This message goes to both console and file');
  logger.warning('Warning messages also go to both');
  logger.error('Error messages are duplicated to both sinks');

  print('\nCheck logs/multi_sink.log to verify file output');
}
