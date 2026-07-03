part of '../native_handler.dart';

/// A lightweight reference to a native memory buffer containing Binary IR.
///
/// [NativePacket] is designed to be sent across isolates with zero-copy
/// efficiency. It contains the raw pointer, the length of the data, and
/// a completion port used to signal the main isolate when the buffer is
/// ready for reuse.
final class NativePacket {
  /// Creates a [NativePacket].
  const NativePacket({
    required this.address,
    required this.length,
    required this.terminalWidth,
    required this.completionPort,
  });

  /// The memory address of the native buffer.
  final int address;

  /// The length of the Binary IR data in bytes.
  final int length;

  /// The terminal width used for rendering.
  final int terminalWidth;

  /// The [SendPort] used to signal the [Arena] that this packet's memory
  /// can be recycled.
  final SendPort completionPort;

  /// Returns the native pointer.
  ffi.Pointer<ffi.Uint8> get pointer => ffi.Pointer.fromAddress(address);
}
