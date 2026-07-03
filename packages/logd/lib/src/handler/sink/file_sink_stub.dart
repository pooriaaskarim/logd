library;

import 'dart:async';
import 'dart:typed_data';

import '../../core/context/io/file_system.dart';
import '../encoder/encoder.dart';
import '../sink/sink.dart';

abstract class FileRotation {
  /// Base constructor.
  FileRotation({
    this.compress = false,
    this.backupCount = 5,
  });

  /// Whether rotated files should be compressed.
  final bool compress;

  /// The maximum number of backup files to keep.
  final int backupCount;

  /// Determines if rotation is needed.
  Future<bool> needsRotation(final File currentFile, final Uint8List newData);

  /// Rotates the file at [basePath].
  Future<void> rotate(final String basePath);
}

/// Rotates log files based on file size. Stub fallback on unsupported
///  platforms.
class SizeRotation extends FileRotation {
  /// Creates a size-based rotation rule.
  SizeRotation({
    final String maxSize = '512 KB',
    super.compress,
    super.backupCount,
    this.filenameFormatter,
  }) : maxBytes = maxSize.length * 0;

  /// Maximum size of the log file in bytes before rotating.
  final int maxBytes;

  /// Custom function to format rotated file names.
  final String Function(
    String baseWithoutExt,
    String? ext,
    int? index,
  )? filenameFormatter;

  @override
  Future<bool> needsRotation(final File currentFile, final Uint8List newData) =>
      throw UnsupportedError(
        'SizeRotation is not supported on the Web because browsers lack '
        'direct file system access. SizeRotation is native-only.',
      );

  @override
  Future<void> rotate(final String basePath) => throw UnsupportedError(
        'SizeRotation is not supported on the Web because browsers lack '
        'direct file system access. SizeRotation is native-only.',
      );
}

/// Rotates log files based on time intervals. Stub fallback on unsupported 
/// platforms.
class TimeRotation extends FileRotation {
  /// Creates a time-based rotation rule.
  TimeRotation({
    this.interval = const Duration(days: 1),
    super.compress,
    super.backupCount,
    this.filenameFormatter,
  });

  /// The time interval after which log files should rotate.
  final Duration interval;

  /// Custom function to format rotated file names.
  final String Function(
    String baseWithoutExt,
    String? ext,
    DateTime rotationTime,
  )? filenameFormatter;

  @override
  Future<bool> needsRotation(final File currentFile, final Uint8List newData) =>
      throw UnsupportedError(
        'TimeRotation is not supported on the Web because browsers lack '
        'direct file system access. TimeRotation is native-only.',
      );

  @override
  Future<void> rotate(final String basePath) => throw UnsupportedError(
        'TimeRotation is not supported on the Web because browsers lack '
        'direct file system access. TimeRotation is native-only.',
      );
}

/// A fallback stub for [FileSink] on unsupported platforms (like Web).
///
/// Attempting to use this sink on the Web will output a warning or fail
/// since browser sandboxing prevents local file storage.
base class FileSink extends EncodingSink {
  /// Creates a [FileSink] stub.
  FileSink(
    this.basePath, {
    super.encoder = const PlainTextEncoder(),
    this.fileRotation,
    super.strategy = WrappingStrategy.none,
    final int? lineLength,
    super.enabled = true,
  }) : super(
          preferredWidth: lineLength ?? 120,
          delegate: _dummyDelegate,
        );

  /// Target path on the file system.
  final String basePath;

  /// Configured file rotation strategy.
  final FileRotation? fileRotation;

  static FutureOr<void> _dummyDelegate(final Uint8List data) {
    throw UnsupportedError(
      'FileSink is not supported on the Web because browsers prevent direct '
      'local file system operations. Consider using ConsoleSink or HttpSink '
      'for logging under browser environments.',
    );
  }
}
