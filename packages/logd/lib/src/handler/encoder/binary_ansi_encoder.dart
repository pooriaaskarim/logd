part of '../handler.dart';

/// A high-performance [LogEncoder] that renders a [BinaryIR] stream into ANSI text.
///
/// This encoder serves as the reference implementation for the Native Engine.
/// It processes the linearized instruction stream (B-IR) in a single pass,
/// minimizing memory allocations and object traversal.
@internal
final class BinaryAnsiEncoder {
  const BinaryAnsiEncoder();

  /// Renders the [BinaryIR] buffer starting at [irPtr] into a string.
  String encode(final ffi.Pointer<ffi.Uint8> irPtr, {required int terminalWidth}) {
    final buffer = StringBuffer();
    
    // 1. Read Header
    final magic = irPtr.cast<ffi.Uint32>()[0];
    if (magic != BinaryIR.magic) return 'Error: Invalid Binary IR';
    
    final nodeCount = irPtr.cast<ffi.Uint32>()[2];
    int currentOffset = BinaryIR.headerSize;
    
    // 2. Rendering State
    int currentIndent = 0;
    String indentStr = '';
    
    // 3. Process Instructions
    for (int i = 0; i < nodeCount; i++) {
      final opPtr = irPtr.elementAt(currentOffset);
      final op = opPtr[0];
      
      switch (op) {
        case BinaryIR.opText:
          final style = opPtr.cast<ffi.Uint32>()[1];
          final len = opPtr.cast<ffi.Uint32>()[2];
          final dataPtr = opPtr.elementAt(12);
          
          final text = convert.utf8.decode(dataPtr.asTypedList(len));
          _applyStyle(buffer, style);
          buffer.write(text);
          _resetStyle(buffer);
          currentOffset += 12 + len;
          
        case BinaryIR.opNewline:
          buffer.writeln();
          buffer.write(indentStr);
          currentOffset += 8;
          
        case BinaryIR.opBoxStart:
          // Simplified box rendering logic
          buffer.writeln('┌' + '─' * (terminalWidth - 2) + '╮');
          currentOffset += 8;
          
        case BinaryIR.opBoxEnd:
          buffer.writeln('╰' + '─' * (terminalWidth - 2) + '╯');
          currentOffset += 8;
          
        case BinaryIR.opIndentStart:
          final len = opPtr.cast<ffi.Uint32>()[2];
          final dataPtr = opPtr.elementAt(12);
          indentStr += convert.utf8.decode(dataPtr.asTypedList(len));
          buffer.write(indentStr);
          currentOffset += 12 + len;
          
        case BinaryIR.opIndentEnd:
          // Simplified: just pop last indent (logic would be more complex for real nesting)
          if (indentStr.length >= 2) {
            indentStr = indentStr.substring(0, indentStr.length - 2);
          }
          currentOffset += 8;

        default:
          currentOffset += 8; // Skip unknown
      }
    }
    
    return buffer.toString();
  }

  void _applyStyle(StringBuffer buffer, int styleBitmask) {
    if (styleBitmask == 0) return;
    
    buffer.write('\x1B[');
    final codes = <int>[];
    
    // Colors
    final fg = styleBitmask & 0xF;
    if (fg != 15) codes.add(30 + fg);
    
    final bg = (styleBitmask >> 4) & 0xF;
    if (bg != 15) codes.add(40 + bg);
    
    // Flags
    if ((styleBitmask & (1 << 8)) != 0) codes.add(1); // Bold
    if ((styleBitmask & (1 << 9)) != 0) codes.add(2); // Dim
    if ((styleBitmask & (1 << 10)) != 0) codes.add(3); // Italic
    if ((styleBitmask & (1 << 11)) != 0) codes.add(7); // Inverse
    if ((styleBitmask & (1 << 12)) != 0) codes.add(4); // Underline
    
    buffer.write(codes.join(';'));
    buffer.write('m');
  }

  void _resetStyle(StringBuffer buffer) {
    buffer.write('\x1B[0m');
  }
}
