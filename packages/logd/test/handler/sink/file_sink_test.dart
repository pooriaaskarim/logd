import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:logd/logd.dart';
import 'package:logd/src/core/context/clock/clock.dart';
import 'package:logd/src/core/context/context.dart';
import 'package:logd/src/core/context/io/file_system.dart';
import 'package:test/test.dart';

class MockClock implements Clock {
  MockClock(this._now, [this._timezoneName]);
  DateTime _now;
  final String? _timezoneName;

  void set(final DateTime time) => _now = time;

  @override
  DateTime get now => _now;

  @override
  String? get timezoneName => _timezoneName;
}

class MockFileSystem implements FileSystem {
  MockFileSystem(this.clock);
  final MockClock clock;
  final Map<String, MockFile> files = {};

  @override
  File file(final String path) =>
      files.putIfAbsent(path, () => MockFile(path, this));

  @override
  Directory directory(final String path) => MockDirectory(this, path);
}

class MockFile implements File {
  MockFile(this.path, this.fs);
  @override
  final String path;
  final MockFileSystem fs;
  List<int> content = [];
  bool _exists = false;
  DateTime _lastModified = DateTime(2000);
  void setLastModified(final DateTime time) => _lastModified = time;

  @override
  Future<bool> exists() async => _exists;

  @override
  Future<FileSystemEntity> create({final bool recursive = false}) async {
    _exists = true;
    return this;
  }

  @override
  Future<void> writeAsString(
    final String contents, {
    final io.FileMode mode = io.FileMode.write,
    final Encoding encoding = utf8,
    final bool flush = false,
  }) async {
    _exists = true;
    if (mode == io.FileMode.append) {
      content.addAll(encoding.encode(contents));
    } else {
      content = encoding.encode(contents);
    }
    _lastModified = fs.clock.now;
  }

  @override
  Directory get parent => MockDirectory(fs, '.');

  @override
  Future<File> rename(final String newPath) async {
    final newFile = fs.file(newPath) as MockFile
      ..content = List.from(content)
      .._exists = true
      .._lastModified = _lastModified;
    _exists = false;
    content = [];
    fs.files.remove(path); // Update mock state
    return newFile;
  }

  @override
  Future<void> delete() async {
    _exists = false;
    content = [];
    fs.files.remove(path);
  }

  @override
  Future<int> length() async => content.length;

  @override
  DateTime lastModifiedSync() => _lastModified;

  @override
  Future<DateTime> lastModified() async => _lastModified;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List.fromList(content);

  @override
  Future<void> writeAsBytes(
    final List<int> bytes, {
    final io.FileMode mode = io.FileMode.write,
    final bool flush = false,
  }) async {
    _exists = true;
    content = bytes;
    _lastModified = fs.clock.now;
  }
}

class MockDirectory implements Directory {
  MockDirectory(this.fs, this.path);
  final MockFileSystem fs;
  @override
  final String path;

  @override
  Future<bool> exists() async => true;

  @override
  Future<Directory> create({final bool recursive = false}) async => this;

  @override
  Future<void> delete() async {}

  @override
  Future<FileSystemEntity> rename(final String newPath) async => this;

  @override
  Directory get parent => this;

  @override
  Future<DateTime> lastModified() async => DateTime.now();

  @override
  DateTime lastModifiedSync() => DateTime.now();

  @override
  Stream<FileSystemEntity> list({
    final bool recursive = false,
    final bool followLinks = true,
  }) async* {
    for (final f in fs.files.values) {
      if (await f.exists()) {
        yield f;
      }
    }
  }
}

