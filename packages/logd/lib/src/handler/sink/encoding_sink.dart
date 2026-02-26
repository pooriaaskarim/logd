part of '../handler.dart';

/// Defines how a [LogSink] should wrap its encoded log entries.
enum WrappingStrategy {
  /// No wrapping is applied. Each entry is emitted as a standalone snippet.
  none,

  /// The entire logging session is wrapped in a document (e.g., HTML shell).
  ///
  /// The [LogEncoder.preamble] is triggered on the first log write, and
  /// [LogEncoder.postamble] can be triggered during sink disposal or session
  /// finalization.
  document,
}

/// A [LogSink] that encodes logs using an interchangeable [LogEncoder].
///
/// This base class serves as the final orchestration point where semantic
/// [LogDocument]s are serialized into physical data (e.g., String, JSON Map)
/// before being written to a medium (Console, File, Network).
///
/// By separating the [encoder] from the transport logic, [EncodingSink] enables
/// "Medium-Centric" sinking—a single sink implementation can support multiple
/// output formats by swapping its encoder.
base class EncodingSink extends LogSink<LogDocument> {
  /// Creates an [EncodingSink].
  ///
  /// - [encoder]: The encoder to serialize LogDocuments into bytes.
  /// - [delegate]: The transport callback.
  /// - [strategy]: The wrapping strategy for this sink (default:
  /// [WrappingStrategy.none]).
  /// - [preferredWidth]: The preferred width for wrapping logs (default: 100).
  const EncodingSink({
    required this.encoder,
    required this.delegate,
    this.strategy = WrappingStrategy.none,
    this.preferredWidth = 100,
    super.enabled,
  });

  /// The encoder used to serialize logs.
  final LogEncoder encoder;

  /// The transport callback.
  final FutureOr<void> Function(Uint8List data) delegate;

  /// The wrapping strategy for this sink.
  final WrappingStrategy strategy;

  /// The maximum line length for the output.
  final int? preferredWidth;

  static final Expando<bool> _preambleFlags = Expando();

  bool get _preambleWritten => _preambleFlags[this] ?? false;
  set _preambleWritten(final bool value) => _preambleFlags[this] = value;

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
  ) async {
    if (!enabled) {
      return;
    }

    final context = LogArena.instance.checkoutContext();

    try {
      // Trigger preamble if needed
      if (strategy == WrappingStrategy.document && !_preambleWritten) {
        encoder.preamble(context, level, document: document);
        _preambleWritten = true;
      }

      // Pass the entry and document to the encoder
      encoder.encode(
        entry,
        document,
        level,
        context,
        width: preferredWidth,
      );

      // Standard record delimiter: every record gets exactly one trailing \n
      if (context.length > 0) {
        context.addByte(0x0A);
      }

      final data = context.takeBytes();
      if (data.isNotEmpty) {
        await delegate(data);
      }
    } finally {
      LogArena.instance.release(context);
    }
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    if (strategy == WrappingStrategy.document && _preambleWritten) {
      final context = HandlerContext();
      // We don't have a specific level for postamble, use Info as safe default
      encoder.postamble(context, LogLevel.info);
      final data = context.takeBytes();
      if (data.isNotEmpty) {
        await delegate(data);
      }
    }
    await super.dispose();
  }
}
