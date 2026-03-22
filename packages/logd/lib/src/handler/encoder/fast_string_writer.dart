part of '../handler.dart';

/// A utility for converting static strings (like ANSI escape codes) into
/// pre-calculated UTF-8 bytes to avoid encoding them multiple times.
class FastStringWriter {
  const FastStringWriter._();

  /// Converts [string] to UTF-8 bytes and returns them.
  static Uint8List utf8Bytes(final String string) =>
      Uint8List.fromList(convert.utf8.encode(string));
}
