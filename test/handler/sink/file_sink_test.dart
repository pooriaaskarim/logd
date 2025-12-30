import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logd/logd.dart';
import 'package:logd/src/core/clock/clock.dart';
import 'package:logd/src/core/context.dart';
import 'package:logd/src/core/io/file_system.dart';

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
      // Very basic filtering for "parent" logic simulation (if needed)
      // Since FileSink backup cleanup looks for files in same dir,
      // assuming flattening for mock
      yield f;
    }
  }
}

void main() {
  group('FileSink', () {
    late MockClock clock;
    late MockFileSystem fs;

    setUp(() {
      clock = MockClock(DateTime(2025, 1, 1, 10, 0));
      fs = MockFileSystem();
      Context.setClock(clock);
      Context.setFileSystem(fs);
    });

    tearDown(() {
      Context.reset();
    });

    test('validates basePath on construction', () {
      expect(() => FileSink(''), throwsArgumentError);
      expect(() => FileSink('dir/'), throwsArgumentError);
    });

    test('output writes to file', () async {
      final sink = FileSink('test.log');
      await sink.output(['Hello', 'World'], LogLevel.info);

      final file = fs.files['test.log']!;
      expect(await file.exists(), isTrue);
      // FileSink joins with \n and appends \n
      expect(utf8.decode(file.content), equals('Hello\nWorld\n'));
    });

    test('TimeRotation rotates based on interval', () async {
      final rotation = TimeRotation(interval: const Duration(hours: 1));
      final sink = FileSink('app.log', fileRotation: rotation);

      // 10:00 - Log 1
      await sink.output(['Log 1'], LogLevel.info);
      final file = fs.files['app.log']!;
      expect(utf8.decode(file.content), contains('Log 1'));

      // 12:00 - Log 2 (Should rotate)
      clock.set(DateTime(2025, 1, 1, 12, 0));
      await sink.output(['Log 2'], LogLevel.info);

      // Current file has Log 2 only
      expect(utf8.decode(file.content), equals('Log 2\n'));

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
      await sink.output(['123456'], LogLevel.info);
      final file = fs.files['size.log']!;
      expect(await file.length(), equals(7));

      // Append 5 bytes ('7890' + \n) -> 12 bytes total > 10 -> Rotate
      await sink.output(['7890'], LogLevel.info);

      // Current file has new data only
      expect(utf8.decode(file.content), equals('7890\n'));

      // Backup exists (size.1.log)
      const backupPath = 'size.1.log'; // default formatter
      expect(fs.files.containsKey(backupPath), isTrue);
      expect(utf8.decode(fs.files[backupPath]!.content), equals('123456\n'));
    });
  });
}
