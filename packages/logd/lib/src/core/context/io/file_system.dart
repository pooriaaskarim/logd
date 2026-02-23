import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

/// Abstract interface for file system operations.
///
/// Provides access to [File] and [Directory] abstractions, allowing
/// platform-agnostic or testable implementations.
abstract class FileSystem {
  /// Create a [File] handle for the given [path].
  File file(final String path);

  /// Create a [Directory] handle for the given [path].
  Directory directory(final String path);
}

/// Base interface for file system entities ([File] and [Directory]).
abstract class FileSystemEntity {
  /// The path of this entity.
  String get path;

  /// Check if the entity exists.
  Future<bool> exists();

  /// Delete the entity.
  Future<void> delete();

  /// Rename the entity to [newPath].
  Future<FileSystemEntity> rename(final String newPath);

  /// Create the entity.
  Future<FileSystemEntity> create({final bool recursive = false});

  /// Get the parent directory of this entity.
  FileSystemEntity get parent;

  /// Get the last modified timestamp.
  Future<DateTime> lastModified();

  /// Get the last modified timestamp synchronously.
  DateTime lastModifiedSync();
}

/// Abstract interface for file operations.
abstract class File implements FileSystemEntity {
  @override
  Directory get parent;

  /// Get the length of the file in bytes.
  Future<int> length();

  /// Write string content to the file.
  Future<void> writeAsString(
    final String contents, {
    final io.FileMode mode = io.FileMode.write,
    final Encoding encoding = utf8,
    final bool flush = false,
  });

  /// Write byte content to the file.
  Future<void> writeAsBytes(
    final List<int> bytes, {
    final io.FileMode mode = io.FileMode.write,
    final bool flush = false,
  });

  /// Read the entire file as bytes.
  Future<Uint8List> readAsBytes();
}

/// Abstract interface for directory operations.
abstract class Directory implements FileSystemEntity {
  /// List the contents of the directory.
  Stream<FileSystemEntity> list({
    final bool recursive = false,
    final bool followLinks = true,
  });
}

/// Default implementation of [FileSystem] using `dart:io`.
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
    final io.FileMode mode = io.FileMode.write,
    final Encoding encoding = utf8,
    final bool flush = false,
  }) =>
      _delegate.writeAsString(
        contents,
        mode: mode,
        encoding: encoding,
        flush: flush,
      );

  @override
  Future<void> writeAsBytes(
    final List<int> bytes, {
    final io.FileMode mode = io.FileMode.write,
    final bool flush = false,
  }) =>
      _delegate.writeAsBytes(bytes, mode: mode, flush: flush);

  @override
  Future<Uint8List> readAsBytes() => _delegate.readAsBytes();
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
