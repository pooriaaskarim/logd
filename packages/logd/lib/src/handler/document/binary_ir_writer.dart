part of '../handler.dart';

/// An internal utility that standardizes a [LogDocument] into a [BinaryIR]
/// buffer.
///
/// This writer performs a single-pass traversal of the semantic tree and
/// linearizes it into a contiguous block of native memory, suitable for
/// zero-copy consumption by FFI-based engines.
@internal
final class BinaryIRWriter {
  BinaryIRWriter(this._arena);

  final Arena _arena;
  int _nodeCount = 0;
  ffi.Pointer<ffi.Uint8>? _header;

  /// Starts a new Binary IR session.
  void start() {
    _arena.resetNative();
    _nodeCount = 0;

    // Write Header (16 bytes)
    _header = _arena.allocateNative(BinaryIR.headerSize);
    _header!.cast<ffi.Uint32>()[0] = BinaryIR.magic;
    _header!.cast<ffi.Uint16>()[2] = BinaryIR.version;
    _header!.cast<ffi.Uint16>()[3] = 0; // Reserved
  }

  /// Finalizes the session and returns the head pointer.
  ffi.Pointer<ffi.Uint8> finalize() {
    if (_header == null) {
      throw StateError('BinaryIRWriter not started');
    }
    _header!.cast<ffi.Uint32>()[2] = _nodeCount;
    final result = _header!;
    _header = null;
    return result;
  }

  /// Linearizes [document] into a native buffer and returns the head pointer.
  /// (Legacy support for non-streaming paths)
  ffi.Pointer<ffi.Uint8> write(final LogDocument document) {
    start();
    for (final node in document.nodes) {
      _nodeCount += _writeNode(node);
    }
    return finalize();
  }

  /// Linearizes a single [node] into the current buffer.
  void writeNode(final LogNode node) {
    _nodeCount += _writeNode(node);
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

  void writeText(
    final String text, {
    final LogStyle? style,
    final int tags = LogTag.none,
  }) {
    _writeText(text, style: style?.bitmask ?? 0, tags: tags);
    _nodeCount++;
  }

  void writeNewline() {
    _writeOp(BinaryIR.opNewline);
    _nodeCount++;
  }

  void writeBoxStart({
    final BoxBorderStyle border = BoxBorderStyle.rounded,
    final int tags = LogTag.none,
  }) {
    _writeOp(BinaryIR.opBoxStart, tags: tags, payload: border.index);
    _nodeCount++;
  }

  void writeBoxEnd() {
    _writeOp(BinaryIR.opBoxEnd);
    _nodeCount++;
  }

  void writeIndentStart(
    final String indent, {
    final LogStyle? style,
    final int tags = LogTag.none,
  }) {
    _writeIndent(indent, style: style?.bitmask ?? 0, tags: tags);
    _nodeCount++;
  }

  void writeIndentEnd() {
    _writeOp(BinaryIR.opIndentEnd);
    _nodeCount++;
  }

  void writeMap(
    final Map<String, Object?> map, {
    final int tags = LogTag.none,
  }) {
    _writeOp(BinaryIR.opMetadata, tags: tags, payload: map.length);
    for (final entry in map.entries) {
      _writeMetadataEntry(entry.key, entry.value);
    }
    _nodeCount++;
  }

  void _writeOp(final int op, {final int tags = 0, final int payload = 0}) {
    final ptr = _arena.allocateNative(8);
    ptr[0] = op;
    ptr[1] = 0; // Padding
    ptr.cast<ffi.Uint16>()[1] = tags;
    ptr.cast<ffi.Uint32>()[1] = payload;
  }

  void _writeText(
    final String text, {
    final int style = 0,
    final int tags = 0,
  }) {
    final bytes = convert.utf8.encode(text);
    final len = bytes.length;
    final ptr = _arena.allocateNative(16 + len);

    ptr[0] = BinaryIR.opText;
    ptr[1] = 0; // Padding
    ptr.cast<ffi.Uint16>()[1] = tags;
    ptr.cast<ffi.Uint32>()[1] = 0; // Color (Reserved)
    ptr.cast<ffi.Uint32>()[2] = style;
    ptr.cast<ffi.Uint32>()[3] = len;

    (ptr + 16).asTypedList(len).setAll(0, bytes);
  }

  void _writeIndent(
    final String indent, {
    final int style = 0,
    final int tags = 0,
  }) {
    final bytes = convert.utf8.encode(indent);
    final len = bytes.length;
    final ptr = _arena.allocateNative(16 + len);

    ptr[0] = BinaryIR.opIndentStart;
    ptr[1] = 0; // Padding
    ptr.cast<ffi.Uint16>()[1] = tags;
    ptr.cast<ffi.Uint32>()[1] = 0; // Color (Reserved)
    ptr.cast<ffi.Uint32>()[2] = style;
    ptr.cast<ffi.Uint32>()[3] = len;

    (ptr + 16).asTypedList(len).setAll(0, bytes);
  }

  void _writeContentNode(final ContentNode n) {
    for (final segment in n.segments) {
      _writeText(
        segment.text,
        style: segment.style?.bitmask ?? 0,
        tags: n.tags,
      );
    }
  }

  void _writeBoxNode(final BoxNode n) {
    _writeOp(BinaryIR.opBoxStart, tags: n.tags, payload: n.border.index);
  }

  void _writeIndentNode(final IndentationNode n) {
    _writeIndent(n.indentString, style: n.style?.bitmask ?? 0, tags: n.tags);
  }

  void _writeFillerNode(final FillerNode n) {
    final ptr = _arena.allocateNative(20);
    ptr[0] = BinaryIR.opFiller;
    ptr[1] = 0; // Padding
    ptr.cast<ffi.Uint16>()[1] = n.tags;
    ptr.cast<ffi.Uint32>()[1] = 0; // Color (Reserved)
    ptr.cast<ffi.Uint32>()[2] = n.style?.bitmask ?? 0;
    ptr.cast<ffi.Uint32>()[3] = 1; // count
    ptr[16] = n.char.isNotEmpty ? n.char.codeUnitAt(0) : 32; // char
  }

  void _writeMapNode(final MapNode n) {
    _writeOp(BinaryIR.opMetadata, payload: n.map.length);
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
    ptr.cast<ffi.Uint16>()[0] = keyData.length;
    (ptr + 2).asTypedList(keyData.length).setAll(0, keyData);

    final valLenPtr = (ptr + (2 + keyData.length)).cast<ffi.Uint32>();
    valLenPtr[0] = valData.length;
    (ptr + (2 + keyData.length + 4))
        .asTypedList(valData.length)
        .setAll(0, valData);
  }
}
