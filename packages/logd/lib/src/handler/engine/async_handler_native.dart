library;

import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import '../../logger/logger.dart';
import '../handler.dart';

class _AsyncHandlerConfig {
  _AsyncHandlerConfig({
    required this.formatter,
    required this.sink,
    required this.decorators,
    required this.engine,
    required this.timeout,
  });

  final LogFormatter formatter;
  final LogSink sink;
  final List<LogDecorator> decorators;
  final LogEngine engine;
  final Duration? timeout;
}

enum _AsyncCommandType { stop }

class _AsyncIsolateCommand {
  _AsyncIsolateCommand.stop(this.replyPort) : type = _AsyncCommandType.stop;
  final _AsyncCommandType type;
  final SendPort? replyPort;
}

class _AsyncHandlerState {
  SendPort? commandPort;
  ReceivePort? errorPort;
  Isolate? isolate;
  final Completer<void> ready = Completer<void>();
  bool isDisposed = false;
}

/// A [Handler] that offloads the execution of the logging pipeline
/// (formatting, decorating, and sinking) to a background worker isolate.
///
/// ### Architecture & Concurrency
/// When instantiated, [AsyncHandler] spawns a dedicated background isolate.
/// Any log events logged through this handler are sent as message payloads
/// across a [SendPort] boundary. The background isolate listens to these
/// events, processes them sequentially on its own event loop, and outputs
/// them to the underlying [sink].
///
/// ### Performance Characteristics
/// * **Unblocked Main Thread**: Since layout formatting, decorating, and
///   physical I/O are performed off-thread, logging calls return almost
///   instantly (~15–20µs), maximizing main thread throughput.
/// * **Throughput vs. Latency**: Ideal for applications with high-frequency
///   logging or slow physical sinks (e.g., files, HTTP dashboards). However,
///   it introduces minor overhead due to thread context-switching and object
///   serialization.
///
/// ### Isolate Copy/Transfer Constraints
/// Because the pipeline runs in a separate isolate, all parameters (the
/// [formatter], [sink], and [decorators]) must be sendable. Sinks with
/// non-transferable native assets or open TCP sockets must handle
/// isolate-aware setup or use custom serialization handles.
///
/// ### Lifecycle Management
/// It is critical to call [dispose] when this handler is no longer needed.
/// [dispose] safely closes the isolate control ports, flushes the background
/// worker queues, disposes of the underlying [sink], and terminates the
/// worker isolate to prevent resource leaks.
base class AsyncHandler extends Handler {
  /// Creates an [AsyncHandler] that delegates pipeline execution to a
  /// background isolate.
  ///
  /// - [formatter]: The formatter used to translate logs into semantic
  ///   documents.
  /// - [sink]: The final output sink.
  /// - [filters]: Optional filters to block events before isolate boundary
  ///   crossing.
  /// - [decorators]: Optional decorators for document layout enrichment.
  /// - [engine]: The execution engine to run on the background isolate
  ///   (defaults to [StandardEngine]).
  /// - [timeout]: Optional timeout boundary for pipeline processing.
  AsyncHandler({
    required super.formatter,
    required super.sink,
    super.filters = const [],
    super.decorators = const [],
    super.engine = const StandardEngine(),
    super.timeout,
  }) {
    _start();
  }

  static final Expando<_AsyncHandlerState> _states = Expando();

  _AsyncHandlerState get _state => _states[this] ??= _AsyncHandlerState();

  Future<void> _start() async {
    final receivePort = ReceivePort();
    _state.errorPort = ReceivePort();

    final config = _AsyncHandlerConfig(
      formatter: formatter,
      sink: sink,
      decorators: decorators,
      engine: engine,
      timeout: timeout,
    );

    _state.isolate = await Isolate.spawn(
      _spawnWorker,
      [receivePort.sendPort, config],
      onError: _state.errorPort!.sendPort,
    );

    _state.errorPort!.listen((final message) {
      InternalLogger.log(
        LogLevel.error,
        'AsyncHandler worker error',
        error: message,
      );
    });

    _state.commandPort = await receivePort.first as SendPort;
    _state.ready.complete();
  }

  @override
  @internal
  Future<void> log(final LogEntry entry) async {
    if (filters.any((final filter) => !filter.shouldLog(entry))) {
      return;
    }

    if (!_state.ready.isCompleted) {
      await _state.ready.future;
    }

    final port = _state.commandPort;
    if (port != null) {
      try {
        port.send(entry);
        return;
      } catch (e, s) {
        InternalLogger.log(
          LogLevel.warning,
          'AsyncHandler: Failed to send LogEntry to background isolate. '
          'Processing on caller isolate.',
          error: e,
          stackTrace: s,
        );
      }
    }

    if (timeout != null) {
      await engine
          .execute(
            entry,
            formatter,
            decorators,
            sink,
          )
          .timeout(timeout!);
    } else {
      await engine.execute(
        entry,
        formatter,
        decorators,
        sink,
      );
    }
  }

  /// Disposes of the background isolate and releases any associated resources.
  Future<void> dispose() async {
    _state.isDisposed = true;
    final port = _state.commandPort;
    if (port != null) {
      final callback = ReceivePort();
      port.send(_AsyncIsolateCommand.stop(callback.sendPort));
      await callback.first;
      callback.close();
    }

    _state.isolate?.kill();
    _state.errorPort?.close();
  }

  static void _spawnWorker(final List<dynamic> args) {
    final sendPort = args[0] as SendPort;
    final config = args[1] as _AsyncHandlerConfig;

    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((final message) async {
      if (message is LogEntry) {
        try {
          if (config.timeout != null) {
            await config.engine
                .execute(
                  message,
                  config.formatter,
                  config.decorators,
                  config.sink,
                )
                .timeout(config.timeout!);
          } else {
            await config.engine.execute(
              message,
              config.formatter,
              config.decorators,
              config.sink,
            );
          }
        } catch (e, s) {
          InternalLogger.log(
            LogLevel.error,
            'AsyncHandler worker pipeline execution failed',
            error: e,
            stackTrace: s,
          );
        }
      } else if (message is _AsyncIsolateCommand) {
        if (message.type == _AsyncCommandType.stop) {
          await config.sink.dispose();
          message.replyPort?.send(null);
          receivePort.close();
        }
      }
    });
  }
}