void main() {
  group('FileSink', () {
    late MockClock clock;
    late MockFileSystem fs;

    setUp(() {
      clock = MockClock(DateTime(2025, 1, 1, 10, 0));
      fs = MockFileSystem(clock);
      Context.setClock(clock);
      Context.setFileSystem(fs);
    });

    tearDown(() {
      Logger.clearRegistry();
      Context.reset();
    });

    test('validates basePath on construction', () {
      expect(() => FileSink(''), throwsArgumentError);
      expect(() => FileSink('dir/'), throwsArgumentError);
    });

    test('output writes to file', () async {
      final sink = FileSink('test.log');
      await sink.output(
        [LogLine.text('Hello'), LogLine.text('World')],
        LogLevel.info,
      );

      final file = fs.files['test.log']!;
      expect(await file.exists(), isTrue);
      // FileSink joins with \n and appends \n
      expect(utf8.decode(file.content), equals('Hello\nWorld\n'));
    });

    test('TimeRotation rotates based on interval', () async {
      final rotation = TimeRotation(interval: const Duration(hours: 1));
      final sink = FileSink('app.log', fileRotation: rotation);

      // 10:00 - Log 1
      await sink.output([LogLine.text('Log 1')], LogLevel.info);
      final file = fs.files['app.log']!;
      expect(utf8.decode(file.content), contains('Log 1'));

      // 12:00 - Log 2 (Should rotate)
      clock.set(DateTime(2025, 1, 1, 12, 0));
      await sink.output([LogLine.text('Log 2')], LogLevel.info);

      final currentFile = fs.files['app.log']!;
      // Current file has Log 2 only
      expect(utf8.decode(currentFile.content), equals('Log 2\n'));

      // Rotated file exists (app-2025-01-01.log or similar, default formatter)
      final rotatedFiles =
          fs.files.keys.where((final k) => k != 'app.log').toList();
      expect(rotatedFiles, isNotEmpty);
      final rotated = fs.files[rotatedFiles.first]!;
      expect(utf8.decode(rotated.content), contains('Log 1'));
    });

    test('SizeRotation rotates based on size', () async {
      // Rotate if > 10 bytes
      final rotation = SizeRotation(maxSize: '10 B');
      final sink = FileSink('size.log', fileRotation: rotation);

      // '123456' + \n = 7 bytes
      await sink.output([LogLine.text('123456')], LogLevel.info);
      final file = fs.files['size.log']!;
      expect(await file.length(), equals(7));

      // Append 5 bytes ('7890' + \n) -> 12 bytes total > 10 -> Rotate
      await sink.output([LogLine.text('7890')], LogLevel.info);

      final currentFile = fs.files['size.log']!;
      // Current file has new data only
      expect(utf8.decode(currentFile.content), equals('7890\n'));

      // Backup exists (size.1.log)
      const backupPath = 'size.1.log'; // default formatter
      expect(fs.files.containsKey(backupPath), isTrue);
      expect(utf8.decode(fs.files[backupPath]!.content), equals('123456\n'));
    });

    test('SizeRotation cleans up old backups', () async {
      final rotation = SizeRotation(maxSize: '5 B', backupCount: 2);
      final sink = FileSink('clean.log', fileRotation: rotation);

      // Create some "old" backups manually in the mock FS
      final b1 = fs.file('clean.1.log') as MockFile
        ..setLastModified(DateTime(2025, 1, 1, 9, 0))
        ..content = utf8.encode('old 1');

      await b1.writeAsString('old 1'); // Ensure exists

      final b2 = fs.file('clean.2.log') as MockFile
        ..setLastModified(DateTime(2025, 1, 1, 8, 0)) // Oldest
        ..content = utf8.encode('old 2');
      await b2.writeAsString('old 2');

      // Now trigger rotation
      await sink.output([LogLine.text('trigger')], LogLevel.info);

      // We expect:
      // clean.1.log: 'trigger' (moved from current)
      // clean.2.log: 'old 1' (shifted from 1)
      // clean.3.log: Should be deleted because backupCount is 2?
      // Wait, let's check the code logic: backupCount is the limit.
      // If backupCount is 2, it keeps clean.1.log and clean.2.log.

      expect(fs.files.containsKey('clean.1.log'), isTrue);
      expect(fs.files.containsKey('clean.2.log'), isTrue);
      expect(fs.files.containsKey('clean.3.log'), isFalse);
    });

    test('SizeRotation supports compression', () async {
      final rotation = SizeRotation(maxSize: '5 B', compress: true);
      final sink = FileSink('gzip.log', fileRotation: rotation);

      await sink.output([LogLine.text('data')], LogLevel.info);
      await sink.output([LogLine.text('rotate')], LogLevel.info);

      // Current file is 'rotate\n'
      expect(utf8.decode(fs.files['gzip.log']!.content), equals('rotate\n'));

      // Rotated file is 'gzip.1.log.gz'
      expect(fs.files.containsKey('gzip.1.log.gz'), isTrue);
      expect(
        fs.files.containsKey('gzip.1.log'),
        isFalse,
      ); // Deleted after compress
    });

    test('TimeRotation cleans up old backups', () async {
      final rotation = TimeRotation(
        interval: const Duration(hours: 1),
        backupCount: 1,
      );
      final sink = FileSink('time_clean.log', fileRotation: rotation);

      // 10:00 - Initial log
      await sink.output([LogLine.text('Initial')], LogLevel.info);

      // Next Day 11:00 - First rotation
      clock.set(DateTime(2025, 1, 2, 11, 0));
      await sink.output([LogLine.text('Second')], LogLevel.info);

      // Rotated: time_clean-2025-01-01.log (based on lastRotation=Jan 1)
      const jan1Backup = 'time_clean-2025-01-01.log';
      expect(fs.files.containsKey(jan1Backup), isTrue);

      // Next Day 12:00 - Second rotation
      clock.set(DateTime(2025, 1, 3, 12, 0));
      await sink.output([LogLine.text('Third')], LogLevel.info);

      // Rotated: time_clean-2025-01-02.log (based on lastRotation=Jan 2)
      const jan2Backup = 'time_clean-2025-01-02.log';
      expect(fs.files.containsKey(jan2Backup), isTrue);

      // Only 1 backup should remain ( Jan 1 should be gone if backupCount is 1)
      final backups = fs.files.keys
          .where((final k) => k.startsWith('time_clean-'))
          .toList();
      expect(backups.length, equals(1));
      expect(backups, contains(jan2Backup));
      expect(backups, isNot(contains(jan1Backup)));
    });

    test('Rotation cleanup does not delete unrelated files', () async {
      final rotation = SizeRotation(maxSize: '5 B', backupCount: 1);
      final sink = FileSink('app.log', fileRotation: rotation);

      // Create an unrelated file
      final unrelated = fs.file('random.txt') as MockFile;
      await unrelated.writeAsString('I should stay');

      // Trigger rotation
      await sink.output([LogLine.text('data')], LogLevel.info);
      await sink.output([LogLine.text('rotate')], LogLevel.info);

      expect(fs.files.containsKey('random.txt'), isTrue);
    });
  });
}
