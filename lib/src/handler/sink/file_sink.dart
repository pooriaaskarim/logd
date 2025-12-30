part of '../handler.dart';

/// File Rotation Handler.
///
/// Subclasses implement triggers (e.g., size or time) for rotating the current
/// log file. Rotation renames the current file (with optional compression) and
/// starts fresh. Use [backupCount] to limit kept rotated files.
abstract class FileRotation {
  FileRotation({
    this.compress = false,
    this.backupCount = 5,
  }) {
    if (backupCount < 0) {
      throw ArgumentError('Invalid backupCount:'
          ' $backupCount. Must be non-negative.');
    }
  }

  /// Whether to gzip compress rotated files.
  final bool compress;

  /// Number of backup files to keep (deletes oldest if exceeded; 0 = no limit).
  final int backupCount;

  /// Check if rotation is needed before appending new data.
  Future<bool> needsRotation(final File currentFile, final String newData);

  /// Perform the rotation: rename/compress current file, cleanup excess backups.
  Future<void> rotate(final String basePath);
}

/// [FileRotation] based on log file size.
///
/// Rotates when the file size would exceed [maxBytes] after appending.
///
/// Example:
/// ```dart
/// FileSink(
///   'logs/app.log',
///   fileRotation: SizeRotation(
///     maxSize: '10 MB',
///     backupCount: 5,
///     compress: true,
///   ),
/// );
/// ```
/// Rotated files: app.1.log.gz, app.2.log.gz, etc. (index 1 is newest).
class SizeRotation extends FileRotation {
  SizeRotation({
    final String maxSize = '512 KB',
    super.compress,
    super.backupCount,
    this.filenameFormatter,
  }) : maxBytes = parseMaxSizeLiteral(maxSize);

  /// Optional: Custom formatter for rotated filenames.
  ///
  /// Takes the base name (without extension), extension, rotation index.
  /// Returns the rotated name (without path or compression suffix).
  ///
  /// Example for custom: (base, ext, index) => '$base-custom-$index$ext'
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

  /// Maximum file size (parsed from string like '10 MB', '512 KB', '1 TB').
  final int maxBytes;

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

    // Extract base and ext (platform-agnostic)
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
      final backupFiles = <File>[];
      final dir = file.parent;
      final entities = await dir.list().toList();
      for (final e in entities) {
        if (e is File && e.path.endsWith(extension)) {
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

/// [FileRotation] based on time.
///
/// Rotates every [interval] (e.g., Duration(hours: 1) for hourly,
/// Duration(days: 7) for weekly).
/// Uses [timestamp] to format the timestamp suffix for rotated files.
///
/// Predefined intervals: Duration(hours: 1) for hourly, Duration(days: 1)
/// for daily, Duration(days: 7) for weekly.
///
/// Example:
/// ```dart
/// FileSink(
///   'logs/app.log',
///   fileRotation: TimeRotation(
///     interval: Duration(days: 1),
///     nameFormatter: Timestamp(formatter: 'yyyy-MM-dd'),
///     backupCount: 7,
///     compress: true,
///   ),
/// );
/// ```
/// Rotated files: app-2025-11-11.log.gz, etc.
/// (current logs always to 'app.log').
class TimeRotation extends FileRotation {
  TimeRotation({
    this.interval = const Duration(days: 7),
    this.timestamp = const Timestamp(formatter: 'yyyy-MM-dd'),
    this.filenameFormatter,
    super.compress,
    super.backupCount,
  }) {
    if (interval.isNegative) {
      throw ArgumentError('Invalid interval: $interval. Must be non-negative.');
    }
  }

  /// Optional: Custom formatter for rotated filenames.
  ///
  /// Takes the base name (without extension), extension, rotation time.
  /// Returns the rotated name (without path or compression suffix).
  ///
  /// Example for custom: (base, ext, time) => '$base-custom-$time.$ext'
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
    final ts = timestamp.getTimestamp() ??
        rotationTime.toIso8601String().split('T')[0];
    return '$baseWithoutExt-$ts${ext != null && ext.isNotEmpty ? ext : ''}';
  }

  /// Rotation interval (must be positive;
  /// e.g., Duration(hours: 1),
  /// Duration(days: 7)).
  final Duration interval;

  /// Formatter for the timestamp suffix in rotated filenames
  /// (default: 'yyyy-MM-dd').
  final Timestamp timestamp;

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

    // Extract base and ext (platform-agnostic)
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

/// Appends to a file asynchronously, with optional rotation.
///
/// Creates a file sink at [basePath].
///
/// - [basePath]: Path to the log file (e.g., 'app.log' or 'logs/app.log').
///   Must include a non-empty filename (extension optional, e.g., 'logs/my_log' is valid).
///   Invalid if empty, a directory (ends in '/'), or no filename (e.g., '/').
///   Parent directories are created if missing.
/// - [fileRotation]: Optional rotation policy.
class FileSink implements LogSink {
  FileSink(
    this.basePath, {
    this.fileRotation,
    this.enabled = true,
  }) {
    _validateBasePath(basePath);
  }

  /// Path to the current log file (e.g., 'logs/app.log').
  ///
  /// Rotated files will be named based on [FileRotation].
  /// (e.g., app-2025-11-11.log or app.1.log).
  ///
  /// [basePath] should contain a valid filename. Paths not containing a valid
  /// filename ( e.g. 'path/to/some/dir/' ) will throw [ArgumentError].
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

  /// Optional rotation policy (null = no rotation).
  final FileRotation? fileRotation;

  @override
  final bool enabled;

  @override
  Future<void> output(final List<String> lines, final LogLevel level) async {
    if (lines.isEmpty) {
      return;
    }
    final file = Context.fileSystem.file(basePath);
    try {
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      final newData = '${lines.join('\n')}\n';
      if (fileRotation != null &&
          await fileRotation!.needsRotation(file, newData)) {
        await fileRotation!.rotate(basePath);
      }
      await file.writeAsString(
        newData,
        mode: io.FileMode.append,
        flush: true,
      );
    } catch (e, s) {
      if (!const bool.fromEnvironment('dart.vm.product')) {
        rethrow;
      }
      Logger.get().error(
        'FileSink error (path: $basePath)',
        error: e,
        stackTrace: s,
      );
    }
  }
}
