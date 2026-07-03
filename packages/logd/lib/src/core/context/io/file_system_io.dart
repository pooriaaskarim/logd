import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'file_system.dart';

class LocalFileSystem implements FileSystem {
  const LocalFileSystem();

  @override
  File file(final String path) => _LocalFile(io.File(path));

  @override
  Directory directory(final String path) => _LocalDirectory(io.Directory(path));
}

class _LocalFile implements File {
  _LocalFile(this._delegate);

  final io.File _delegate;

  @override
  String get path => _delegate.path;

  @override
  Future<bool> exists() => _delegate.exists();

  @override
  Future<void> delete() => _delegate.delete();

  @override
  Future<File> rename(final String newPath) async {
    final renamed = await _delegate.rename(newPath);
    return _LocalFile(renamed);
  }

  @override
  Future<File> create({final bool recursive = false}) async {
    final created = await _delegate.create(recursive: recursive);
    return _LocalFile(created);
  }

  @override
  Directory get parent => _LocalDirectory(_delegate.parent);

  @override
  Future<DateTime> lastModified() => _delegate.lastModified();

  @override
  DateTime lastModifiedSync() => _delegate.lastModifiedSync();

  @override
  Future<int> length() => _delegate.length();

  @override
  Future<void> writeAsString(
    final String contents, {
    final LogFileMode mode = LogFileMode.write,
    final Encoding encoding = utf8,
    final bool flush = false,
  }) =>
      _delegate.writeAsString(
        contents,
        mode: _toIoMode(mode),
        encoding: encoding,
        flush: flush,
      );

  @override
  Future<void> writeAsBytes(
    final List<int> bytes, {
    final LogFileMode mode = LogFileMode.write,
    final bool flush = false,
  }) =>
      _delegate.writeAsBytes(bytes, mode: _toIoMode(mode), flush: flush);

  @override
  RandomAccessFile openSync({final LogFileMode mode = LogFileMode.read}) =>
      _LocalRandomAccessFile(_delegate.openSync(mode: _toIoMode(mode)));

  @override
  Future<Uint8List> readAsBytes() => _delegate.readAsBytes();
}

class _LocalRandomAccessFile implements RandomAccessFile {
  _LocalRandomAccessFile(this._delegate);

  final io.RandomAccessFile _delegate;

  @override
  void writeFromSync(
    final List<int> buffer, [
    final int start = 0,
    final int? end,
  ]) {
    _delegate.writeFromSync(buffer, start, end);
  }

  @override
  void closeSync() {
    _delegate.closeSync();
  }
}

class _LocalDirectory implements Directory {
  _LocalDirectory(this._delegate);
  final io.Directory _delegate;

  @override
  String get path => _delegate.path;

  @override
  Future<bool> exists() => _delegate.exists();

  @override
  Future<void> delete() => _delegate.delete();

  @override
  Future<Directory> rename(final String newPath) async {
    final renamed = await _delegate.rename(newPath);
    return _LocalDirectory(renamed);
  }

  @override
  Future<Directory> create({final bool recursive = false}) async {
    final created = await _delegate.create(recursive: recursive);
    return _LocalDirectory(created);
  }

  @override
  Directory get parent => _LocalDirectory(_delegate.parent);

  @override
  Future<DateTime> lastModified() => throw UnimplementedError(
        'Directory.lastModified not strictly needed yet',
      );

  @override
  DateTime lastModifiedSync() => throw UnimplementedError(
        'Directory.lastModifiedSync not strictly needed yet',
      );

  @override
  Stream<FileSystemEntity> list({
    final bool recursive = false,
    final bool followLinks = true,
  }) async* {
    await for (final entity
        in _delegate.list(recursive: recursive, followLinks: followLinks)) {
      if (entity is io.File) {
        yield _LocalFile(entity);
      } else if (entity is io.Directory) {
        yield _LocalDirectory(entity);
      }
    }
  }
}

io.FileMode _toIoMode(final LogFileMode mode) {
  switch (mode) {
    case LogFileMode.read:
      return io.FileMode.read;
    case LogFileMode.write:
      return io.FileMode.write;
    case LogFileMode.append:
      return io.FileMode.append;
    case LogFileMode.writeOnly:
      return io.FileMode.writeOnly;
    case LogFileMode.writeOnlyAppend:
      return io.FileMode.writeOnlyAppend;
  }
}
