// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

library;

import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:logd/logd.dart';
import 'package:meta/meta.dart';

import 'sqlite_sink.dart';

/// Internal plain-data config passed across the isolate boundary.
class _SqliteWorkerConfig {
  const _SqliteWorkerConfig({
    required this.path,
    required this.tableName,
    required this.maxEntries,
    this.maxAge,
    required this.batchSize,
    this.flushIntervalMs,
    required this.walMode,
    required this.formatterJson,
    required this.decoratorsJson,
    this.timeoutMs,
  });

  final String path;
  final String tableName;
  final int? maxEntries;
  final Duration? maxAge;
  final int batchSize;
  final int? flushIntervalMs;
  final bool walMode;
  final Map<String, dynamic> formatterJson;
  final List<Map<String, dynamic>> decoratorsJson;
  final int? timeoutMs;
}

/// Internal stop command sent to the worker isolate.
class _StopCommand {
  _StopCommand(this.replyPort);

  final SendPort replyPort;
}

class _IsolateState {
  Isolate? isolate;
  SendPort? commandPort;
  bool isDisposed = false;
}

/// A background-isolate [Handler] for [SqliteSink] that passes only
/// plain-data config across the isolate boundary, constructing the
/// [SqliteSink] fresh inside the worker isolate.
///
/// This avoids the [SendPort] `object is unsendable` error that arises
/// when transferring an already-opened SQLite database handle or active
/// [Timer] across isolate boundaries.
@internal
base class SqliteIsolateHandler extends Handler {
  /// Creates a [SqliteIsolateHandler] that spawns a background isolate.
  ///
  /// The [SqliteSink] is constructed inside the background isolate from
  /// the supplied plain-data config. All database I/O happens off the
  /// main thread.
  SqliteIsolateHandler({
    required final String path,
    final String tableName = 'logs',
    final int? maxEntries = 10000,
    final Duration? maxAge,
    final int batchSize = 50,
    final Duration? flushInterval = const Duration(seconds: 2),
    final bool walMode = true,
    super.formatter = const StructuredFormatter(),
    super.decorators,
    super.filters,
    super.timeout,
  })  : _config = _SqliteWorkerConfig(
          path: path,
          tableName: tableName,
          maxEntries: maxEntries,
          maxAge: maxAge,
          batchSize: batchSize,
          flushIntervalMs: flushInterval?.inMilliseconds,
          walMode: walMode,
          formatterJson:
              LoggerSerializationRegistry.serializeFormatter(formatter),
          decoratorsJson: decorators
              .map(LoggerSerializationRegistry.serializeDecorator)
              .toList(),
          timeoutMs: timeout?.inMilliseconds,
        ),
        // Handler requires a sink at construction; we use a no-op placeholder.
        // The real SqliteSink lives entirely inside the background isolate.
        super(
          sink: _NoOpSink(),
          engine: const StandardEngine(),
        ) {
    _finalizer.attach(this, _receivePort, detach: this);
    _start();
  }

  final _SqliteWorkerConfig _config;
  final ReceivePort _receivePort = ReceivePort();
  final ReceivePort _errorPort = ReceivePort();
  final Completer<void> _ready = Completer<void>();
  final _IsolateState _state = _IsolateState();

  static final Finalizer<ReceivePort> _finalizer =
      Finalizer<ReceivePort>((final port) {
    io.stderr.writeln(
      '[logd] SqliteIsolateHandler leak detected! '
      'Handler garbage-collected without dispose(). '
      'Call dispose() to flush pending entries and close the database.',
    );
    port.close();
  });

  /// A future that completes when the background isolate is ready.
  Future<void> get ready => _ready.future;

  Future<void> _start() async {
    try {
      _state.isolate = await Isolate.spawn(
        _workerMain,
        [_receivePort.sendPort, _config],
        onError: _errorPort.sendPort,
        debugName: 'SqliteIsolateHandler',
      );

      _errorPort.listen((final message) {
        io.stderr.writeln(
          '[logd] SqliteIsolateHandler worker error: $message',
        );
      });

      _state.commandPort = await _receivePort.first as SendPort;

      if (_state.isDisposed) {
        // Disposed before ready — stop the worker immediately.
        _state.commandPort?.send(_StopCommand(ReceivePort().sendPort));
        _state.commandPort = null;
      } else {
        _ready.complete();
      }
    } catch (e, s) {
      _errorPort.close();
      _receivePort.close();
      if (!_ready.isCompleted) {
        _ready.completeError(e, s);
      }
    }
  }

  @override
  @internal
  Future<void> log(final LogEntry entry) async {
    if (_state.isDisposed) return;

    if (filters.any((final f) => !f.shouldLog(entry))) return;

    if (!_ready.isCompleted) {
      await _ready.future;
    }

    _state.commandPort?.send(entry);
  }

  @override
  Future<void> dispose() async {
    if (_state.isDisposed) return;
    _state.isDisposed = true;
    _finalizer.detach(this);

    final port = _state.commandPort;
    if (port != null) {
      final reply = ReceivePort();
      try {
        port.send(_StopCommand(reply.sendPort));
        await reply.first;
      } catch (_) {
        _state.isolate?.kill(priority: Isolate.immediate);
      } finally {
        reply.close();
      }
    } else {
      _state.isolate?.kill(priority: Isolate.immediate);
    }

    _receivePort.close();
    _errorPort.close();
    _state.isolate = null;
    _state.commandPort = null;
    await super.dispose();
  }

  /// Worker isolate entry point. Receives only plain-data config.
  /// Constructs [SqliteSink] fresh here — no native handles cross the boundary.
  static void _workerMain(final List<dynamic> args) {
    final sendPort = args[0] as SendPort;
    final config = args[1] as _SqliteWorkerConfig;

    // Reconstruct formatter and decorators from serialized JSON.
    final formatter =
        LoggerSerializationRegistry.deserializeFormatter(config.formatterJson);
    final decorators = config.decoratorsJson
        .map(LoggerSerializationRegistry.deserializeDecorator)
        .toList();
    final timeout = config.timeoutMs != null
        ? Duration(milliseconds: config.timeoutMs!)
        : null;

    // Construct the sink fresh inside the isolate — no isolate transfer needed.
    final sink = SqliteSink(
      dbPath: config.path,
      tableName: config.tableName,
      maxEntries: config.maxEntries,
      maxAge: config.maxAge,
      batchSize: config.batchSize,
      flushInterval: config.flushIntervalMs != null
          ? Duration(milliseconds: config.flushIntervalMs!)
          : null,
      walMode: config.walMode,
    );

    const engine = StandardEngine();

    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((final message) async {
      if (message is LogEntry) {
        try {
          if (timeout != null) {
            await engine
                .execute(message, formatter, decorators, sink)
                .timeout(timeout);
          } else {
            await engine.execute(message, formatter, decorators, sink);
          }
        } catch (e, s) {
          io.stderr.writeln(
            '[logd] SqliteIsolateHandler worker pipeline failed: $e\n$s',
          );
        }
      } else if (message is _StopCommand) {
        await sink.dispose();
        message.replyPort.send(null);
        receivePort.close();
      }
    });
  }
}

/// A no-op [LogSink] used as a placeholder in [SqliteIsolateHandler]'s
/// [Handler] superclass constructor. All actual output goes to the
/// [SqliteSink] running inside the background isolate.
base class _NoOpSink extends LogSink<LogDocument> {
  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {}
}
