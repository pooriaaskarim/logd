library;

import '../../logger/logger.dart';
import '../decorator/decorator.dart';
import '../engine/engine.dart';
import '../formatter/formatter.dart';
import '../sink/sink.dart';

class NativeEngine implements LogEngine {
  const NativeEngine();

  @override
  LogPipelineFactory get factory =>
      throw UnsupportedError('NativeEngine is native-only.');

  @override
  Future<void> execute(
    final LogEntry entry,
    final LogFormatter formatter,
    final List<LogDecorator> decorators,
    final LogSink sink,
  ) =>
      throw UnsupportedError('NativeEngine is native-only.');
}

class ArenaEngine implements LogEngine {
  const ArenaEngine();

  @override
  LogPipelineFactory get factory =>
      throw UnsupportedError('ArenaEngine is native-only.');

  @override
  Future<void> execute(
    final LogEntry entry,
    final LogFormatter formatter,
    final List<LogDecorator> decorators,
    final LogSink sink,
  ) =>
      throw UnsupportedError('ArenaEngine is native-only.');
}
