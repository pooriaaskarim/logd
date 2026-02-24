part of '../handler.dart';

/// A LIFO-recyclable buffer for encoding log entries into UTF-8 bytes.
///
/// Designed to eliminate `String` churn by providing a pre-allocated
/// `Uint8List` buffer. It falls back to `BytesBuilder` if the line exceeds
/// the fixed capacity.
class HandlerContext {
  /// By default, allocates 64KB per buffer to accommodate very large log lines.
  HandlerContext({final int capacity = 64 * 1024})
      : _buffer = Uint8List(capacity);

  /// Internal constructor for the [LogArena] to create pooled instances.
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
  /// This performs allocation for the UTF-8 bytes, use [FastStringWriter]
  /// for static tokens.
  void writeString(final String string) {
    if (string.isEmpty) {
      return;
    }
    final bytes = convert.utf8.encode(string);
    add(bytes);
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

  /// Resets the context for reuse in the [LogArena].
  void reset() {
    _length = 0;
    _overflowBuilder = null;
  }
}
