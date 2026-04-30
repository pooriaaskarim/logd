part of '../handler.dart';

/// A high-performance [LogEncoder] that renders a [BinaryIR] stream into ANSI
/// text.
///
/// This encoder serves as the reference implementation for the Native Engine.
/// It processes the linearized instruction stream (B-IR) in a single pass,
/// minimizing memory allocations and object traversal.
@internal
final class BinaryAnsiEncoder {
  const BinaryAnsiEncoder();

  /// Renders the [BinaryIR] buffer starting at [irPtr] into a string.
  String encode(
    final ffi.Pointer<ffi.Uint8> irPtr, {
    required final int terminalWidth,
  }) {
    final buffer = StringBuffer();

    // 1. Read Header
    final magic = irPtr.cast<ffi.Uint32>()[0];
    if (magic != BinaryIR.magic) {
      return 'Error: Invalid Binary IR';
    }

    final nodeCount = irPtr.cast<ffi.Uint32>()[2];
    int currentOffset = BinaryIR.headerSize;

    // 2. Rendering State
    int currentLineWidth = 0;
    final indentStack = <String>[''];
    final boxStack = <_BoxContext>[];

    String fullIndent() =>
        indentStack.join() + boxStack.map((final e) => e.padding).join();


    // 3. Process Instructions
    for (int i = 0; i < nodeCount; i++) {
      final opPtr = irPtr + currentOffset;
      final op = opPtr[0];

      switch (op) {
        case BinaryIR.opGlobalMetadata:
          final count = opPtr.cast<ffi.Uint32>()[1];
          currentOffset += 8;
          for (int j = 0; j < count; j++) {
            final entryPtr = irPtr + currentOffset;
            final keyLen = (entryPtr + 2).cast<ffi.Uint16>()[0];
            final valLenPtr = (entryPtr + 4 + keyLen).cast<ffi.Uint32>();
            final valLen = valLenPtr[0];
            currentOffset += 8 + keyLen + valLen;
          }

        case BinaryIR.opText:
          final style = opPtr.cast<ffi.Uint32>()[2];
          final len = opPtr.cast<ffi.Uint32>()[3];
          final dataPtr = opPtr + 16;

          final text = convert.utf8.decode(dataPtr.asTypedList(len));

          // Line Wrapping Logic
          final words = text.split(' ');
          for (var j = 0; j < words.length; j++) {
            final word = words[j];
            final wordLen = word.length;
            final prefix = (j == 0) ? '' : ' ';

            if (currentLineWidth + wordLen + prefix.length > terminalWidth) {
              buffer.writeln();
              final indent = fullIndent();
              buffer.write(indent);
              currentLineWidth = indent.length;
            } else if (j > 0) {
              buffer.write(' ');
              currentLineWidth++;
            }

            _applyStyle(buffer, style);
            buffer.write(word);
            _resetStyle(buffer);
            currentLineWidth += wordLen;
          }
          currentOffset += 16 + len;

        case BinaryIR.opNewline:
          buffer.writeln();
          final indent = fullIndent();
          buffer.write(indent);
          currentLineWidth = indent.length;
          currentOffset += 8;

        case BinaryIR.opBoxStart:
          final borderIdx = opPtr.cast<ffi.Uint32>()[1];
          final border = BoxBorderStyle.values[borderIdx];

          // Render Top Border
          buffer.write(
            border.getCorner(
              BoxBorderPosition.top,
              BoxBorderCorner.left,
            ),
          );
          buffer.write(
            border.getChar(BoxBorderPosition.horizontal) *
                (terminalWidth - currentLineWidth - 2),
          );
          buffer.write(
            border.getCorner(
              BoxBorderPosition.top,
              BoxBorderCorner.right,
            ),
          );
          buffer.writeln();

          boxStack.add(_BoxContext(border));
          final indent = fullIndent();
          buffer.write(indent);
          currentLineWidth = indent.length;
          currentOffset += 8;

        case BinaryIR.opBoxEnd:
          if (boxStack.isNotEmpty) {
            final ctx = boxStack.removeLast();
            buffer.writeln();
            final indentBefore = fullIndent();
            buffer
              ..write(indentBefore)
              ..write(
                ctx.border
                    .getCorner(BoxBorderPosition.bottom, BoxBorderCorner.left),
              )
              ..write(
                ctx.border.getChar(BoxBorderPosition.horizontal) *
                    (terminalWidth - indentBefore.length - 2),
              )
              ..write(
                ctx.border
                    .getCorner(BoxBorderPosition.bottom, BoxBorderCorner.right),
              );
          }
          currentOffset += 8;

        case BinaryIR.opIndentStart:
          final len = opPtr.cast<ffi.Uint32>()[3];
          final dataPtr = opPtr + 16;
          final indent = convert.utf8.decode(dataPtr.asTypedList(len));
          indentStack.add(indent);

          final full = fullIndent();
          if (currentLineWidth == 0) {
            buffer.write(full);
            currentLineWidth = full.length;
          }
          currentOffset += 16 + len;

        case BinaryIR.opIndentEnd:
          if (indentStack.length > 1) {
            indentStack.removeLast();
          }
          currentOffset += 8;

        case BinaryIR.opMetadata:
          // Metadata is invisible in ANSI by default, skip
          final pairCount = opPtr.cast<ffi.Uint32>()[1];
          currentOffset += 8;
          for (int j = 0; j < pairCount; j++) {
            final entryPtr = irPtr + currentOffset;
            final keyLen = (entryPtr + 2).cast<ffi.Uint16>()[0];
            final valLenPtr = (entryPtr + 4 + keyLen).cast<ffi.Uint32>();
            final valLen = valLenPtr[0];
            currentOffset += 8 + keyLen + valLen;
          }

        case BinaryIR.opFiller:
          final style = opPtr.cast<ffi.Uint32>()[2];
          final count = opPtr.cast<ffi.Uint32>()[3];
          final char = String.fromCharCode(opPtr[16]);

          _applyStyle(buffer, style);
          buffer.write(char * count);
          _resetStyle(buffer);
          currentLineWidth += count;
          currentOffset += 20;

        default:
          currentOffset += 8;
      }
    }

    return buffer.toString();
  }

  void _applyStyle(final StringBuffer buffer, final int styleBitmask) {
    if (styleBitmask == 0) {
      return;
    }

    buffer.write('\x1B[');
    final codes = <int>[];

    // Colors
    final fg = styleBitmask & 0xF;
    if (fg != 15) {
      codes.add(30 + fg);
    }

    final bg = (styleBitmask >> 4) & 0xF;
    if (bg != 15) {
      codes.add(40 + bg);
    }

    // Flags
    if ((styleBitmask & (1 << 8)) != 0) {
      codes.add(1); // Bold
    }
    if ((styleBitmask & (1 << 9)) != 0) {
      codes.add(2); // Dim
    }
    if ((styleBitmask & (1 << 10)) != 0) {
      codes.add(3); // Italic
    }
    if ((styleBitmask & (1 << 11)) != 0) {
      codes.add(7); // Inverse
    }
    if ((styleBitmask & (1 << 12)) != 0) {
      codes.add(4); // Underline
    }

    buffer
      ..write(codes.join(';'))
      ..write('m');
  }

  void _resetStyle(final StringBuffer buffer) {
    buffer.write('\x1B[0m');
  }
}

class _BoxContext {
  _BoxContext(this.border);
  final BoxBorderStyle border;
  String get padding => border.getChar(BoxBorderPosition.vertical);
}
