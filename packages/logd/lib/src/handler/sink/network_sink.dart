part of '../handler.dart';

/// Defines the behavior when the network buffer reaches its maximum capacity.
enum DropPolicy {
  /// Discard the oldest entries in the buffer to make room for new ones.
  discardOldest,

  /// Discard the incoming entries until the buffer has space.
  discardNewest,

  /// Pause logging until the buffer has space (blocking the application).
  ///
  /// CAUTION: This can lead to performance issues if the network is down.
  block,
}

/// A base class for network-based sinks that require an internal buffer.
abstract base class NetworkSink extends EncodingSink<String> {
  /// Creates a [NetworkSink].
  ///
  /// - [encoder]: The encoder used to serialize logs (default:
  ///   [PlainTextEncoder]).
  /// - [maxBufferSize]: Max entries to hold in memory (default: 1000).
  /// - [dropPolicy]: Behavior when [maxBufferSize] is reached.
  /// - [enabled]: Whether the sink is active.
  const NetworkSink({
    super.encoder = const PlainTextEncoder(),
    this.maxBufferSize = 1000,
    this.dropPolicy = DropPolicy.discardOldest,
    super.enabled,
  }) : super(
          delegate: _doNothing,
        );

  static void _doNothing(final String _) {}

  /// Max entries to hold in memory.
  final int maxBufferSize;

  /// Behavior when [maxBufferSize] is reached.
  final DropPolicy dropPolicy;

  /// Shared [Expando] to store mutable state for sink instances.
  static final Expando<_NetworkState> _states = Expando();

  _NetworkState get _state => _states[this] ??= _createState();

  /// Creates the specialized state for this sink type.
  @protected
  _NetworkState _createState();

  /// Returns `true` if the sink has been disposed.
  bool get isDisposed => _state.isDisposed;

  /// Safely adds a line to the buffer according to the [dropPolicy].
  @protected
  void enqueue(final String line) {
    final buffer = _state.buffer;
    if (buffer.length >= maxBufferSize) {
      if (dropPolicy == DropPolicy.discardOldest) {
        if (buffer.isNotEmpty) {
          buffer.removeAt(0);
        }
        buffer.add(line);
      } else if (dropPolicy == DropPolicy.discardNewest) {
        return;
      } else {
        // block/fallback
        if (buffer.isNotEmpty) {
          buffer.removeAt(0);
        }
        buffer.add(line);
      }
    } else {
      buffer.add(line);
    }
  }

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
  ) async {
    if (!enabled) {
      return;
    }

    // Trigger preamble if needed
    if (strategy == WrappingStrategy.document && !_preambleWritten) {
      final preamble = encoder.preamble(level, document: document);
      if (preamble != null) {
        enqueue(preamble);
      }
      _preambleWritten = true;
    }

    final data = encoder.encode(
      entry,
      document,
      level,
      width: preferredWidth,
    );

    enqueue(data);
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    if (strategy == WrappingStrategy.document && _preambleWritten) {
      final post = encoder.postamble(LogLevel.info);
      if (post != null) {
        enqueue(post);
      }
    }
    await super.dispose();
  }

  /// Returns and clears the current buffer.
  @protected
  List<String> flush() {
    final buffer = _state.buffer;
    final lines = List<String>.from(buffer);
    buffer.clear();
    return lines;
  }

  /// Returns `true` if there are logs waiting in the buffer.
  @protected
  bool get hasBufferedLogs => _state.buffer.isNotEmpty;
}

/// Internal state for a [NetworkSink].
class _NetworkState {
  final List<String> buffer = [];
  bool isDisposed = false;
}

