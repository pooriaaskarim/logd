// Test to reproduce TimeRotation bug.
import 'dart:io' as io;

import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('TimeRotation Bug Reproduction', () {
    late String testLogPath;

    setUp(() {
      testLogPath =
          'logs/test_time_rotation_${DateTime.now().millisecondsSinceEpoch}.log';
      final file = io.File(testLogPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    tearDown(() {
      final file = io.File(testLogPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      // Clean up rotated files
      final dir = file.parent;
      if (dir.existsSync()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is io.File &&
              entity.path.startsWith(
                testLogPath.replaceAll('.log', ''),
              )) {
            entity.deleteSync();
          }
        }
      }
    });

    test('TimeRotation should rotate after interval', () async {
      // Create TimeRotation with 5 second interval
      final rotation = TimeRotation(interval: const Duration(seconds: 5));
      final sink = FileSink(testLogPath, fileRotation: rotation);
      final handler = Handler(
        formatter: const PlainFormatter(),
        sink: sink,
      );

      const entry1 = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'First log at T0',
        timestamp: '2025-01-01 10:00:00',
        hierarchyDepth: 0,
      );

      // First log - should create file
      await handler.log(entry1);
      await Future.delayed(const Duration(milliseconds: 100));

      final file = io.File(testLogPath);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'File should exist after first log',
      );
      final initialContent = await file.readAsString();
      expect(initialContent, contains('First log at T0'));

      // Wait 6 seconds (more than interval)
      await Future.delayed(const Duration(seconds: 6));

      const entry2 = LogEntry(
        loggerName: 'test',
        origin: 'test',
        level: LogLevel.info,
        message: 'Second log after interval',
        timestamp: '2025-01-01 10:00:06',
        hierarchyDepth: 0,
      );

      // Second log - should trigger rotation
      await handler.log(entry2);
      await Future.delayed(const Duration(milliseconds: 200));

      // Current file should only have second log
      final currentContent = await file.readAsString();
      expect(currentContent, contains('Second log after interval'));
      expect(currentContent, isNot(contains('First log at T0')));

      // Rotated file should exist with first log
      final dir = file.parent;
      final rotatedFiles = <io.File>[];
      if (dir.existsSync()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is io.File &&
              entity.path != testLogPath &&
              entity.path.contains(testLogPath.replaceAll('.log', ''))) {
            rotatedFiles.add(entity);
          }
        }
      }

      expect(rotatedFiles, isNotEmpty, reason: 'Rotated file should exist');
      final rotatedContent = await rotatedFiles.first.readAsString();
      expect(rotatedContent, contains('First log at T0'));
    });
  });
}
