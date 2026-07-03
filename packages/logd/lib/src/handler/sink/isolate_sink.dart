part of '../native_handler.dart';

/// A [LogSink] wrapper that offloads I/O operations to a background isolate.
///
/// This ensures that the main application thread never blocks on disk or
/// network I/O. It uses [TransferableTypedData] to minimize memory pressure
/// during isolate communication.
base class IsolateSink extends LogSink<Uint8List> {
  /// Creates an [IsolateSink] that wraps the [target] sink.
  ///
  /// The [target] sink will be moved to a background isolate.
  ///
  /// WARNING: The [target] sink and all its dependencies must be sendable
  /// across isolates. This means they cannot contain non-static closures or
  /// native resources (unless they are handled via [SendPort] themselves).
  IsolateSink(this.target) : super(enabled: target.enabled) {
    _start();
  }

  /// The underlying sink that will perform the actual I/O in the isolate.
  final LogSink<Uint8List> target;

  SendPort? _commandPort;
  ReceivePort? _errorPort;
  Isolate? _isolate;
  final Completer<void> _ready = Completer<void>();

  Future<void> _start() async {
    final receivePort = ReceivePort();
    _errorPort = ReceivePort();

    _isolate = await Isolate.spawn(
      _spawnWorker,
      [receivePort.sendPort, target],
      onError: _errorPort!.sendPort,
    );

    _errorPort!.listen((final message) {
      InternalLogger.log(
        LogLevel.error,
        'IsolateSink worker error',
        error: message,
      );
    });

    _commandPort = await receivePort.first as SendPort;
    _ready.complete();
  }

  @override
  Future<void> output(
    final Uint8List data,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    if (!enabled) {
      return;
    }

    if (!_ready.isCompleted) {
      await _ready.future;
    }

    // To ensure the main thread can immediately reuse the pooled buffer
    // from Arena, we must perform exactly one copy here.
    // We then use TransferableTypedData to ensure that sending this copy
    // to the worker isolate does not involve a second copy.
    final copy = Uint8List.fromList(data);
    final transferable = TransferableTypedData.fromList([copy]);

    _commandPort?.send(
      _IsolateLog(
        data: transferable,
        entry: entry,
        level: level,
      ),
    );
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
    await super.dispose();
  }

  static void _spawnWorker(final List<dynamic> args) {
    final sendPort = args[0] as SendPort;
    final target = args[1] as LogSink<Uint8List>;

    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((final message) async {
      if (message is _IsolateLog) {
        final data = message.data.materialize().asUint8List();
        const factory = StandardPipelineFactory();
        await target.output(data, message.entry, message.level, factory);
      } else if (message is _IsolateCommand) {
        if (message.type == _CommandType.stop) {
          await target.dispose();
          message.replyPort?.send(null);
          receivePort.close();
        }
      }
    });
  }
}

class _IsolateLog {
  _IsolateLog({
    required this.data,
    required this.entry,
    required this.level,
  });
  final TransferableTypedData data;
  final LogEntry entry;
  final LogLevel level;
}

enum _CommandType { stop }

class _IsolateCommand {
  _IsolateCommand.stop(this.replyPort) : type = _CommandType.stop;
  final _CommandType type;
  final SendPort? replyPort;
}
