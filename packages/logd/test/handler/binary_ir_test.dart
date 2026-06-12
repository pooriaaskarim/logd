import 'dart:ffi' as ffi;

import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart';
import 'package:test/test.dart';

void main() {
  group('Binary IR Standardization', () {
    test('Linearizes a simple log document into B-IR buffer', () {
      final arena = Arena.instance;
      final doc = arena.checkoutDocument() as ArenaDocument;
      // 1. Build a document
      final header = arena.checkoutHeader();
      header.segments.add(
        const StyledText(
          'INFO',
          style: LogStyle(bold: true),
          tags: LogTag.header,
        ),
      );
      doc.nodes.add(header);

      final msg = arena.checkoutMessage();
      msg.segments.add(const StyledText('Hello FFI'));
      doc.nodes.add(msg);

      // 2. Standardize
      final writer = BinaryIRWriter(doc);
      final irPtr = writer.write(doc);

      // 3. Verify Header
      expect(irPtr.cast<ffi.Uint32>()[0], BinaryIR.magic);
      expect(irPtr.cast<ffi.Uint16>()[2], BinaryIR.version);

      // 4. Verify OpCodes
      // Node 1: Header (Text)
      // Offset: 16 (Header)
      final op1 = irPtr + 16;
      expect(op1[0], BinaryIR.opText);
      expect(op1.cast<ffi.Uint32>()[1], LogTag.header);

      // Verify String Data in Op1
      final strLen = op1.cast<ffi.Uint32>()[3];
      expect(strLen, 4); // "INFO"

      // 5. Cleanup
      doc.releaseRecursive(arena);
    });
  });
}
