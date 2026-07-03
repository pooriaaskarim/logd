part of '../native_handler.dart';

/// Specification for the logd Binary Intermediate Representation (B-IR) v2.
///
/// B-IR is a linearized, instruction-based memory format designed for
/// zero-copy transfer between the Dart VM and Native engines (C, Rust, Zig).
///
/// ## Memory Layout
/// A B-IR buffer consists of a fixed-size header followed by a stream of
/// variable-length OpCode blocks. Each block is 8-byte aligned.
///
/// Standard 16-byte OpCode Header:
/// [0]: opcode (uint8)
/// [1-3]: opcode-specific small payload
/// [4-7]: tags (uint32 bitmask)
/// [8-11]: primary payload (e.g. style bitmask)
/// [12-15]: secondary payload (e.g. length, count)
@internal
abstract final class BinaryIR {
  const BinaryIR._();

  /// Magic bytes identifying the format ('LOGD' in ASCII).
  static const int magic = 0x4C4F4744;

  /// Current specification version.
  static const int version = 2;

  /// Header size in bytes.
  static const int headerSize = 16;

  // --- OpCodes (1 byte) ---

  /// A block of styled text.
  /// Payload: [uint32 tags][uint32 style][uint32 length][char[] utf8_data]
  static const int opText = 0x01;

  /// A structural newline.
  static const int opNewline = 0x02;

  /// Start of a visual box or border.
  /// Payload: [uint8 type][uint32 tags][uint32 style]
  static const int opBoxStart = 0x03;

  /// End of a visual box.
  static const int opBoxEnd = 0x04;

  /// Start of an indented block.
  /// Payload: [uint32 tags][uint32 length][char[] indent_text]
  static const int opIndentStart = 0x05;

  /// End of an indented block.
  static const int opIndentEnd = 0x06;

  /// A repeated filler character.
  /// Payload: [uint8 char][uint32 tags][uint32 style][uint32 count]
  static const int opFiller = 0x07;

  /// Metadata key-value pair block.
  /// Payload: [uint32 tags][uint32 count][entries...]
  static const int opMetadata = 0x08;

  /// A potential point where the line can be wrapped.
  /// Payload: [uint8 priority]
  static const int opWrapPoint = 0x09;

  /// Resets all styling and structural state.
  static const int opReset = 0x0A;

  /// Start of a decorated block (leading/trailing).
  /// Payload: [uint8 leadingWidth][uint8 trailingWidth][uint8 flags]
  /// [uint32 tags][uint32 hintIdx][uint32 leadingCount][uint32 trailingCount]
  static const int opDecoratedStart = 0x0B;

  /// End of a decorated block.
  static const int opDecoratedEnd = 0x0C;

  /// Global document metadata.
  static const int opGlobalMetadata = 0x0D;

  /// Explicit content alignment.
  /// Payload: [uint8 alignment_type][uint32 tags]
  static const int opAlignmentStart = 0x0E;
  static const int opAlignmentEnd = 0x13;

  /// Start of a grid layout (table).
  /// Payload: [uint8 columns][uint32 tags][uint16 columnWidths[]]
  static const int opTableStart = 0x0F;

  /// End of a grid layout.
  static const int opTableEnd = 0x10;

  /// Start of a table cell.
  /// Payload: [uint8 colSpan][uint8 rowSpan][uint32 tags]
  static const int opTableCellStart = 0x11;

  /// End of a table cell.
  static const int opTableCellEnd = 0x12;

  /// Start of a table row.
  /// Payload: [uint32 tags]
  static const int opTableRowStart = 0x15;

  /// End of a table row.
  static const int opTableRowEnd = 0x16;

  /// Start of a layout row.
  /// Payload: [uint8 char][uint32 tags][uint32 styleBitmask]
  static const int opRowStart = 0x17;

  /// End of a layout row.
  static const int opRowEnd = 0x18;

  // --- Metadata Types ---
  static const int metaString = 0x01;
  static const int metaInt = 0x02;
  static const int metaBool = 0x03;
  static const int metaJson = 0x04;

  // --- Alignment Types ---
  static const int alignLeft = 0x00;
  static const int alignCenter = 0x01;
  static const int alignRight = 0x02;
  static const int alignJustify = 0x03;
}
