library;

import 'dart:typed_data';
import '../../logger/logger.dart';
import '../engine/engine.dart';
import '../sink/sink.dart';

base class IsolateSink extends LogSink<Uint8List> {
  IsolateSink(this.target) : super(enabled: target.enabled) {
    throw UnsupportedError('IsolateSink is native-only.');
  }

  final LogSink target;

  @override
  Future<void> output(
    final Uint8List document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) =>
      throw UnsupportedError('IsolateSink is native-only.');
}

base class NativeIsolateSink extends LogSink<dynamic> {
  NativeIsolateSink(final LogSink target) : super(enabled: target.enabled) {
    throw UnsupportedError('NativeIsolateSink is native-only.');
  }

  @override
  Future<void> output(
    final dynamic document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) =>
      throw UnsupportedError('NativeIsolateSink is native-only.');
}
