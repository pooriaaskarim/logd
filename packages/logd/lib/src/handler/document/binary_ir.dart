part of '../handler.dart';

/// Specification for the logd Binary Intermediate Representation (B-IR) v1.
///
/// B-IR is a linearized, instruction-based memory format designed for
/// zero-copy transfer between the Dart VM and Native engines (C, Rust, Zig).
///
/// ## Memory Layout
/// A B-IR buffer consists of a fixed-size header followed by a stream of
/// variable-length OpCode blocks.
@internal
abstract final class BinaryIR {
  const BinaryIR._();

  /// Magic bytes identifying the format ('LOGD' in ASCII).
  static const int magic = 0x4C4F4744;

  /// Current specification version.
  static const int version = 1;

  /// Header size in bytes.
  static const int headerSize = 16;

  // --- OpCodes (1 byte) ---

  /// A block of styled text.
  /// Payload: [uint32 style][uint32 length][char[] utf8_data]
  static const int opText = 0x01;

  /// A structural newline.
  static const int opNewline = 0x02;

  /// Start of a visual box or border.
  /// Payload: [uint32 style][uint8 border_type]
  static const int opBoxStart = 0x03;

  /// End of a visual box.
  static const int opBoxEnd = 0x04;

  /// Start of an indented block.
  /// Payload: [uint32 style][uint8 indent_len][char[] indent_text]
  static const int opIndentStart = 0x05;

  /// End of an indented block.
  static const int opIndentEnd = 0x06;

  /// A repeated filler character.
  /// Payload: [uint32 style][uint8 char][uint32 count]
  static const int opFiller = 0x07;

  /// Metadata key-value pair.
  /// Payload: [uint8 type][uint16 key_len][char[] key][uint32 val_len][byte[]
  /// val]
  static const int opMetadata = 0x08;

  /// A potential point where the line can be wrapped.
  /// Payload: [uint8 priority]
  static const int opWrapPoint = 0x09;

  /// Resets all styling and structural state.
  static const int opReset = 0x0A;

  // --- Metadata Types ---
  static const int metaString = 0x01;
  static const int metaInt = 0x02;
  static const int metaBool = 0x03;
  static const int metaJson = 0x04;
}
