import 'dart:ffi' as ffi;

import 'package:logd/src/handler/handler.dart';
import 'package:logd/src/handler/native_handler.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryIR v2 Serialization', () {
    late ArenaDocument doc;
    late BinaryIRWriter writer;

    setUp(() {
      final arena = Arena.instance..clear();
      doc = arena.checkoutDocument() as ArenaDocument;
      writer = BinaryIRWriter(doc);
    });

    test('serializes AlignmentNode', () {
      doc.writeNode(
        AlignmentNode(
          alignment: LogAlignment.center,
          children: [
            MessageNode(segments: [const StyledText('Centered')]),
          ],
        ),
      );

      final ptr = writer.write(doc);

      // Verify Version
      expect(ptr.cast<ffi.Uint16>()[2], equals(2));

      // First Op should be Alignment
      final opAlignment = ptr + BinaryIR.headerSize;
      expect(opAlignment[0], equals(BinaryIR.opAlignmentStart));
      expect(opAlignment[1], equals(BinaryIR.alignCenter));
    });

    test('serializes TableNode with columns', () {
      doc.writeNode(
        TableNode(
          columnWidths: [10, 20],
          children: [
            TableRowNode(
              children: [
                TableCellNode(
                  children: [
                    MessageNode(segments: [const StyledText('Cell 1')]),
                  ],
                ),
                TableCellNode(
                  children: [
                    MessageNode(segments: [const StyledText('Cell 2')]),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final ptr = writer.write(doc);

      int offset = BinaryIR.headerSize;

      // 1. TableStart
      final opTable = ptr + offset;
      expect(opTable[0], equals(BinaryIR.opTableStart));
      expect(opTable[1], equals(2)); // column count

      final widthsPtr = opTable.cast<ffi.Uint16>() + 8;
      expect(widthsPtr[0], equals(10));
      expect(widthsPtr[1], equals(20));

      const alignedSize = (16 + 2 * 2 + 7) & ~7;
      offset += alignedSize;

      // 1.5. TableRowStart
      final opRow = ptr + offset;
      expect(opRow[0], equals(BinaryIR.opTableRowStart));
      offset += 16;

      // 2. CellStart
      final opCell = ptr + offset;
      expect(opCell[0], equals(BinaryIR.opTableCellStart));
      expect(opCell[1], equals(1)); // colSpan

      offset += 16; // TableCellStart is 16 bytes

      // 3. Text ('Cell 1')
      final opText = ptr + offset;
      expect(opText[0], equals(BinaryIR.opText));
      final textLen = opText.cast<ffi.Uint32>()[3];
      // Account for 8-byte alignment in the writer
      final alignedTextSize = (16 + textLen + 7) & ~7;
      offset += alignedTextSize;

      // 4. CellEnd
      expect(ptr[offset], equals(BinaryIR.opTableCellEnd));
    });
  });
}