/// A [NetworkSink] that transmits logs via HTTP POST.
base class HttpSink extends NetworkSink {
  /// Creates an [HttpSink].
  ///
  /// - [url]: The destination endpoint.
  /// - [encoder]: The encoder used to serialize logs (default:
  ///   [PlainTextEncoder]).
  /// - [headers]: Custom headers to include in the request.
  /// - [batchSize]: Sink when this many logs are accumulated (default: 50).
  /// - [flushInterval]: Sink interval (default: 60s).
  /// - [maxRetries]: Max attempts for a single batch (default: 5).
  /// - [client]: Optional external [http.Client].
  /// - [maxBufferSize]: Max entries to hold in memory.
  /// - [dropPolicy]: Behavior when [maxBufferSize] is reached.
  /// - [enabled]: Whether the sink is active.
  const HttpSink({
    required this.url,
    super.encoder = const PlainTextEncoder(),
    this.headers = const {},
    this.batchSize = 50,
    this.flushInterval = const Duration(seconds: 60),
    this.maxRetries = 5,
    this.client,
    super.maxBufferSize = 1000,
    super.dropPolicy = DropPolicy.discardOldest,
    super.enabled,
  });

  /// The destination endpoint URL.
  final String url;

  /// Custom headers to include in the request.
  final Map<String, String> headers;

  /// Sink when this many logs are accumulated.
  final int batchSize;

  /// Sink interval.
  final Duration flushInterval;

  /// Max attempts for a single batch.
  final int maxRetries;

  /// Optional external [http.Client].
  final http.Client? client;

  @override
  _NetworkState _createState() => _HttpState();

  _HttpState get _httpState => _state as _HttpState;

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
  ) async {
    if (!enabled || isDisposed) {
      return;
    }

    _ensureActive();

    // Use parent's output logic which calls enqueue
    await super.output(document, entry, level);

    if (_state.buffer.length >= batchSize) {
      _triggerFlush();
    }
  }

  void _ensureActive() {
    if (_httpState.timer == null && !isDisposed) {
      _httpState.timer = Timer.periodic(flushInterval, (final _) => _flush());
    }
  }

  /// Triggers an asynchronous flush of the current buffer.
  void _triggerFlush() {
    scheduleMicrotask(_flush);
  }

  Future<void> _flush() async {
    if (!hasBufferedLogs || isDisposed) {
      return;
    }

    final batch = flush();
    await _pushWithRetry(batch);
  }

  Future<void> _pushWithRetry(final List<String> batch) async {
    final httpClient = client ?? (_httpState.internalClient ??= http.Client());
    final uri = _httpState.uri ??= Uri.parse(url);

    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final response = await httpClient.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            ...headers,
          },
          body: convert.jsonEncode(batch),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }

        throw io.HttpException(
          'HTTP Error ${response.statusCode}',
          uri: uri,
        );
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          _handleFailure(e);
          return;
        }
        final delay = Duration(milliseconds: pow(2, attempts).toInt() * 100);
        await Future.delayed(delay);
      }
    }
  }

  void _handleFailure(final Object error) {
    InternalLogger.log(
      LogLevel.error,
      'HttpSink failed to send batch after $maxRetries attempts',
      error: error,
    );
  }

  @override
  Future<void> dispose() async {
    _httpState.timer?.cancel();
    await _flush(); // Final drain before marking disposed
    _httpState.internalClient?.close();
    _state.isDisposed = true;
    await super.dispose();
  }
}

class _HttpState extends _NetworkState {
  Timer? timer;
  http.Client? internalClient;
  Uri? uri;
}

/// A [NetworkSink] that transmits logs via a WebSocket.
base class SocketSink extends NetworkSink {
  /// Creates a [SocketSink].
  ///
  /// - [url]: The WebSocket server URL.
  /// - [headers]: Optional protocols/headers for the connection.
  /// - [reconnectInterval]: Delay before attempting reconnection
  /// (default: 15s).
  /// - [channel]: Optional external WebSocketChannel.
  /// - [encoder]: The encoder used to serialize logs (default:
  ///   [PlainTextEncoder]).
  /// - [maxBufferSize]: Max entries to hold in memory.
  /// - [dropPolicy]: Behavior when [maxBufferSize] is reached.
  /// - [enabled]: Whether the sink is active.
  const SocketSink({
    required this.url,
    this.headers = const {},
    this.reconnectInterval = const Duration(seconds: 15),
    this.channel,
    super.encoder = const PlainTextEncoder(),
    super.maxBufferSize = 1000,
    super.dropPolicy = DropPolicy.discardOldest,
    super.enabled,
  });

  /// The WebSocket server URL.
  final String url;

  /// Optional protocols/headers for the connection.
  final Map<String, String> headers;

  /// Delay before attempting reconnection.
  final Duration reconnectInterval;

  /// Optional external [WebSocketChannel].
  final WebSocketChannel? channel;

  @override
  _NetworkState _createState() => _SocketState();

  _SocketState get _socketState => _state as _SocketState;

  @override
  Future<void> output(
    final LogDocument document,
    final LogEntry entry,
    final LogLevel level,
  ) async {
    if (!enabled || isDisposed) {
      return;
    }

    // Use parent logic to get encoded data and put in buffer
    await super.output(document, entry, level);

    if (_socketState.isConnected) {
      _drainBuffer();
    } else if (!_socketState.isConnecting) {
      unawaited(_connect());
    }
  }

  void _send(final String line) {
    try {
      _socketState.channel?.sink.add(line);
    } catch (e) {
      _handleFailure(e);
      _socketState.isConnected = false;
      enqueue(line);
      unawaited(_connect());
    }
  }

  void _drainBuffer() {
    if (!hasBufferedLogs) {
      return;
    }
    final batch = flush();
    for (final line in batch) {
      _send(line);
    }
  }

  Future<void> _connect() async {
    if (_socketState.isConnecting || isDisposed) {
      return;
    }

    _socketState.isConnecting = true;
    try {
      final uri = _socketState.uri ??= Uri.parse(url);
      _socketState.channel = channel ??
          WebSocketChannel.connect(uri, protocols: headers.keys.toList());
      await _socketState.channel?.ready;
      _socketState.isConnected = true;
      _socketState.isConnecting = false;

      _drainBuffer();
    } catch (e) {
      _socketState.isConnecting = false;
      _socketState.isConnected = false;
      if (!isDisposed) {
        Future.delayed(reconnectInterval, _connect);
      }
    }
  }

  void _handleFailure(final Object error) {
    InternalLogger.log(
      LogLevel.error,
      'SocketSink connection error',
      error: error,
    );
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    _state.isDisposed = true;
    _socketState.isConnected = false;
    await _socketState.channel?.sink.close();
    await super.dispose();
  }
}

class _SocketState extends _NetworkState {
  WebSocketChannel? channel;
  Uri? uri;
  bool isConnected = false;
  bool isConnecting = false;
}
