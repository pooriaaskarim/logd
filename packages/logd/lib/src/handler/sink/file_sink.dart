part of '../handler.dart';

/// Base interface for file rotation policies.
///
/// Subclasses define the criteria for when a log file should be rotated (e.g.,
/// based on size or time) and how the rotation is performed.
abstract class FileRotation {
  /// Creates a [FileRotation] policy.
  ///
  /// - [compress]: Whether to gzip compress rotated backup files.
  /// - [backupCount]: The number of backup files to keep.
  /// If 0, no backups are kept.
  FileRotation({
    this.compress = false,
    this.backupCount = 5,
  }) {
    if (backupCount < 0) {
      throw ArgumentError(
        'Invalid backupCount: $backupCount. Must be non-negative.',
      );
    }
  }

  /// Whether to gzip compress rotated files.
  final bool compress;

  /// Number of backup files to keep
  /// (deletes oldest if exceeded; 0 = no backups).
  final int backupCount;

  /// Determines if rotation is necessary before appending
  /// [newData] to [currentFile].
  Future<bool> needsRotation(final File currentFile, final String newData);

  /// Performs the rotation of the file at [basePath].
  ///
  /// This typically involves renaming the current file, optionally compressing
  /// it, and cleaning up old backups that exceed [backupCount].
  Future<void> rotate(final String basePath);
}

/// A [FileRotation] policy that rotates files when they exceed a maximum size.
///
/// Rotated files are indexed (e.g., `app.1.log`, `app.2.log`), where index 1
/// is always the most recent backup.
class SizeRotation extends FileRotation {
  /// Creates a [SizeRotation] policy.
  ///
  /// - [maxSize]: A human-readable string representing the maximum size (e.g.,
  ///   '10 MB', '512 KB').
  /// - [filenameFormatter]: An optional function to customize the rotated
  /// filename.
  SizeRotation({
    final String maxSize = '512 KB',
    super.compress,
    super.backupCount,
    this.filenameFormatter,
  }) : maxBytes = parseMaxSizeLiteral(maxSize);

  /// A custom function for formatting rotated filenames.
  ///
  /// Takes the base name without extension, the extension, and the
  /// backup index. Returns the relative filename.
  final String Function(
    String baseWithoutExt,
    String? ext,
    int? index,
  )? filenameFormatter;

  String _defaultNameFormatter(
    final String baseWithoutExt,
    final String? ext,
    final int? index,
  ) =>
      '$baseWithoutExt'
      '${index != null ? '.$index' : ''}'
      '${ext != null && ext.isNotEmpty ? ext : ''}';

  /// The maximum size in bytes after which rotation occurs.
  ///
  /// e.g. '10 MB', '512 KB', '1 TB'
  final int maxBytes;

  /// Parses a human-readable size string into bytes.
  ///
  /// Supported units: B, KB, MB, GB, TB.
  static int parseMaxSizeLiteral(final String maxSizeLiteral) {
    final s = maxSizeLiteral.toUpperCase().replaceAll(' ', '');
    final match = RegExp(r'^(\d+(\.\d+)?)(TB|GB|MB|KB|B)?$').firstMatch(s);
    if (match == null) {
      throw FormatException(
        'Invalid size: $s (e.g., "10 MB", "512 KB", "1 TB")',
      );
    }
    final num = double.parse(match.group(1)!);
    final unit = match.group(3) ?? 'B';
    final multipliers = {
      'B': 1,
      'KB': 1024,
      'MB': 1024 * 1024,
      'GB': 1024 * 1024 * 1024,
      'TB': 1024 * 1024 * 1024 * 1024,
    };
    return (num * (multipliers[unit] ?? 1)).toInt();
  }

  @override
  Future<bool> needsRotation(
    final File currentFile,
    final String newData,
  ) async {
    final currentLength =
        await currentFile.exists() ? await currentFile.length() : 0;
    final newDataSize = utf8.encode(newData).length;
    return currentLength + newDataSize > maxBytes;
  }

