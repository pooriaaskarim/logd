part of '../handler.dart';

/// An internal utility that standardizes a [LogDocument] into a [BinaryIR] buffer.
///
/// This writer performs a single-pass traversal of the semantic tree and
/// linearizes it into a contiguous block of native memory, suitable for
/// zero-copy consumption by FFI-based engines.
@internal
final class BinaryIRWriter {
  BinaryIRWriter(this._arena);

  final Arena _arena;

  /// Linearizes [document] into a native buffer and returns the head pointer.
  ffi.Pointer<ffi.Uint8> write(final LogDocument document) {
    _arena.resetNative();

    // 1. Write Header (16 bytes)
    final header = _arena.allocateNative(BinaryIR.headerSize);
    header.cast<ffi.Uint32>()[0] = BinaryIR.magic;
    header.cast<ffi.Uint16>()[2] = BinaryIR.version;
    header.cast<ffi.Uint16>()[3] = 0; // Reserved
    // We'll update Node Count at the end.
    
    int nodeCount = 0;

    // 2. Traverse Nodes
    for (final node in document.nodes) {
      nodeCount += _writeNode(node);
    }

    // 3. Update Node Count in Header
    header.cast<ffi.Uint32>()[2] = nodeCount;

    return header;
  }

  int _writeNode(final LogNode node) {
    int count = 1;
    switch (node) {
      case final ContentNode n:
        count = n.segments.length; // Each segment is an opText
        _writeContentNode(n);
      case final BoxNode n:
        _writeBoxNode(n);
        for (final child in n.children) {
          count += _writeNode(child);
        }
        _writeOp(BinaryIR.opBoxEnd);
      case final IndentationNode n:
        _writeIndentNode(n);
        for (final child in n.children) {
          count += _writeNode(child);
        }
        _writeOp(BinaryIR.opIndentEnd);
      case final FillerNode n:
        _writeFillerNode(n);
      case final MapNode n:
        _writeMapNode(n);
      case final ListNode n:
        _writeListNode(n);
      case final GroupNode n:
        count = 0;
        for (final child in n.children) {
          count += _writeNode(child);
        }
        return count;
      case final DecoratedNode n:
        // For now, treat as a group, native engine will need more logic
        count = 0;
        for (final child in n.children) {
          count += _writeNode(child);
        }
        return count;
      case final RowNode n:
        // Row nodes are structural but transparent to LIS for now
        count = 0;
        for (final child in n.children) {
          count += _writeNode(child);
        }
        return count;
      default:
        return 0;
    }
    return count;
  }

  void _writeOp(final int op, {final int tags = 0, final int payload = 0}) {
    final ptr = _arena.allocateNative(8);
    ptr[0] = op;
    ptr[1] = 0; // Flags
    ptr.cast<ffi.Uint16>()[1] = tags;
    ptr.cast<ffi.Uint32>()[1] = payload;
  }

  void _writeContentNode(final ContentNode n) {
    for (final segment in n.segments) {
      final text = segment.text;
      final utf8Data = convert.utf8.encode(text);
      final ptr = _arena.allocateNative(12 + utf8Data.length);
      
      ptr[0] = BinaryIR.opText;
      ptr[1] = 0;
      ptr.cast<ffi.Uint16>()[1] = n.tags;
      ptr.cast<ffi.Uint32>()[1] = segment.style?.bitmask ?? 0;
      ptr.cast<ffi.Uint32>()[2] = utf8Data.length;
      
      final dataPtr = ptr.elementAt(12);
      for (int i = 0; i < utf8Data.length; i++) {
        dataPtr[i] = utf8Data[i];
      }
    }
  }

  void _writeBoxNode(final BoxNode n) {
    _writeOp(BinaryIR.opBoxStart, tags: n.tags, payload: n.border.index);
  }

  void _writeIndentNode(final IndentationNode n) {
    final indentData = convert.utf8.encode(n.indentString);
    final ptr = _arena.allocateNative(12 + indentData.length);
    
    ptr[0] = BinaryIR.opIndentStart;
    ptr[1] = 0;
    ptr.cast<ffi.Uint16>()[1] = n.tags;
    ptr.cast<ffi.Uint32>()[1] = n.style?.bitmask ?? 0;
    ptr.cast<ffi.Uint32>()[2] = indentData.length;
    
    final dataPtr = ptr.elementAt(12);
    for (int i = 0; i < indentData.length; i++) {
      dataPtr[i] = indentData[i];
    }
  }

  void _writeFillerNode(final FillerNode n) {
    final ptr = _arena.allocateNative(13);
    ptr[0] = BinaryIR.opFiller;
    ptr.cast<ffi.Uint16>()[1] = n.tags;
    ptr.cast<ffi.Uint32>()[1] = n.style?.bitmask ?? 0;
    ptr[8] = n.char.isNotEmpty ? n.char.codeUnitAt(0) : 32; // Space default
    ptr.cast<ffi.Uint32>()[2] = 1;
  }

  void _writeMapNode(final MapNode n) {
    // Write OpCode
    _writeOp(BinaryIR.opMetadata, payload: n.map.length);
    
    // Write entries sequentially
    for (final entry in n.map.entries) {
      _writeMetadataEntry(entry.key, entry.value);
    }
  }

  void _writeListNode(final ListNode n) {
    _writeOp(BinaryIR.opMetadata, payload: n.list.length);
    for (int i = 0; i < n.list.length; i++) {
      _writeMetadataEntry(i.toString(), n.list[i]);
    }
  }

  void _writeMetadataEntry(final String key, final Object? value) {
    final keyData = convert.utf8.encode(key);
    final valStr = value?.toString() ?? 'null';
    final valData = convert.utf8.encode(valStr);
    
    final ptr = _arena.allocateNative(8 + keyData.length + valData.length);
    // [uint16 keyLen][char[] key][uint32 valLen][char[] val]
    ptr.cast<ffi.Uint16>()[0] = keyData.length;
    
    final keyPtr = ptr.elementAt(2);
    for (int i = 0; i < keyData.length; i++) keyPtr[i] = keyData[i];
    
    final valLenPtr = keyPtr.elementAt(keyData.length).cast<ffi.Uint32>();
    valLenPtr[0] = valData.length;
    
    final valPtr = valLenPtr.elementAt(1).cast<ffi.Uint8>();
    for (int i = 0; i < valData.length; i++) valPtr[i] = valData[i];
  }
}
