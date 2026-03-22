part of '../handler.dart';

/// A reusable encoding buffer for log serialization.
///
/// [HandlerContext] is designed to minimize intermediate string allocations by
/// providing a pre-allocated byte buffer for UTF-8 encoding. It provides
/// automatic overflow handling via a chunked conversion fallback.
class HandlerContext {
  /// By default, allocates 64KB per buffer to accommodate very large log lines.
  HandlerContext({final int capacity = 64 * 1024})
      : _buffer = Uint8List(capacity);

  /// Internal constructor for the [Arena] to create pooled instances.
  HandlerContext._pooled({final int capacity = 64 * 1024})
      : _buffer = Uint8List(capacity);

  final Uint8List _buffer;
  int _length = 0;

  BytesBuilder? _overflowBuilder;

  /// Returns the number of bytes currently written to the buffer.
  int get length => _overflowBuilder?.length ?? _length;

  /// Appends [bytes] to the buffer.
  void add(final List<int> bytes) {
    if (_overflowBuilder != null) {
      _overflowBuilder!.add(bytes);
      return;
    }

    if (_length + bytes.length > _buffer.length) {
      _overflow();
      _overflowBuilder!.add(bytes);
      return;
    }

    _buffer.setAll(_length, bytes);
    _length += bytes.length;
  }

  /// Appends a pre-encoded [token] to the buffer.
  ///
  /// This is an alias for [add] that emphasizes the use of static,
  /// pre-calculated byte arrays.
  void addToken(final Uint8List token) {
    add(token);
  }

  /// Appends a single [byte] to the buffer.
  void addByte(final int byte) {
    if (_overflowBuilder != null) {
      _overflowBuilder!.addByte(byte);
      return;
    }

    if (_length == _buffer.length) {
      _overflow();
      _overflowBuilder!.addByte(byte);
      return;
    }

    _buffer[_length++] = byte;
  }

  /// Writes [string] as UTF-8 into the buffer.
  ///
  /// This implementation avoids intermediate allocations by writing directly
  /// into the internal buffer. It uses an ASCII fast-path for common English
  /// log messages.
  void writeString(final String string) {
    if (string.isEmpty) {
      return;
    }

    // Fast Path: Check if the string is ASCII and fits in the buffer.
    // ASCII characters (0-127) are exactly 1 byte in UTF-8.
    final len = string.length;
    if (_overflowBuilder == null && _length + len <= _buffer.length) {
      var isAscii = true;
      for (var i = 0; i < len; i++) {
        final codeUnit = string.codeUnitAt(i);
        if (codeUnit > 127) {
          isAscii = false;
          break;
        }
        _buffer[_length + i] = codeUnit;
      }

      if (isAscii) {
        _length += len;
        return;
      }
    }

    // Fallback: Use the standard encoder but write into a chunked sink
    // that appends directly to this context.
    final encoder = convert.utf8.encoder;
    final sink = _HandlerContextSink(this);
    encoder.startChunkedConversion(sink)
      ..add(string)
      ..close();
  }

  void _overflow() {
    _overflowBuilder = BytesBuilder(copy: false)..add(takeBytes());
  }

  /// Takes the written bytes to be output to a sink.
  ///
  /// This returns a view over the internal array if there was no overflow,
  /// avoiding duplication. Do not cache the returned `Uint8List`.
  Uint8List takeBytes() {
    if (_overflowBuilder != null) {
      final bytes = _overflowBuilder!.takeBytes();
      _overflowBuilder = null;
      _length = 0;
      return bytes;
    }

    final bytes = Uint8List.sublistView(_buffer, 0, _length);
    _length = 0;
    return bytes;
  }

  /// Resets the context for reuse in the [Arena].
  void reset() {
    _length = 0;
    _overflowBuilder = null;
  }
}

/// A sink that redirects chunked data back into [HandlerContext].
class _HandlerContextSink implements Sink<List<int>> {
  _HandlerContextSink(this.context);
  final HandlerContext context;

  @override
  void add(final List<int> data) {
    context.add(data);
  }

  @override
  void close() {}
}