  @override
  Future<void> rotate(final String basePath) async {
    final file = Context.fileSystem.file(basePath);
    if (!await file.exists()) {
      return;
    }

    final pathSeparator = io.Platform.pathSeparator;
    final normalizedPath =
        basePath.replaceAll('\\', pathSeparator).replaceAll('/', pathSeparator);
    final lastSepIndex = normalizedPath.lastIndexOf(pathSeparator);
    final filenamePart = lastSepIndex != -1
        ? normalizedPath.substring(lastSepIndex + 1)
        : normalizedPath;
    final extIndex = filenamePart.lastIndexOf('.');
    final ext = extIndex != -1 && extIndex < filenamePart.length - 1
        ? filenamePart.substring(extIndex)
        : null;
    final baseWithoutExt =
        basePath.substring(0, basePath.length - (ext?.length ?? 0));

    final formatter = filenameFormatter ?? _defaultNameFormatter;

    if (backupCount > 0) {
      // Shift backups: .N -> .(N+1)
      final extension = compress ? '.gz' : '';
      for (int i = backupCount - 1; i >= 1; i--) {
        final oldPath = formatter(baseWithoutExt, ext, i) + extension;
        final newPath = formatter(baseWithoutExt, ext, i + 1) + extension;
        final oldFile = Context.fileSystem.file(oldPath);
        if (await oldFile.exists()) {
          await oldFile.rename(newPath);
        }
      }
      // Move current to .1
      final backupPath = formatter(baseWithoutExt, ext, 1);
      await file.rename(backupPath);
      if (compress) {
        final bytes = await Context.fileSystem.file(backupPath).readAsBytes();
        final gzBytes = io.GZipCodec().encode(bytes);
        await Context.fileSystem.file('$backupPath.gz').writeAsBytes(gzBytes);
        await Context.fileSystem.file(backupPath).delete();
      }
      // Cleanup excess
      final dir = file.parent;
      final entities = await dir.list().toList();
      final backupFiles = <File>[];
      for (final e in entities) {
        if (e is File &&
            e.path.startsWith(baseWithoutExt) &&
            e.path.endsWith(extension)) {
          backupFiles.add(e);
        }
      }
      backupFiles.sort(
        (final a, final b) =>
            a.lastModifiedSync().compareTo(b.lastModifiedSync()),
      ); // Oldest first
      while (backupFiles.length > backupCount) {
        await backupFiles.removeAt(0).delete();
      }
    } else {
      await file.delete();
    }
  }
}

/// A [FileRotation] policy that rotates files based on a time interval.
///
/// Rotated files are suffixed with a timestamp (e.g., `app-2025-01-01.log`).
class TimeRotation extends FileRotation {
  /// Creates a [TimeRotation] policy.
  ///
  /// - [interval]: The duration after which rotation occurs
  /// (e.g., daily, weekly).
  /// - [timestamp]: A [Timestamp] instance used to format the suffix.
  TimeRotation({
    this.interval = const Duration(days: 7),
    final Timestamp? timestamp,
    this.filenameFormatter,
    super.compress,
    super.backupCount,
  })  : timestamp = timestamp ?? Timestamp(formatter: 'yyyy-MM-dd'),
        assert(!interval.isNegative, 'Invalid interval: must be non-negative');

  /// A custom function for formatting rotated filenames.
  ///
  /// Takes the base name without extension, the extension,
  /// and the rotation time.
  final String Function(
    String baseWithoutExt,
    String? ext,
    DateTime rotationTime,
  )? filenameFormatter;

  String _defaultNameFormatter(
    final String baseWithoutExt,
    final String? ext,
    final DateTime rotationTime,
  ) {
    final ts = timestamp.formatter.format(rotationTime) ??
        rotationTime.toIso8601String().split('T')[0];
    return '$baseWithoutExt-$ts${ext != null && ext.isNotEmpty ? ext : ''}';
  }

  /// The duration between rotations.
  ///
  /// Must be non-negative.
  /// e.g. `Duration(days: 7)`
  final Duration interval;

  /// The timestamp formatter for rotated filename suffixes.
  final Timestamp timestamp;

  /// The last time rotation occurred
  /// (calculated from the file's last modified time if null).
  DateTime? lastRotation;

  @override
  Future<bool> needsRotation(
    final File currentFile,
    final String newData,
  ) async {
    await initLastRotation(currentFile);
    final now = Context.clock.now;
    return now.difference(lastRotation!) >= interval;
  }

  @override
  Future<void> rotate(final String basePath) async {
    final file = Context.fileSystem.file(basePath);
    if (!await file.exists()) {
      return;
    }

    final pathSeparator = io.Platform.pathSeparator;
    final normalizedPath =
        basePath.replaceAll('\\', pathSeparator).replaceAll('/', pathSeparator);
    final lastSepIndex = normalizedPath.lastIndexOf(pathSeparator);
    final filenamePart = lastSepIndex != -1
        ? normalizedPath.substring(lastSepIndex + 1)
        : normalizedPath;
    final extIndex = filenamePart.lastIndexOf('.');
    final ext = extIndex != -1 && extIndex < filenamePart.length - 1
        ? filenamePart.substring(extIndex)
        : null;
    final baseWithoutExt =
        basePath.substring(0, basePath.length - (ext?.length ?? 0));

    final rotationTime = lastRotation!;
    final formatter = filenameFormatter ?? _defaultNameFormatter;
    final rotatedPath = formatter(baseWithoutExt, ext, rotationTime);
    await file.rename(rotatedPath);
    if (compress) {
      final bytes = await Context.fileSystem.file(rotatedPath).readAsBytes();
      final gzBytes = io.GZipCodec().encode(bytes);
      await Context.fileSystem.file('$rotatedPath.gz').writeAsBytes(gzBytes);
      await Context.fileSystem.file(rotatedPath).delete();
    }
    lastRotation = Context.clock.now;
    if (backupCount > 0) {
      // Cleanup: Find rotated files, sort by mod time, delete oldest
      final dir = file.parent;
      final entities = await dir.list().toList();
      final extension = compress ? '.gz' : '';
      final logFiles = entities
          .where(
            (final e) =>
                e is File &&
                e.path.startsWith('$baseWithoutExt-') &&
                e.path.endsWith(extension),
          )
          .cast<File>()
          .toList()
        ..sort(
          (final a, final b) =>
              a.lastModifiedSync().compareTo(b.lastModifiedSync()),
        ); // Oldest first
      while (logFiles.length > backupCount) {
        await logFiles.removeAt(0).delete();
      }
    }
  }

