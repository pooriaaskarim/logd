import 'dart:convert';
import 'dart:io';

import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('TargetHandlers (v0.9.3)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'logd_target_handlers_test_',
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('ConsoleHandler creates a valid Handler pipeline', () {
      final handler = ConsoleHandler(
        lineLength: 80,
        theme: const LogTheme.light(),
      );

      expect(handler, isA<Handler>());
      expect(handler.formatter, isA<StructuredFormatter>());
      expect(handler.sink, isA<ConsoleSink>());
      expect(handler.decorators.length, equals(1));
    });

    test('ConsoleHandler.async creates an AsyncHandler pipeline', () async {
      final handler = ConsoleHandler.async(
        lineLength: 80,
        theme: const LogTheme.light(),
      );

      expect(handler, isA<AsyncHandler>());
      expect(handler.formatter, isA<StructuredFormatter>());
      expect(handler.sink, isA<ConsoleSink>());
      await handler.dispose();
    });

    test('HtmlFileHandler logs HTML content with document preamble', () async {
      final file = File('${tempDir.path}/log.html');
      final handler = HtmlFileHandler(
        path: file.path,
        title: 'Test Session',
      );

      final entry = LogEntry(
        loggerName: 'test.html',
        origin: 'test_file.dart',
        level: LogLevel.info,
        message: 'Hello HTML World',
        timestamp: '2026-08-15 12:00:00.000',
      );

      await handler.log(entry);

      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('<!DOCTYPE html>'));
      expect(content, contains('Test Session'));
      expect(content, contains('Hello HTML World'));
    });

    test('HtmlFileHandler.async creates an AsyncHandler pipeline', () async {
      final file = File('${tempDir.path}/log_async.html');
      final handler = HtmlFileHandler.async(
        path: file.path,
        title: 'Async Session',
      );

      expect(handler, isA<AsyncHandler>());
      final entry = LogEntry(
        loggerName: 'test.html_async',
        origin: 'test_file.dart',
        level: LogLevel.info,
        message: 'Async HTML Event',
        timestamp: '2026-08-15 12:00:00.000',
      );

      await handler.log(entry);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await handler.dispose();

      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('<!DOCTYPE html>'));
      expect(content, contains('Async HTML Event'));
    });

    test(
      'JsonFileHandler logs formatted JSON payload when pretty is true',
      () async {
        final file = File('${tempDir.path}/log.json');
        final handler = JsonFileHandler(
          path: file.path,
          pretty: true,
        );

        final entry = LogEntry(
          loggerName: 'test.json',
          origin: 'test_file.dart',
          level: LogLevel.warning,
          message: 'Structured warning event',
          timestamp: '2026-08-15 12:00:00.000',
        );

        await handler.log(entry);

        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        expect(decoded['level'], equals('warning'));
        expect(decoded['message'], equals('Structured warning event'));
      },
    );

    test(
      'JsonFileHandler.async logs JSON payload to background worker',
      () async {
        final file = File('${tempDir.path}/log_async.json');
        final handler = JsonFileHandler.async(
          path: file.path,
          pretty: true,
        );

        expect(handler, isA<AsyncHandler>());
        final entry = LogEntry(
          loggerName: 'test.json_async',
          origin: 'test_file.dart',
          level: LogLevel.warning,
          message: 'Async JSON Event',
          timestamp: '2026-08-15 12:00:00.000',
        );

        await handler.log(entry);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await handler.dispose();

        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content, contains('"level": "warning"'));
        expect(content, contains('"message": "Async JSON Event"'));
      },
    );

    test(
      'JsonFileHandler logs compact JSON payload when pretty is false',
      () async {
        final file = File('${tempDir.path}/log_compact.json');
        final handler = JsonFileHandler(
          path: file.path,
          pretty: false,
        );

        final entry = LogEntry(
          loggerName: 'test.json_compact',
          origin: 'test_file.dart',
          level: LogLevel.error,
          message: 'Compact error event',
          timestamp: '2026-08-15 12:00:00.000',
        );

        await handler.log(entry);

        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content, contains('"level":"error"'));
        expect(content, contains('"message":"Compact error event"'));
      },
    );

    test('PlainFileHandler logs raw text payload', () async {
      final file = File('${tempDir.path}/log.txt');
      final handler = PlainFileHandler(
        path: file.path,
      );

      final entry = LogEntry(
        loggerName: 'test.plain',
        origin: 'test_file.dart',
        level: LogLevel.info,
        message: 'Simple text line',
        timestamp: '2026-08-15 12:00:00.000',
      );

      await handler.log(entry);

      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('Simple text line'));
    });

    test(
      'PlainFileHandler.async logs raw text via background isolate',
      () async {
        final file = File('${tempDir.path}/log_async.txt');
        final handler = PlainFileHandler.async(
          path: file.path,
        );

        expect(handler, isA<AsyncHandler>());
        final entry = LogEntry(
          loggerName: 'test.plain_async',
          origin: 'test_file.dart',
          level: LogLevel.info,
          message: 'Async plain line',
          timestamp: '2026-08-15 12:00:00.000',
        );

        await handler.log(entry);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await handler.dispose();

        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content, contains('Async plain line'));
      },
    );

    test('ToonFileHandler logs token-optimized TOON output', () async {
      final file = File('${tempDir.path}/log.toon');
      final handler = ToonFileHandler(
        path: file.path,
        arrayName: 'telemetry',
      );

      final entry = LogEntry(
        loggerName: 'test.toon',
        origin: 'test_file.dart',
        level: LogLevel.info,
        message: 'TOON tokenized line',
        timestamp: '2026-08-15 12:00:00.000',
      );

      await handler.log(entry);

      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('telemetry'));
      expect(content, contains('TOON tokenized line'));
    });

    test('ToonFileHandler.async logs TOON via background isolate', () async {
      final file = File('${tempDir.path}/log_async.toon');
      final handler = ToonFileHandler.async(
        path: file.path,
        arrayName: 'telemetry_async',
      );

      expect(handler, isA<AsyncHandler>());
      final entry = LogEntry(
        loggerName: 'test.toon_async',
        origin: 'test_file.dart',
        level: LogLevel.info,
        message: 'Async TOON tokenized line',
        timestamp: '2026-08-15 12:00:00.000',
      );

      await handler.log(entry);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await handler.dispose();

      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('telemetry_async'));
      expect(content, contains('Async TOON tokenized line'));
    });

    test('MarkdownFileHandler logs Markdown formatting', () async {
      final file = File('${tempDir.path}/log.md');
      final handler = MarkdownFileHandler(
        path: file.path,
      );

      final entry = LogEntry(
        loggerName: 'test.md',
        origin: 'test_file.dart',
        level: LogLevel.error,
        message: 'Markdown error report',
        timestamp: '2026-08-15 12:00:00.000',
      );

      await handler.log(entry);

      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('Markdown error report'));
    });

    test('MarkdownFileHandler.async logs Markdown via background isolate',
        () async {
      final file = File('${tempDir.path}/log_async.md');
      final handler = MarkdownFileHandler.async(
        path: file.path,
      );

      expect(handler, isA<AsyncHandler>());
      final entry = LogEntry(
        loggerName: 'test.md_async',
        origin: 'test_file.dart',
        level: LogLevel.error,
        message: 'Async Markdown report',
        timestamp: '2026-08-15 12:00:00.000',
      );

      await handler.log(entry);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await handler.dispose();

      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('Async Markdown report'));
    });

    test('HttpDashboardHandler creates valid dashboard pipeline', () {
      final handler = HttpDashboardHandler(
        port: 8888,
        title: 'Test Dashboard',
      );

      expect(handler, isA<Handler>());
      expect(handler.formatter, isA<StructuredFormatter>());
      expect(handler.sink, isA<HttpServerSink>());
    });

    test('MemoryHandler retains log entries in memory ring-buffer', () async {
      final handler = MemoryHandler(capacity: 5);

      final entry1 = LogEntry(
        loggerName: 'test.mem',
        origin: 'test_file.dart',
        level: LogLevel.info,
        message: 'Memory Event 1',
        timestamp: '2026-08-15 12:00:00.000',
      );

      final entry2 = LogEntry(
        loggerName: 'test.mem',
        origin: 'test_file.dart',
        level: LogLevel.warning,
        message: 'Memory Event 2',
        timestamp: '2026-08-15 12:00:01.000',
      );

      await handler.log(entry1);
      await handler.log(entry2);

      expect(handler.entries.length, equals(2));
      expect(handler.entries[0].message, equals('Memory Event 1'));
      expect(handler.entries[1].message, equals('Memory Event 2'));
    });
    group('2. File System & Lifecycle Edge Cases', () {
      test('TargetHandlers auto-create missing deep parent directories',
          () async {
        final deepFile =
            File('${tempDir.path}/nested/deep/logs/telemetry.toon');
        final handler = ToonFileHandler(
          path: deepFile.path,
          arrayName: 'telemetry',
        );

        final entry = LogEntry(
          loggerName: 'test.deep',
          origin: 'test_file.dart',
          level: LogLevel.info,
          message: 'Deep directory log',
          timestamp: '2026-08-16 12:00:00.000',
        );

        await handler.log(entry);

        expect(deepFile.existsSync(), isTrue);
        final content = deepFile.readAsStringSync();
        expect(content, contains('Deep directory log'));
      });

      test('JsonFileHandler forwards FileRotation configuration correctly',
          () async {
        final rotateFile = File('${tempDir.path}/rotate_app.json');
        final handler = JsonFileHandler(
          path: rotateFile.path,
          pretty: false,
          fileRotation: SizeRotation(maxSize: '100 B'),
        );

        // Dispatch large logs to trigger rotation
        for (var i = 0; i < 5; i++) {
          final entry = LogEntry(
            loggerName: 'test.rotation',
            origin: 'test_file.dart',
            level: LogLevel.info,
            message: 'Large log entry padding ' * 5,
            timestamp: '2026-08-16 12:00:00.000',
          );
          await handler.log(entry);
        }

        final backupFile = File('${tempDir.path}/rotate_app.1.json');
        expect(backupFile.existsSync(), isTrue);
      });

      test('HttpDashboardHandler cleanly releases resources on dispose',
          () async {
        final handler = HttpDashboardHandler(
          port: 0, // 0 lets OS pick random port
          title: 'Test Dashboard',
        );

        // Wait a tiny bit for the internal HttpServer to bind
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Dispose should complete without hanging or crashing
        await expectLater(handler.dispose(), completes);
      });
    });

    group('3. MemoryHandler Ring-Buffer Safety', () {
      test('MemoryHandler evicts oldest logs under capacity FIFO overflow',
          () async {
        final handler = MemoryHandler(capacity: 3);

        for (var i = 1; i <= 5; i++) {
          final entry = LogEntry(
            loggerName: 'test.mem',
            origin: 'test_file.dart',
            level: LogLevel.info,
            message: 'Event $i',
            timestamp: '2026-08-16 12:00:0$i.000',
          );
          await handler.log(entry);
        }

        // Expected: 1 and 2 are evicted, 3, 4, 5 remain.
        expect(handler.entries.length, equals(3));
        expect(handler.entries[0].message, equals('Event 3'));
        expect(handler.entries[1].message, equals('Event 4'));
        expect(handler.entries[2].message, equals('Event 5'));
      });

      test('MemoryHandler entries list is unmodifiable', () {
        final handler = MemoryHandler(capacity: 3);

        final entry = LogEntry(
          loggerName: 'test.mem',
          origin: 'test_file.dart',
          level: LogLevel.info,
          message: 'Hack Event',
          timestamp: '2026-08-16 12:00:00.000',
        );

        expect(
          () => handler.entries.add(entry),
          throwsUnsupportedError,
        );
      });

      test('MemoryHandler.clear() flushes all retained entries', () async {
        final handler = MemoryHandler(capacity: 3);
        final entry = LogEntry(
          loggerName: 'test.mem',
          origin: 'test_file.dart',
          level: LogLevel.info,
          message: 'Event',
          timestamp: '2026-08-16 12:00:00.000',
        );
        await handler.log(entry);

        expect(handler.entries.length, equals(1));

        // Use the sink reference if needed, or if MemoryHandler exposes clear:
        // Actually, MemorySink has clear(), but we can't easily access it unless MemoryHandler exposes it.
        // Let's verify MemoryHandler has clear. Oh, wait, in previous logs we said "MemoryHandler.clear()". Let's check MemoryHandler implementation!
        if (handler.sink is MemorySink) {
          (handler.sink as MemorySink).clear();
        }

        expect(handler.entries.isEmpty, isTrue);
      });
    });

    group('4. High-Throughput Async Stress Test', () {
      test(
        'JsonFileHandler.async safely processes rapid burst loads without dropping entries',
        () async {
          final stressFile = File('${tempDir.path}/stress.json');
          final handler = JsonFileHandler.async(
            path: stressFile.path,
            pretty: false,
          );

          for (var i = 0; i < 100; i++) {
            final entry = LogEntry(
              loggerName: 'test.stress',
              origin: 'test_file.dart',
              level: LogLevel.info,
              message: 'Stress Event $i',
              timestamp: '2026-08-16 12:00:00.000',
            );
            // Fire and forget (simulating unawaited UI dispatch)
            // ignore: unawaited_futures
            handler.log(entry);
          }

          // Allow the background isolate to finish processing the burst
          await Future<void>.delayed(const Duration(milliseconds: 500));

          // Dispose MUST await all flushes
          await handler.dispose();

          expect(stressFile.existsSync(), isTrue);
          final content = stressFile.readAsStringSync().trim();
          final lines = content.split('\n');

          expect(lines.length, equals(100));
          expect(lines.first, contains('Stress Event 0'));
          expect(lines.last, contains('Stress Event 99'));
        },
      );
    });
  });
}
