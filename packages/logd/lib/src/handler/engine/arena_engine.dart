part of '../native_handler.dart';

/// A [LogEngine] that utilizes LIFO object pooling via [Arena].
///
/// This implementation is designed for high-throughput, low-latency
/// environments. By reusing objects across log cycles, it significantly
/// reduces allocation overhead and main-thread GC pressure.
///
/// **Constraints**:
/// - [LogDocument]s must not be retained beyond the log cycle.
/// - Sinks should ideally be [IsolateSink]s to maximize the benefit of
///   asynchronous I/O.
class ArenaEngine implements LogEngine {
  const ArenaEngine();

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

    try {
      // 1. Format: Populate the document using arena as factory
      formatter.format(entry, document, arena);

      // 2. Decorate: Transform document in-place
      if (decorators.isNotEmpty) {
        DecoratorPipeline(decorators).apply(document, entry, arena);
      }

      // 3. Output: Emission
      if (document.nodes.isNotEmpty) {
        await sink.output(document, entry, entry.level, factory);
      }
    } finally {
      // 4. Deterministic release: Always return entire tree to pool
      document.releaseRecursive(arena);
    }
  }
}
