library;

import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../logger/logger.dart';
import '../document/document.dart';
import '../encoder/encoder.dart';
import '../engine/engine.dart';
import '../sink/sink.dart';
import 'dashboard_html.dart';

/// A [LogSink] that starts a local HTTP and WebSocket server to host a
/// real-time log viewer dashboard.
base class HttpServerSink extends EncodingSink {
  /// Creates an [HttpServerSink] binding to [address] and [port].
  HttpServerSink({
    this.address = 'localhost',
    this.port = 8080,
    super.encoder = const HtmlEncoder(),
    super.strategy = WrappingStrategy.none,
    final int? lineLength,
    super.enabled = true,
  }) : super(
          preferredWidth: lineLength ?? 120,
          delegate: _staticWrite,
        ) {
    _startServer();
  }

  /// The local interface address to bind to.
  final String address;

  /// The local port number to bind to.
  final int port;

  /// Completer to track server readiness.
  final Completer<void> _ready = Completer<void>();

  /// A future that completes when the HTTP server is successfully bound
  /// and listening.
  Future<void> get ready => _ready.future;

  /// The actual bound port of the running HTTP server.
  int get boundPort => _serverState.server?.port ?? port;

  static final Expando<_ServerState> _states = Expando();

  _ServerState get _serverState => _states[this] ??= _ServerState();

  static void _staticWrite(final Uint8List data) {
    // Overridden by custom output logic
  }

  Future<void> _startServer() async {
    try {
      final server = await io.HttpServer.bind(address, port);
      _serverState.server = server;
      _serverState.isListening = true;
      _ready.complete();

      server.listen((final request) async {
        if (request.uri.path == '/') {
          request.response.headers.contentType = io.ContentType.html;
          var html = dashboardHtml;
          final currentEncoder = encoder;
          if (currentEncoder is HtmlEncoder) {
            final css = currentEncoder.stylesheet;
            html = html.replaceFirst(
              '</head>',
              '<style>$css</style></head>',
            );
          }
          request.response.write(html);
          await request.response.close();
        } else if (request.uri.path == '/ws') {
          try {
            final socket = await io.WebSocketTransformer.upgrade(request);
            _serverState.sockets.add(socket);
            socket.listen(
              (final _) {},
              onError: (final _) {
                _serverState.sockets.remove(socket);
              },
              onDone: () {
                _serverState.sockets.remove(socket);
              },
            );
          } catch (e) {
            InternalLogger.log(
              LogLevel.error,
              'HttpServerSink: Failed to upgrade WebSocket request',
              error: e,
            );
          }
        } else {
          request.response.statusCode = io.HttpStatus.notFound;
          await request.response.close();
        }
      });
    } catch (e, s) {
      _ready.completeError(e, s);
      InternalLogger.log(
        LogLevel.error,
        'HttpServerSink: Failed to start HTTP server on $address:$port',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {
    if (!enabled || _serverState.isDisposed) {
      return;
    }

    final context = factory.checkoutContext();
    try {
      encoder.encode(
        entry,
        document,
        level,
        context,
        factory,
        width: preferredWidth,
      );
      final data = context.takeBytes();
      final formattedString = convert.utf8.decode(data);

      final payload = {
        'formatted': formattedString,
        'entry': {
          'loggerName': entry.loggerName,
          'origin': entry.origin,
          'level': entry.level.name,
          'message': entry.message,
          'timestamp': entry.timestamp,
          if (entry.error != null) 'error': entry.error.toString(),
          if (entry.stackTrace != null)
            'stackTrace': entry.stackTrace.toString(),
          if (entry.context != null) 'context': entry.context,
        },
      };

      final payloadJson = convert.jsonEncode(payload);

      final sockets = List<io.WebSocket>.from(_serverState.sockets);
      for (final socket in sockets) {
        if (socket.readyState == io.WebSocket.open) {
          socket.add(payloadJson);
        }
      }
    } catch (e, s) {
      InternalLogger.log(
        LogLevel.error,
        'HttpServerSink output failed',
        error: e,
        stackTrace: s,
      );
    } finally {
      factory.release(context);
    }
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    _serverState.isDisposed = true;
    _serverState.isListening = false;

    final sockets = List<io.WebSocket>.from(_serverState.sockets);
    for (final socket in sockets) {
      await socket.close();
    }
    _serverState.sockets.clear();

    await _serverState.server?.close(force: true);
    await super.dispose();
  }
}

class _ServerState {
  io.HttpServer? server;
  final List<io.WebSocket> sockets = [];
  bool isListening = false;
  bool isDisposed = false;
}
