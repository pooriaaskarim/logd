part of '../handler.dart';

/// A [LogEngine] that targets native platforms via FFI.
///
/// [NativeEngine] standardizes the [LogDocument] into a [BinaryIR] instruction
/// stream before passing it to a native shared library for high-performance
/// rendering.
class NativeEngine implements LogEngine {
  /// Creates a [NativeEngine].
  const NativeEngine();

  @override
  LogPipelineFactory get factory => Arena.instance;

  @override
  Future<void> execute(
    final LogEntry entry,
    final LogFormatter formatter,
    final List<LogDecorator> decorators,
    final LogSink sink,
  ) async {
    final arena = Arena.instance;
    final document = arena.checkoutDocument() as ArenaDocument;

    try {
      // 1. Determine Execution Mode
      // If no decorators are present, we use "Streaming Mode" to bypass
      // object allocation entirely.
      if (decorators.isEmpty) {
        document.enableStreaming();
      }

      // 2. Format
      formatter.format(entry, document, arena);

      // 3. Finalize/Standardize
      final ffi.Pointer<ffi.Uint8> irPtr;
      if (document.isStreaming) {
        irPtr = document.writer.finalize();
      } else {
        // Standard Path: Apply decorators to the object tree
        if (decorators.isNotEmpty) {
          DecoratorPipeline(decorators).apply(document, entry, arena);
        }
        irPtr = document.writer.write(document);
      }

      // 4. Output
      if (sink is NativeIsolateSink && document.isStreaming) {
        // 4a. Backpressure: Wait for pool capacity if needed
        await arena.waitForPoolCapacity();

        // THE FAST PATH: Offload EVERYTHING (Rendering + I/O) to the isolate
        final width = sink.target.preferredWidth ?? 80;
        final packet =
            arena.checkoutNativePacket(document, terminalWidth: width);
        sink.dispatchPacket(packet);
        arena.resetNative(document); // Buffer already moved to in-flight
      } else if (sink is EncodingSink &&
          (sink.encoder is AnsiEncoder || sink.encoder is AutoConsoleEncoder) &&
          !document.metadata.containsKey('toon_columns')) {
        // Standard Path: Render locally and delegate to sink
        const binaryEncoder = BinaryAnsiEncoder();
        final output = binaryEncoder.encode(
          irPtr,
          terminalWidth: sink.preferredWidth ?? 80,
          level: entry.level,
        );
        final data = convert.utf8.encode(output);
        await sink.delegate(data);
      } else {
        // Fallback to standard engine for any other sink types
        await const StandardEngine()
            .execute(entry, formatter, decorators, sink);
      }
    } finally {
      // 5. Release
      document.releaseRecursive(arena);
    }
  }
}
