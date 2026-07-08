library;

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../logger/logger.dart';
import '../document/binary_ir_native.dart';
import '../document/document.dart';
import '../engine/arena_native.dart';
import '../engine/engine.dart';
import '../engine/native_engine_native.dart';
import '../sink/sink.dart';

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
      IsolateLog(
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

      _commandPort!.send(IsolateCommand.stop(callback.sendPort));
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
      if (message is IsolateLog) {
        final data = message.data.materialize().asUint8List();
        const factory = StandardPipelineFactory();
        await target.output(data, message.entry, message.level, factory);
      } else if (message is IsolateCommand) {
        if (message.type == CommandType.stop) {
          await target.dispose();
          message.replyPort?.send(null);
          receivePort.close();
        }
      }
    });
  }
}

@internal
class IsolateLog {
  IsolateLog({
    required this.data,
    required this.entry,
    required this.level,
  });
  final TransferableTypedData data;
  final LogEntry entry;
  final LogLevel level;
}

@internal
enum CommandType { stop }

@internal
class IsolateCommand {
  IsolateCommand.stop(this.replyPort) : type = CommandType.stop;
  final CommandType type;
  final SendPort? replyPort;
}

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

  /// Exposes the background worker Isolate for testing.
  @visibleForTesting
  Isolate? get isolate => _isolate;

  final Completer<void> _ready = Completer<void>();
  final List<Object> _buffer = [];
  bool _workerDead = false;

  /// Exposes whether the worker has crashed/died.
  @visibleForTesting
  bool get workerDead => _workerDead;

  bool _isDisposed = false;
  bool _bufferOverflowWarningFired = false;
  static const int _maxPreReadyBuffer = 200;

  Future<void> _start() async {
    _workerDead = false;
    final receivePort = ReceivePort();
    _errorPort = ReceivePort();

    _isolate = await Isolate.spawn(
      spawnNativeWorker,
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
      _workerDead = true;
      _commandPort = null;
      _errorPort?.close();
      _errorPort = null;

      // Attempt to restart if not disposed
      if (!_isDisposed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed) {
            _start();
          }
        });
      }
    });

    _commandPort = await receivePort.first as SendPort;

    // Flush buffer
    for (final msg in _buffer) {
      _commandPort!.send(msg);
    }
    _buffer.clear();

    if (!_ready.isCompleted) {
      _ready.complete();
    }
  }

  /// Dispatches a [NativePacket] directly to the worker isolate.
  ///
  /// This method bypasses the standard [output] path and is called
  /// by the [NativeEngine].
  @internal
  void dispatchPacket(final NativePacket packet) {
    if (_workerDead || !enabled) {
      packet.completionPort.send(packet.address);
      return;
    }
    if (_commandPort != null) {
      _commandPort!.send(packet);
    } else {
      if (_buffer.length >= _maxPreReadyBuffer) {
        final dropped = _buffer.removeAt(0);
        if (dropped is NativePacket) {
          dropped.completionPort.send(dropped.address);
        }
        if (!_bufferOverflowWarningFired) {
          _bufferOverflowWarningFired = true;
          InternalLogger.log(
            LogLevel.warning,
            'NativeIsolateSink buffer overflowed. '
            'Dropping oldest native packets.',
          );
        }
      }
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
    if (!enabled || _workerDead) {
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
    if (_workerDead) {
      return;
    }
    final copy = Uint8List.fromList(data);
    final transferable = TransferableTypedData.fromList([copy]);
    final msg = IsolateLog(
      data: transferable,
      entry: entry,
      level: level,
    );

    if (_commandPort != null) {
      _commandPort!.send(msg);
    } else {
      if (_buffer.length >= _maxPreReadyBuffer) {
        _buffer.removeAt(0);
        if (!_bufferOverflowWarningFired) {
          _bufferOverflowWarningFired = true;
          InternalLogger.log(
            LogLevel.warning,
            'NativeIsolateSink buffer overflowed. Dropping oldest log entries.',
          );
        }
      }
      _buffer.add(msg);
    }
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    if (_commandPort != null) {
      final callback = ReceivePort();
      _commandPort!.send(IsolateCommand.stop(callback.sendPort));
      await callback.first;
      callback.close();
    }

    _isolate?.kill();
    _errorPort?.close();
    for (final msg in _buffer) {
      if (msg is NativePacket) {
        msg.completionPort.send(msg.address);
      }
    }
    _buffer.clear();
    Arena.instance.reclaimInFlightBuffers();
    await super.dispose();
  }
}
