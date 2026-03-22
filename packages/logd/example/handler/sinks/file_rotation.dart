// Example: File Rotation
//
// Demonstrates:
// - Size-based rotation
// - Time-based rotation
// - Compression
// - Backup management
//
// Expected: Files rotate correctly with backups

import 'package:logd/logd.dart';

/// This example demonstrates how to use `FileSink` with `FileRotation`.
///
/// Logd supports two types of rotation:
/// 1. `SizeRotation`: Rotates files when they reach a certain size.
/// 2. `TimeRotation`: Rotates files based on time intervals (daily, hourly, etc.).
void main() async {
  // Size-based rotation
  final sizeRotationHandler = Handler(
    formatter: const PlainFormatter(),
    sink: FileSink(
      'logs/size_rotation.log',
      fileRotation: SizeRotation(
        maxSize: '1 KB',
        backupCount: 3,
        compress: false,
      ),
    ),
  );

  // Time-based rotation (daily)
  final timeRotationHandler = Handler(
    formatter: const PlainFormatter(),
    sink: FileSink(
      'logs/time_rotation.log',
      fileRotation: TimeRotation(
        interval: const Duration(seconds: 5), // Short for demo
        backupCount: 5,
        // compress: true,
      ),
    ),
  );

  Logger.configure('example.size', handlers: [sizeRotationHandler]);
  Logger.configure('example.time', handlers: [timeRotationHandler]);

  final sizeLogger = Logger.get('example.size');
  final timeLogger = Logger.get('example.time');

  print('=== Size-Based Rotation ===');
  // Generate enough logs to trigger rotation
  for (int i = 0; i < 100; i++) {
    sizeLogger.info('Size rotation test message $i: ${'x' * 50}');
  }

  print('\n=== Time-Based Rotation ===');
  timeLogger.info('Time rotation test - this will rotate every 5 seconds');
  await Future.delayed(const Duration(seconds: 6));
  timeLogger.info('After delay - should be in new file');

  print('\nCheck logs/ directory for rotated files');
}
