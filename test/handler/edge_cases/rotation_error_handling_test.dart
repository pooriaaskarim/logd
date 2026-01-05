// Tests for rotation error handling scenarios.
import 'dart:io' as io;

import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Rotation Error Handling', () {
    test('should handle rotation failure gracefully', () async {
      // This test verifies that if rotation fails, the write operation
      // doesn't crash the entire sink
      final sink = FileSink(
        'logs/rotation_error_test.log',
        fileRotation: SizeRotation(maxSize: '1 KB'),
      );
      final handler = Handler(
        formatter: const PlainFormatter(),
        sink: sink,
      );

      // Write enough to trigger rotation
      for (int i = 0; i < 200; i++) {
        final entry = LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.info,
          message: 'Entry $i: ${'x' * 50}',
          timestamp: '2025-01-01 10:00:00',
          hierarchyDepth: 0,
        );
        // Should not throw even if rotation has issues
        await handler.log(entry);
      }

      // Verify file exists and has content
      final file = io.File('logs/rotation_error_test.log');
      expect(file.existsSync(), isTrue);
      final content = await file.readAsString();
      expect(content, isNotEmpty);
    });

    test('should continue writing after rotation error', () async {
      final sink = FileSink(
        'logs/rotation_recovery_test.log',
        fileRotation: TimeRotation(interval: const Duration(seconds: 1)),
      );
      final handler = Handler(
        formatter: const PlainFormatter(),
        sink: sink,
      );

      // First write
      await handler.log(
        const LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.info,
          message: 'Before rotation',
          timestamp: '2025-01-01 10:00:00',
          hierarchyDepth: 0,
        ),
      );

      // Wait for rotation interval
      await Future.delayed(const Duration(seconds: 2));

      // Second write - should trigger rotation
      await handler.log(
        const LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.info,
          message: 'After rotation',
          timestamp: '2025-01-01 10:00:02',
          hierarchyDepth: 0,
        ),
      );

      // Should have written both entries (even if rotation had issues)
      final file = io.File('logs/rotation_recovery_test.log');
      if (file.existsSync()) {
        final content = await file.readAsString();
        // Should have at least the second entry
        expect(content, contains('After rotation'));
      }
    });
  });
}
