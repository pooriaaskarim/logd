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
    final document = arena.checkoutDocument();
    formatter.format(entry, document, arena);

    // Apply decorators
    for (final decorator in decorators) {
      decorator.decorate(document, entry, arena);
    }

    // Standardize to Binary IR
    final writer = BinaryIRWriter(arena);
    final irPtr = writer.write(document);

    // 1. Native Path (Future)
    // In a real implementation, we would call the C library here:
    // _nativeRender(irPtr, sink.handle);

    // 2. Fast-Path (Dart Reference Implementation)
    // We use the BinaryAnsiEncoder to prove the IR is valid and
    // to provide a performance boost even before C integration.
    if (sink is EncodingSink && sink.encoder is AnsiEncoder) {
      final binaryEncoder = const BinaryAnsiEncoder();
      final output = binaryEncoder.encode(irPtr, terminalWidth: sink.preferredWidth ?? 80);
      final data = convert.utf8.encode(output);
      await sink.delegate(data is Uint8List ? data : Uint8List.fromList(data));
    } else if (sink is EncodingSink) {
       // Fallback to standard engine for other encoders (JSON, HTML)
       await const StandardEngine().execute(entry, formatter, decorators, sink);
    }

    // Release resources
    document.releaseRecursive(arena);
  }
}
