import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

export 'file_system_stub.dart' if (dart.library.io) 'file_system_io.dart';

enum LogFileMode {
  read,
  write,
  append,
  writeOnly,
  writeOnlyAppend,
}

abstract class FileSystem {
  File file(final String path);
  Directory directory(final String path);
}

abstract class FileSystemEntity {
  String get path;
  Future<bool> exists();
  Future<void> delete();
  Future<FileSystemEntity> rename(final String newPath);
  Future<FileSystemEntity> create({final bool recursive = false});
  FileSystemEntity get parent;
  Future<DateTime> lastModified();
  DateTime lastModifiedSync();
}

abstract class File implements FileSystemEntity {
  @override
  Directory get parent;
  Future<int> length();
  Future<void> writeAsString(
    final String contents, {
    final LogFileMode mode = LogFileMode.write,
    final Encoding encoding = utf8,
    final bool flush = false,
  });
  Future<void> writeAsBytes(
    final List<int> bytes, {
    final LogFileMode mode = LogFileMode.write,
    final bool flush = false,
  });
  RandomAccessFile openSync({final LogFileMode mode = LogFileMode.read});
  Future<Uint8List> readAsBytes();
}

abstract class RandomAccessFile {
  void writeFromSync(
    final List<int> buffer, [
    final int start = 0,
    final int? end,
  ]);
  void closeSync();
}

abstract class Directory implements FileSystemEntity {
  Stream<FileSystemEntity> list({
    final bool recursive = false,
    final bool followLinks = true,
  });
}
