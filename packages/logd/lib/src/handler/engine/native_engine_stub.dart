library;

import '../../logger/logger.dart';
import '../decorator/decorator.dart';
import '../engine/engine.dart';
import '../formatter/formatter.dart';
import '../sink/sink.dart';

/// A fallback stub for [NativeEngine] on unsupported platforms (like Web).
///
/// Attempting to use this engine on non-native platforms will result in an
/// [UnsupportedError] pointing the user to cross-platform alternatives.
class NativeEngine implements LogEngine {
  /// Creates a [NativeEngine] stub.
  NativeEngine();

  @override
  LogPipelineFactory get factory => throw UnsupportedError(
        'NativeEngine is only supported on native platforms (VM/Desktop/Mobile) '
        'because it relies on low-level FFI hooks. For Web/JS/WASM compatibility, '
        'please use StandardEngine instead.',
      );

  @override
  Future<void> execute(
    final LogEntry entry,
    final LogFormatter formatter,
    final List<LogDecorator> decorators,
    final LogSink sink,
  ) =>
      throw UnsupportedError(
        'NativeEngine is only supported on native platforms (VM/Desktop/Mobile) '
        'because it relies on low-level FFI hooks. For Web/JS/WASM compatibility, '
        'please use StandardEngine instead.',
      );
}

/// A fallback stub for [ArenaEngine] on unsupported platforms (like Web).
///
/// Attempting to use this engine on non-native platforms will result in an
/// [UnsupportedError] pointing the user to cross-platform alternatives.
class ArenaEngine implements LogEngine {
  /// Creates an [ArenaEngine] stub.
  const ArenaEngine();

  @override
  LogPipelineFactory get factory => throw UnsupportedError(
        'ArenaEngine is only supported on native platforms (VM/Desktop/Mobile) '
        'because it relies on FFI-backed memory arenas for zero-copy output. '
        'For Web/JS/WASM compatibility, please use StandardEngine instead.',
      );

  @override
  Future<void> execute(
    final LogEntry entry,
    final LogFormatter formatter,
    final List<LogDecorator> decorators,
    final LogSink sink,
  ) =>
      throw UnsupportedError(
        'ArenaEngine is only supported on native platforms (VM/Desktop/Mobile) '
        'because it relies on FFI-backed memory arenas for zero-copy output. '
        'For Web/JS/WASM compatibility, please use StandardEngine instead.',
      );
}
