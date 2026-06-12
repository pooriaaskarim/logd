part of '../handler.dart';

/// A specialized [LogSink] that offloads Native B-IR rendering and I/O
/// to a background isolate.
///
/// Use [NativeIsolateSink] when using [NativeEngine] to achieve zero-latency
/// logging on the main thread.
base class NativeIsolateSink extends LogSink<dynamic> {
  /// Creates a [NativeIsolateSink] wrapping the [target].
  NativeIsolateSink(this.target) : super(enabled: target.enabled) {
    _start();
  }

  /// The underlying sink that performs the final byte I/O.
  final EncodingSink target;

  SendPort? _commandPort;
  ReceivePort? _errorPort;
  Isolate? _isolate;
  final Completer<void> _ready = Completer<void>();
  final List<Object> _buffer = [];

  Future<void> _start() async {
    final receivePort = ReceivePort();
    _errorPort = ReceivePort();

    _isolate = await Isolate.spawn(
      _spawnNativeWorker,
      [receivePort.sendPort, target],
      onError: _errorPort!.sendPort,
    );

    _errorPort!.listen((final message) {
      InternalLogger.log(
        LogLevel.error,
        'NativeIsolateSink worker error',
        error: message,
      );
      // Reclaim buffers to prevent leaks if the worker died
      Arena.instance.reclaimInFlightBuffers();
    });

    _commandPort = await receivePort.first as SendPort;

    // Flush buffer
    for (final msg in _buffer) {
      _commandPort!.send(msg);
    }
    _buffer.clear();

    _ready.complete();
  }

  /// Dispatches a [NativePacket] directly to the worker isolate.
  ///
  /// This method bypasses the standard [output] path and is called
  /// by the [NativeEngine].
  @internal
  void dispatchPacket(final NativePacket packet) {
    if (!enabled) {
      return;
    }
    if (_commandPort != null) {
      _commandPort!.send(packet);
    } else {
      _buffer.add(packet);
    }
  }

  @override
  Future<void> output(
    final dynamic data,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    if (!enabled) {
      return;
    }

    if (data is LogDocument) {
      final context = factory.checkoutContext();
      try {
        target.encoder.encode(
          entry,
          data,
          level,
          context,
          factory,
          width: target.preferredWidth,
        );
        final bytes = context.takeBytes();
        _sendBytes(bytes, entry, level);
      } finally {
        factory.release(context);
      }
    } else if (data is Uint8List) {
      _sendBytes(data, entry, level);
    }
  }

  void _sendBytes(
    final Uint8List data,
    final LogEntry entry,
    final LogLevel level,
  ) {
    final copy = Uint8List.fromList(data);
    final transferable = TransferableTypedData.fromList([copy]);
    final msg = _IsolateLog(
      data: transferable,
      entry: entry,
      level: level,
    );

    if (_commandPort != null) {
      _commandPort!.send(msg);
    } else {
      _buffer.add(msg);
    }
  }

  @override
  Future<void> dispose() async {
    if (_commandPort != null) {
      final callback = ReceivePort();
      _commandPort!.send(_IsolateCommand.stop(callback.sendPort));
      await callback.first;
      callback.close();
    }

    _isolate?.kill();
    _errorPort?.close();
    Arena.instance.reclaimInFlightBuffers();
    await super.dispose();
  }
}
