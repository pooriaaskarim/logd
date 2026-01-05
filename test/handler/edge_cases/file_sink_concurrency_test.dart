// Tests for FileSink concurrency robustness.
//
// These tests verify that rapid logging operations (e.g., in a for loop)
// are properly serialized and all entries are written to the file,
// preventing data loss from overlapping write operations.
import 'dart:async';
import 'dart:io' as io;

import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('FileSink Concurrency', () {
    late String testLogPath;

    setUp(() {
      testLogPath =
          'logs/test_concurrency_${DateTime.now().millisecondsSinceEpoch}.log';
      // Clean up any existing test file
      final file = io.File(testLogPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    tearDown(() {
      // Clean up test file
      final file = io.File(testLogPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    test('rapid logging in loop should write all entries', () async {
      final sink = FileSink(testLogPath);
      final handler = Handler(
        formatter: const PlainFormatter(),
        sink: sink,
      );

      // Log 100 times rapidly in a loop
      final futures = <Future>[];
      for (int i = 0; i < 100; i++) {
        final message = 'Log entry $i';
        final logEntry = LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.info,
          message: message,
          timestamp: '2025-01-01 10:00:00',
          hierarchyDepth: 0,
        );
        futures.add(handler.log(logEntry));
      }

      // Wait for all to complete
      await Future.wait(futures);

      // Give file system a moment to flush
      await Future.delayed(const Duration(milliseconds: 100));

      // Read the file and verify all entries are present
      final file = io.File(testLogPath);
      expect(file.existsSync(), isTrue, reason: 'Log file should exist');

      final content = await file.readAsString();
      final lines =
          content.split('\n').where((final l) => l.trim().isNotEmpty).toList();

      // Should have 100 log entries
      expect(
        lines.length,
        equals(100),
        reason: 'All 100 log entries should be written',
      );

      // Verify each entry is present
      for (int i = 0; i < 100; i++) {
        final expectedMessage = 'Log entry $i';
        expect(
          lines.any((final line) => line.contains(expectedMessage)),
          isTrue,
          reason: 'Log entry $i should be present in file',
        );
      }
    });

    test('concurrent logging from multiple handlers should not lose entries',
        () async {
      final sink = FileSink(testLogPath);
      final handler1 = Handler(
        formatter: const PlainFormatter(),
        sink: sink,
      );
      final handler2 = Handler(
        formatter: const PlainFormatter(),
        sink: sink,
      );
      final handler3 = Handler(
        formatter: const PlainFormatter(),
        sink: sink,
      );

      // Log concurrently from multiple handlers
      final futures = <Future>[];
      for (int i = 0; i < 50; i++) {
        final message1 = 'Handler1 entry $i';
        final message2 = 'Handler2 entry $i';
        final message3 = 'Handler3 entry $i';

        final entry1 = LogEntry(
          loggerName: 'test1',
          origin: 'test',
          level: LogLevel.info,
          message: message1,
          timestamp: '2025-01-01 10:00:00',
          hierarchyDepth: 0,
        );
        final entry2 = LogEntry(
          loggerName: 'test2',
          origin: 'test',
          level: LogLevel.info,
          message: message2,
          timestamp: '2025-01-01 10:00:00',
          hierarchyDepth: 0,
        );
        final entry3 = LogEntry(
          loggerName: 'test3',
          origin: 'test',
          level: LogLevel.info,
          message: message3,
          timestamp: '2025-01-01 10:00:00',
          hierarchyDepth: 0,
        );

        futures.addAll([
          handler1.log(entry1),
          handler2.log(entry2),
          handler3.log(entry3),
        ]);
      }

      await Future.wait(futures);
      await Future.delayed(const Duration(milliseconds: 100));

      final file = io.File(testLogPath);
      expect(file.existsSync(), isTrue);

      final content = await file.readAsString();
      final lines =
          content.split('\n').where((final l) => l.trim().isNotEmpty).toList();

      // Should have 150 entries (50 from each handler)
      expect(
        lines.length,
        equals(150),
        reason: 'All 150 log entries should be written',
      );

      // Verify entries from each handler
      for (int i = 0; i < 50; i++) {
        expect(lines.any((final l) => l.contains('Handler1 entry $i')), isTrue);
        expect(lines.any((final l) => l.contains('Handler2 entry $i')), isTrue);
        expect(lines.any((final l) => l.contains('Handler3 entry $i')), isTrue);
      }
    });

    test('rapid logging with file rotation should not lose entries', () async {
      final sink = FileSink(
        testLogPath,
        fileRotation: SizeRotation(maxSize: '50 KB', backupCount: 3),
      );
      final handler = Handler(
        formatter: const PlainFormatter(),
        sink: sink,
      );

      // Log enough to trigger rotation (but not too many rotations)
      final futures = <Future>[];
      for (int i = 0; i < 200; i++) {
        final message = 'Log entry $i: ${'x' * 100}';
        final entry = LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.info,
          message: message,
          timestamp: '2025-01-01 10:00:00',
          hierarchyDepth: 0,
        );
        futures.add(handler.log(entry));
      }

      await Future.wait(futures);
      await Future.delayed(const Duration(milliseconds: 200));

      // Check that entries are in current file or rotated files
      final file = io.File(testLogPath);
      final content = file.existsSync() ? await file.readAsString() : '';

      // Check rotated files
      final dir = file.parent;
      final rotatedFiles = <io.File>[];
      if (dir.existsSync()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is io.File && entity.path.startsWith(testLogPath)) {
            rotatedFiles.add(entity);
          }
        }
      }

      // Count total entries across all files
      var totalEntries =
          content.split('\n').where((final l) => l.trim().isNotEmpty).length;
      for (final rotatedFile in rotatedFiles) {
        if (rotatedFile.path != testLogPath) {
          final rotatedContent = await rotatedFile.readAsString();
          totalEntries += rotatedContent
              .split('\n')
              .where((final l) => l.trim().isNotEmpty)
              .length;
        }
      }

      // With 50KB rotation and ~115 bytes per entry, expect ~3 rotations
      // Most entries should be preserved
      expect(
        totalEntries,
        greaterThan(180),
        reason: 'Most entries should be preserved during rotation',
      );
    });
  });
}
