import 'dart:io' as io;
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group('Sink & File Rotation Safety', () {
    late String testLogPath;

    setUp(() {
      testLogPath =
          'logs/sink_safety_test_${DateTime.now().millisecondsSinceEpoch}.log';
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
      // Also clean up potential rotated files
      final dir = io.Directory('logs');
      if (dir.existsSync()) {
        dir.listSync().forEach((final e) {
          if (e.path.contains('sink_safety_test_')) {
            e.deleteSync();
          }
        });
      }
    });

    test('rapid concurrent logging completes without data loss', () async {
      final sink = FileSink(testLogPath);
      final handlers = List.generate(
        3,
        (final i) => Handler(
          formatter: const PlainFormatter(),
          sink: sink,
        ),
      );

      final futures = <Future>[];
      for (int i = 0; i < 50; i++) {
        for (var h in handlers) {
          futures.add(
            h.log(
              LogEntry(
                loggerName: 'test',
                origin: 'test',
                level: LogLevel.info,
                message: 'Entry $i',
                timestamp: '2025-01-01 10:00:00',
              ),
            ),
          );
        }
      }

      await Future.wait(futures);
      await Future.delayed(const Duration(milliseconds: 100));

      final file = io.File(testLogPath);
      final lines = await file.readAsLines();
      expect(lines.length, equals(150));
    });

    test('rotation triggers correctly under rapid load', () async {
      final sink = FileSink(
        testLogPath,
        fileRotation: SizeRotation(maxSize: '10 KB', backupCount: 2),
      );
      final handler = Handler(formatter: const PlainFormatter(), sink: sink);

      final futures = <Future>[];
      for (int i = 0; i < 200; i++) {
        futures.add(
          handler.log(
            LogEntry(
              loggerName: 'test',
              origin: 'test',
              level: LogLevel.info,
              message: 'Entry $i: ${'x' * 100}',
              timestamp: '2025-01-01 10:00:00',
            ),
          ),
        );
      }

      await Future.wait(futures);
      await Future.delayed(const Duration(milliseconds: 200));

      final rotated = io.Directory('logs')
          .listSync()
          .whereType<io.File>()
          .where((final f) => f.path.contains(testLogPath))
          .toList();

      expect(rotated.length, greaterThanOrEqualTo(1));
    });

    test('recovery after simulated rotation interval (regression)', () async {
      final sink = FileSink(
        testLogPath,
        fileRotation: TimeRotation(interval: const Duration(milliseconds: 100)),
      );
      final handler = Handler(formatter: const PlainFormatter(), sink: sink);

      await handler.log(
        const LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.info,
          message: 'First',
          timestamp: '10:00:00',
        ),
      );

      await Future.delayed(const Duration(milliseconds: 200));

      await handler.log(
        const LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.info,
          message: 'Second',
          timestamp: '10:00:02',
        ),
      );

      final content = await io.File(testLogPath).readAsString();
      expect(content, contains('Second'));
    });
  });
}