  /// Initializes [lastRotation] from the file's metadata or current time.
  Future<void> initLastRotation(final File currentFile) async {
    if (lastRotation != null) {
      return;
    }
    if (await currentFile.exists()) {
      lastRotation = await currentFile.lastModified();
    } else {
      lastRotation = Context.clock.now;
    }
  }
}

/// A [LogSink] that appends formatted log lines to a local file.
///
/// It supports various file rotation policies (size-based, time-based) and
/// optional GZip compression of rotated backups. Parent directories are
/// automatically created if they do not exist.
///
/// This sink uses internal synchronization to ensure that concurrent write
/// operations are serialized, preventing data loss when logging operations
/// happen rapidly (e.g., in a loop).
base class FileSink extends LogSink {
  /// Creates a [FileSink] at the specified [basePath].
  ///
  /// - [basePath]: The relative or absolute path to the log file. Must point
  ///   to a filename, not a directory.
  /// - [fileRotation]: An optional policy for rotating the log file.
  /// - [enabled]: Whether the sink is currently active.
  FileSink(this.basePath, {this.fileRotation, super.enabled = true}) {
    _validateBasePath(basePath);
  }

  @override
  int get preferredWidth => 120;

  /// The path to the active log file (e.g., 'logs/app.log').
  final String basePath;

  void _validateBasePath(final String basePath) {
    if (basePath.isEmpty) {
      throw ArgumentError('Invalid basePath: empty string. '
          'Examples: "app.log" or "some/dir/app.log".');
    }

    final pathSeparator = io.Platform.pathSeparator;

    final normalizedPath =
        basePath.replaceAll('\\', pathSeparator).replaceAll('/', pathSeparator);

    if (normalizedPath.endsWith(pathSeparator)) {
      throw ArgumentError('Invalid basePath: path to a directory. '
          'Must point to a filename (not empty or end in path separator). '
          'Examples: "app.log" or "some/dir/app.log".');
    }
  }

  /// The rotation policy applied to this sink (null for no rotation).
  final FileRotation? fileRotation;

  /// Internal mutex to serialize write operations and prevent race conditions.
  ///
  /// Uses a Completer-based queue to ensure all write operations are executed
  /// sequentially, even when called concurrently (e.g., from a loop).
  Future<void>? _writeLock;

  @override
  Future<void> output(
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    if (!enabled) {
      return;
    }

    // Serialize all write operations using a mutex
    final previousLock = _writeLock;
    final completer = Completer<void>();
    _writeLock = completer.future;

    // Wait for previous write to complete
    if (previousLock != null) {
      await previousLock;
    }

    try {
      await _performWrite(lines);
      completer.complete();
    } catch (e, s) {
      completer.completeError(e, s);
      InternalLogger.log(
        LogLevel.error,
        'FileSink error',
        error: e,
        stackTrace: s,
      );
    } finally {
      // Clear lock if this was the last operation
      if (_writeLock == completer.future) {
        _writeLock = null;
      }
    }
  }

  /// Performs the actual file write operation.
  ///
  /// This method is called from [output] after acquiring the write lock.
  Future<void> _performWrite(final Iterable<LogLine> lines) async {
    final file = Context.fileSystem.file(basePath);
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final linesList = lines.toList();
    if (linesList.isEmpty) {
      return;
    }
    final newData = '${linesList.map((final l) => l.toString()).join('\n')}\n';

    File targetFile = file;
    if (fileRotation != null &&
        await fileRotation!.needsRotation(file, newData)) {
      try {
        await fileRotation!.rotate(basePath);
        targetFile = Context.fileSystem.file(basePath);
      } catch (rotationError, rotationStack) {
        // If rotation fails, log the error but continue with write to original
        // file This ensures log entries aren't lost due to rotation failures
        InternalLogger.log(
          LogLevel.warning,
          'File rotation failed, continuing with write to original file',
          error: rotationError,
          stackTrace: rotationStack,
        );
        // Continue with original file - don't fail the entire write operation
      }
    }
    await targetFile.writeAsString(
      newData,
      mode: io.FileMode.append,
      flush: true,
    );

    // Update TimeRotation's lastRotation after write to track file's new
    // lastModified time This ensures time-based rotation works correctly
    if (fileRotation is TimeRotation) {
      final timeRotation = fileRotation! as TimeRotation;
      if (await targetFile.exists()) {
        timeRotation.lastRotation = await targetFile.lastModified();
      }
    }
  }
}
