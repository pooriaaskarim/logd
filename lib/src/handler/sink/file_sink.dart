part of '../handler.dart';

/// File Rotation Handler.
///
/// Rotates log files based on a trigger.
abstract class FileRotation {
  const FileRotation({
    this.compress = false,
    this.backupCount = 5,
  }) : assert(backupCount >= 0, 'backupCount must be >= 0.');

  /// Whether to gzip compress rotated files.
  final bool compress;

  /// Number of backup files to keep (deletes oldest if exceeded; 0 = no limit).
  final int backupCount;

  /// Check if rotation is needed before appending new data.
  Future<bool> needsRotation(final io.File currentFile, final String newData);

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
  factory SizeRotation({
    final String maxSize = '512 KB',
    final bool compress = false,
    final int backupCount = 5,
  }) {
    final bytes = SizeRotation.parseMaxSizeLiteral(maxSize);
    return SizeRotation._(
      maxBytes: bytes,
      compress: compress,
      backupCount: backupCount,
    );
  }

  const SizeRotation._({
    required this.maxBytes,
    super.compress,
    super.backupCount,
  }) : assert(maxBytes > 0, 'maxBytes must be > 0');

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
    final io.File currentFile,
    final String newData,
  ) async {
    final currentLength =
        await currentFile.exists() ? await currentFile.length() : 0;
    final newDataSize = utf8.encode(newData).length;
    return currentLength + newDataSize > maxBytes;
  }

  @override
  Future<void> rotate(final String basePath) async {
    final file = io.File(basePath);
    if (!await file.exists()) {
      return;
    }
    final extension = compress ? '.gz' : '';
    final ext = basePath.substring(basePath.lastIndexOf('.'));
    final baseWithoutExt = basePath.substring(0, basePath.lastIndexOf('.'));
    if (backupCount > 0) {
      // Shift backups: .N -> .(N+1)
      for (int i = backupCount - 1; i >= 1; i--) {
        final oldPath = '$baseWithoutExt.$i$ext$extension';
        final newPath = '$baseWithoutExt.${i + 1}$ext$extension';
        final oldFile = io.File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.rename(newPath);
        }
      }
      // Move current to .1
      final backupPath = '$baseWithoutExt.1$ext';
      await file.rename(backupPath);
      if (compress) {
        final bytes = await io.File(backupPath).readAsBytes();
        final gzBytes = io.GZipCodec().encode(bytes);
        await io.File('$backupPath.gz').writeAsBytes(gzBytes);
        await io.File(backupPath).delete();
      }
      // Cleanup excess
      final dir = file.parent;
      final entities = await dir.list().toList();
      final backupFiles = entities
          .where(
            (final e) =>
                e is io.File &&
                RegExp(r'^\w+\.\d+' + RegExp.escape(ext) + r'(\.gz)?$')
                    .hasMatch(e.path.split('/').last),
          )
          .cast<io.File>()
          .toList()
        ..sort((final a, final b) {
          final aMatch = RegExp(r'\.(\d+)').firstMatch(a.path);
          final bMatch = RegExp(r'\.(\d+)').firstMatch(b.path);
          final aIndex =
              aMatch != null ? int.tryParse(aMatch.group(1)!) ?? 0 : 0;
          final bIndex =
              bMatch != null ? int.tryParse(bMatch.group(1)!) ?? 0 : 0;
          return aIndex.compareTo(bIndex); // Ascending: smallest (newest) first
        });
      while (backupFiles.length > backupCount) {
        await backupFiles.removeLast().delete();
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
    super.compress,
    super.backupCount,
  }) : assert(
          !interval.isNegative && interval > Duration.zero,
          'Interval must be positive',
        );

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
    final io.File currentFile,
    final String newData,
  ) async {
    await _initLastRotation(currentFile);
    final now = Time.timeProvider();
    return now.difference(lastRotation!) >= interval;
  }

  @override
  Future<void> rotate(final String basePath) async {
    final oldTime = lastRotation!;
    final suffix =
        timestamp.getTimestamp() ?? oldTime.toIso8601String().split('T')[0];
    final ext = basePath.substring(basePath.lastIndexOf('.'));
    final baseWithoutExt = basePath.substring(0, basePath.lastIndexOf('.'));
    final rotatedPath = '$baseWithoutExt-$suffix$ext';
    final file = io.File(basePath);
    if (await file.exists()) {
      await file.rename(rotatedPath);
      if (compress) {
        final bytes = await io.File(rotatedPath).readAsBytes();
        final gzBytes = io.GZipCodec().encode(bytes);
        await io.File('$rotatedPath.gz').writeAsBytes(gzBytes);
        await io.File(rotatedPath).delete();
      }
    }
    lastRotation = Time.timeProvider();
    if (backupCount > 0) {
      // Cleanup: Find rotated files, sort by date in name, delete oldest
      final dir = file.parent;
      final entities = await dir.list().toList();
      final extension = compress ? '.gz' : '';
      final logFiles = entities
          .where(
            (final e) =>
                e is io.File &&
                e.path.startsWith('$baseWithoutExt-') &&
                e.path.endsWith('$ext$extension'),
          )
          .cast<io.File>()
          .toList();
      final datedFiles = <Map<String, dynamic>>[];
      for (final f in logFiles) {
        final name = f.path.split('/').last.replaceAll('$ext$extension', '');
        final dateStr = name.substring(name.lastIndexOf('-') + 1);
        // Parse date based on formatter; assume ISO-like
        final dt = DateTime.tryParse(dateStr) ?? DateTime(0);
        datedFiles.add({'file': f, 'date': dt});
      }
      datedFiles.sort(
        (final a, final b) => b['date'].compareTo(a['date']),
      ); // Newest first
      while (datedFiles.length > backupCount) {
        await datedFiles.removeLast()['file'].delete();
      }
    }
  }

  Future<void> _initLastRotation(final io.File currentFile) async {
    if (lastRotation != null) {
      return;
    }
    if (await currentFile.exists()) {
      lastRotation = await currentFile.lastModified();
    } else {
      lastRotation = Time.timeProvider();
    }
  }
}

/// Appends to a file asynchronously, with optional rotation.
class FileSink implements LogSink {
  FileSink(
    this.basePath, {
    this.fileRotation,
    this.enabled = true,
  });

  /// Path to the current log file (e.g., 'logs/app.log').
  /// Rotated files will be named based on [FileRotation]
  /// (e.g., app-2025-11-11.log or app.1.log).
  final String basePath;

  /// Optional rotation policy (null = no rotation).
  final FileRotation? fileRotation;

  @override
  final bool enabled;

  @override
  Future<void> output(final List<String> lines, final LogLevel level) async {
    if (lines.isEmpty) {
      return;
    }
    final file = io.File(basePath);
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
      await file.writeAsString(newData, mode: io.FileMode.append);
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
