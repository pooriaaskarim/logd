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
///
/// Refactored to support `const` constructors by moving mutable state
/// (buffer, disposal status) to a lazy-initialized [Expando].
abstract base class NetworkSink extends LogSink {
  /// Creates a [NetworkSink].
  ///
  /// - [maxBufferSize]: Max entries to hold in memory (default: 1000).
  /// - [dropPolicy]: Behavior when [maxBufferSize] is reached.
  /// - [enabled]: Whether the sink is active.
  const NetworkSink({
    this.maxBufferSize = 1000,
    this.dropPolicy = DropPolicy.discardOldest,
    super.enabled,
  });

  /// Max entries to hold in memory.
  final int maxBufferSize;

  /// Behavior when [maxBufferSize] is reached.
  final DropPolicy dropPolicy;

  /// Shared [Expando] to store mutable state for `const` sink instances.
  static final Expando<_NetworkState> _states = Expando();

  _NetworkState get _state => _states[this] ??= _createState();

  /// Creates the specialized state for this sink type.
  @protected
  _NetworkState _createState();

  /// Returns `true` if the sink has been disposed.
  bool get isDisposed => _state.isDisposed;

  @override
  int get preferredWidth => 120;

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

  /// Returns and clears the current buffer.
  @protected
  List<String> takeBuffer() {
    final buffer = _state.buffer;
    final batch = List<String>.from(buffer);
    buffer.clear();
    return batch;
  }

  /// Returns `true` if there are logs waiting in the buffer.
  @protected
  bool get hasBufferedLogs => _state.buffer.isNotEmpty;

  @override
  @mustCallSuper
  Future<void> dispose() async {
    _state.isDisposed = true;
  }
}

/// Internal state for a [NetworkSink].
class _NetworkState {
  final List<String> buffer = [];
  bool isDisposed = false;
}

/// A [LogSink] that ships logs in batches via HTTP POST requests.
final class HttpSink extends NetworkSink {
  /// Creates an [HttpSink].
  ///
  /// - [url]: The endpoint URL (String to support const constructors).
  const HttpSink({
    required this.url,
    this.headers = const {},
    this.batchSize = 50,
    this.flushInterval = const Duration(seconds: 60),
    this.maxRetries = 5,
    this.client,
    super.maxBufferSize,
    super.dropPolicy,
    super.enabled,
  });

  /// The endpoint URL.
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
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    if (!enabled || isDisposed) {
      return;
    }

    _ensureActive();

    final formatted = lines.map((final s) => s.toString()).join('\n');
    enqueue(formatted);

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

    final batch = takeBuffer();
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
          body: jsonEncode(batch),
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
    await super.dispose(); // Set isDisposed = true last
  }
}

class _HttpState extends _NetworkState {
  Timer? timer;
  http.Client? internalClient;
  Uri? uri;
}

/// A [LogSink] that streams logs over a WebSocket connection in real-time.
final class SocketSink extends NetworkSink {
  /// Creates a [SocketSink].
  ///
  /// - [url]: The WebSocket URL (String to support const constructors).
  /// - [reconnectInterval]: Delay before attempting reconnection (default: 5s).
  /// - [channel]: Optional external [WebSocketChannel].
  const SocketSink({
    required this.url,
    this.headers = const {},
    this.reconnectInterval = const Duration(seconds: 15),
    this.channel,
    super.maxBufferSize,
    super.dropPolicy,
    super.enabled,
  });

  /// The WebSocket URL.
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
    final Iterable<LogLine> lines,
    final LogLevel level,
  ) async {
    if (!enabled || isDisposed) {
      return;
    }

    final formatted = lines.map((final s) => s.toString()).join('\n');

    if (_socketState.isConnected) {
      _send(formatted);
    } else {
      enqueue(formatted);
      if (!_socketState.isConnecting) {
        await _connect();
      }
    }
  }

  void _send(final String line) {
    try {
      _socketState.channel?.sink.add(line);
    } catch (e) {
      _handleFailure(e);
      _socketState.isConnected = false;
      enqueue(line);
      _connect();
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

      // Drain buffer on connection
      if (hasBufferedLogs) {
        final batch = takeBuffer();
        for (final line in batch) {
          _send(line);
        }
      }
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
  Future<void> dispose() async {
    await super.dispose();
    _socketState.isConnected = false;
    await _socketState.channel?.sink.close();
  }
}

class _SocketState extends _NetworkState {
  WebSocketChannel? channel;
  Uri? uri;
  bool isConnected = false;
  bool isConnecting = false;
}
