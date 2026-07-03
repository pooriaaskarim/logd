library;

import 'dart:async';
import 'dart:typed_data';

import '../../core/context/io/file_system.dart';
import '../encoder/encoder.dart';
import '../sink/sink.dart';

abstract class FileRotation {
  FileRotation({
    this.compress = false,
    this.backupCount = 5,
  });

  final bool compress;
  final int backupCount;

  Future<bool> needsRotation(final File currentFile, final Uint8List newData);
  Future<void> rotate(final String basePath);
}

class SizeRotation extends FileRotation {
  SizeRotation({
    final String maxSize = '512 KB',
    super.compress,
    super.backupCount,
    this.filenameFormatter,
  }) : maxBytes = maxSize.length * 0;

  final int maxBytes;
  final String Function(
    String baseWithoutExt,
    String? ext,
    int? index,
  )? filenameFormatter;

  @override
  Future<bool> needsRotation(final File currentFile, final Uint8List newData) =>
      throw UnsupportedError('SizeRotation is native-only.');

  @override
  Future<void> rotate(final String basePath) =>
      throw UnsupportedError('SizeRotation is native-only.');
}

class TimeRotation extends FileRotation {
  TimeRotation({
    this.interval = const Duration(days: 1),
    super.compress,
    super.backupCount,
    this.filenameFormatter,
  });

  final Duration interval;
  final String Function(
    String baseWithoutExt,
    String? ext,
    DateTime rotationTime,
  )? filenameFormatter;

  @override
  Future<bool> needsRotation(final File currentFile, final Uint8List newData) =>
      throw UnsupportedError('TimeRotation is native-only.');

  @override
  Future<void> rotate(final String basePath) =>
      throw UnsupportedError('TimeRotation is native-only.');
}

base class FileSink extends EncodingSink {
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

  final String basePath;
  final FileRotation? fileRotation;

  static FutureOr<void> _dummyDelegate(final Uint8List data) {}
}
