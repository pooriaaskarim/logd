part of '../handler.dart';

/// An internal utility that standardizes a [LogDocument] into a [BinaryIR]
/// buffer.
///
/// This writer performs a single-pass traversal of the semantic tree and
/// linearizes it into a contiguous block of native memory, suitable for
/// zero-copy consumption by FFI-based engines.
@internal
final class BinaryIRWriter {
  BinaryIRWriter(this._document);

  final ArenaDocument _document;
  Arena get _arena => _document.arena;
  int _nodeCount = 0;
  ffi.Pointer<ffi.Uint8>? _header;

  /// Starts a new Binary IR session.
  void start() {
    _arena.resetNative(_document);
    _nodeCount = 0;

    // Write Header (16 bytes)
    _header = _arena.allocateNative(BinaryIR.headerSize, _document);
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
  ffi.Pointer<ffi.Uint8> write(final LogDocument document) {
    start();
    writeDocumentMetadata(document.metadata);
    for (final node in document.nodes) {
      _writeNode(node);
    }
    return finalize();
  }

  /// Linearizes a single [node] into the current buffer.
  void writeNode(final LogNode node) {
    _writeNode(node);
  }

  void _writeNode(final LogNode node) {
    switch (node) {
      case final ContentNode n:
        _writeContentNode(n);
      case final BoxNode n:
        writeBoxStart(border: n.border, style: n.style, tags: n.tags);
        for (final child in n.children) {
          _writeNode(child);
        }
        writeBoxEnd();
      case final IndentationNode n:
        writeIndentStart(n.indentString, style: n.style, tags: n.tags);
        for (final child in n.children) {
          _writeNode(child);
        }
        writeIndentEnd();
      case final FillerNode n:
        writeFiller(char: n.char, count: n.count, style: n.style, tags: n.tags);
      case final MapNode n:
        writeMap(n.map, tags: n.tags);
      case final ListNode n:
        final map = <String, Object?>{};
        for (int i = 0; i < n.list.length; i++) {
          map[i.toString()] = n.list[i];
        }
        writeMap(map, tags: n.tags);
      case final GroupNode n:
        for (final child in n.children) {
          _writeNode(child);
        }
      case final ParagraphNode n:
        for (final child in n.children) {
          _writeNode(child);
        }
        writeNewline();
      case final SectionNode n:
        _writeNode(n.summary);
        writeNewline();
        for (final child in n.children) {
          _writeNode(child);
        }
        writeNewline();
      case final DecoratedNode n:
        writeDecoratedStart(
          leading: n.leading ?? [],
          leadingWidth: n.leadingWidth,
          leadingHint: n.leadingHint,
          tags: n.tags,
          repeatLeading: n.repeatLeading,
          repeatTrailing: n.repeatTrailing,
          alignTrailing: n.alignTrailing,
          trailing: n.trailing ?? [],
          trailingWidth: n.trailingWidth,
        );
        for (final child in n.children) {
          _writeNode(child);
        }
        writeDecoratedEnd();
      case final RowNode n:
        FillerNode? filler;
        for (final child in n.children) {
          if (child is FillerNode) {
            filler = child;
            break;
          }
        }
        if (filler != null) {
          writeLayoutRowStart(
            char: filler.char,
            style: filler.style,
            tags: filler.tags,
          );
        }
        for (final child in n.children) {
          if (child != filler) {
            _writeNode(child);
          }
        }
        if (filler != null) {
          writeLayoutRowEnd();
        } else {
          writeNewline();
        }
      case final AlignmentNode n:
        writeAlignmentStart(n.alignment, tags: n.tags);
        for (final child in n.children) {
          _writeNode(child);
        }
        writeAlignmentEnd();
      case final TableNode n:
        writeTableStart(columnWidths: n.columnWidths, tags: n.tags);
        for (final child in n.children) {
          _writeNode(child);
        }
        writeTableEnd();
      case final TableRowNode n:
        writeRowStart(tags: n.tags);
        for (final child in n.children) {
          _writeNode(child);
        }
        writeRowEnd();
      case final TableCellNode n:
        writeCellStart(
          columnSpan: n.colSpan,
          rowSpan: n.rowSpan,
          tags: n.tags,
        );
        for (final child in n.children) {
          _writeNode(child);
        }
        writeCellEnd();
    }
  }

  void _writeContentNode(final ContentNode node) {
    for (final segment in node.segments) {
      writeText(
        segment.text,
        style: segment.style,
        tags: segment.tags,
      );
    }
  }

  // --- Public Emitters (Streaming API) ---

  void writeDocumentMetadata(final Map<String, Object?> metadata) {
    if (metadata.isEmpty) {
      return;
    }
    // Standardize GlobalMetadata to 16-byte header
    final ptr = _arena.allocateNative(16, _document);
    ptr[0] = BinaryIR.opGlobalMetadata;
    ptr.cast<ffi.Uint32>()[2] = metadata.length;
    _nodeCount++;

    for (final entry in metadata.entries) {
      final keyBytes = convert.utf8.encode(entry.key);
      final valStr = entry.value.toString();
      final valBytes = convert.utf8.encode(valStr);

      final entryPtr = _arena.allocateNative(
        8 + keyBytes.length + valBytes.length,
        _document,
      );
      entryPtr.cast<ffi.Uint16>()[0] = 0;
      entryPtr.cast<ffi.Uint16>()[1] = keyBytes.length;
      entryPtr.cast<ffi.Uint32>()[1] = valBytes.length;

      final keyPtr = entryPtr + 8;
      for (int i = 0; i < keyBytes.length; i++) {
        keyPtr[i] = keyBytes[i];
      }
      final valPtr = keyPtr + keyBytes.length;
      for (int i = 0; i < valBytes.length; i++) {
        valPtr[i] = valBytes[i];
      }
    }
  }

  void writeText(
    final String text, {
    final Object? style,
    final int tags = LogTag.none,
  }) {
    final mask = style is LogStyle ? style.bitmask : (style is int ? style : 0);
    final bytes = convert.utf8.encode(text);
    final ptr = _arena.allocateNative(16 + bytes.length, _document);
    ptr[0] = BinaryIR.opText;
    ptr.cast<ffi.Uint32>()[1] = tags;
    ptr.cast<ffi.Uint32>()[2] = mask;
    ptr.cast<ffi.Uint32>()[3] = bytes.length;

    final dataPtr = ptr + 16;
    for (int i = 0; i < bytes.length; i++) {
      dataPtr[i] = bytes[i];
    }
    _nodeCount++;
  }

  void writeNewline() {
    final ptr = _arena.allocateNative(8, _document);
    ptr[0] = BinaryIR.opNewline;
    _nodeCount++;
  }

  void writeBoxStart({
    final BoxBorderStyle border = BoxBorderStyle.rounded,
    final Object? style,
    final int tags = LogTag.none,
  }) {
    final mask = style is LogStyle ? style.bitmask : (style is int ? style : 0);
    final ptr = _arena.allocateNative(16, _document);
    ptr[0] = BinaryIR.opBoxStart;
    ptr[1] = border.index;
    ptr.cast<ffi.Uint32>()[1] = tags;
    ptr.cast<ffi.Uint32>()[2] = mask;
    _nodeCount++;
  }

  void writeBoxEnd() {
    final ptr = _arena.allocateNative(8, _document);
    ptr[0] = BinaryIR.opBoxEnd;
    _nodeCount++;
  }

  void writeIndentStart(
    final String indent, {
    final Object? style,
    final int tags = LogTag.none,
  }) {
    final bytes = convert.utf8.encode(indent);
    final ptr = _arena.allocateNative(16 + bytes.length, _document);
    ptr[0] = BinaryIR.opIndentStart;
    ptr.cast<ffi.Uint32>()[1] = tags;
    ptr.cast<ffi.Uint32>()[3] = bytes.length;

    final dataPtr = ptr + 16;
    for (int i = 0; i < bytes.length; i++) {
      dataPtr[i] = bytes[i];
    }
    _nodeCount++;
  }

  void writeIndentEnd() {
    final ptr = _arena.allocateNative(8, _document);
    ptr[0] = BinaryIR.opIndentEnd;
    _nodeCount++;
  }

  void writeMap(
    final Map<String, Object?> data, {
    final int tags = LogTag.none,
  }) {
    final metaPtr = _arena.allocateNative(16, _document);
    metaPtr[0] = BinaryIR.opMetadata;
    metaPtr.cast<ffi.Uint32>()[1] = tags;
    metaPtr.cast<ffi.Uint32>()[2] = data.length;
    _nodeCount++;

    for (final entry in data.entries) {
      final keyBytes = convert.utf8.encode(entry.key);
      final valStr = entry.value.toString();
      final valBytes = convert.utf8.encode(valStr);

      final entryPtr = _arena.allocateNative(
        8 + keyBytes.length + valBytes.length,
        _document,
      );
      entryPtr.cast<ffi.Uint16>()[0] = 0;
      entryPtr.cast<ffi.Uint16>()[1] = keyBytes.length;
      entryPtr.cast<ffi.Uint32>()[1] = valBytes.length;

      final keyPtr = entryPtr + 8;
      for (int i = 0; i < keyBytes.length; i++) {
        keyPtr[i] = keyBytes[i];
      }
      final valPtr = keyPtr + keyBytes.length;
      for (int i = 0; i < valBytes.length; i++) {
        valPtr[i] = valBytes[i];
      }
    }
  }

  void writeTableStart({
    final List<int>? columnWidths,
    final int tags = LogTag.none,
  }) {
    final widths = columnWidths ?? const [];
    final ptr = _arena.allocateNative(16 + (widths.length * 2), _document);
    ptr[0] = BinaryIR.opTableStart;
    ptr[1] = widths.length;
    ptr.cast<ffi.Uint32>()[1] = tags;

    final widthsPtr = ptr.cast<ffi.Uint16>() + 8;
    for (int i = 0; i < widths.length; i++) {
      widthsPtr[i] = widths[i];
    }
    _nodeCount++;
  }

  void writeTableEnd() {
    final ptr = _arena.allocateNative(8, _document);
    ptr[0] = BinaryIR.opTableEnd;
    _nodeCount++;
  }

  void writeCellStart({
    final int columnSpan = 1,
    final int rowSpan = 1,
    final int tags = LogTag.none,
  }) {
    final ptr = _arena.allocateNative(16, _document);
    ptr[0] = BinaryIR.opTableCellStart;
    ptr[1] = columnSpan;
    ptr[2] = rowSpan;
    ptr.cast<ffi.Uint32>()[1] = tags;
    _nodeCount++;
  }

  void writeCellEnd() {
    final ptr = _arena.allocateNative(8, _document);
    ptr[0] = BinaryIR.opTableCellEnd;
    _nodeCount++;
  }

  void writeRowStart({final int tags = LogTag.none}) {
    final ptr = _arena.allocateNative(16, _document);
    ptr[0] = BinaryIR.opTableRowStart;
    ptr.cast<ffi.Uint32>()[1] = tags;
    _nodeCount++;
  }

  void writeRowEnd() {
    final ptr = _arena.allocateNative(8, _document);
    ptr[0] = BinaryIR.opTableRowEnd;
    _nodeCount++;
  }

  void writeDecoratedStart({
    required final List<StyledText> leading,
    final int leadingWidth = 0,
    final String? leadingHint,
    final int tags = LogTag.none,
    final bool repeatLeading = false,
    final bool repeatTrailing = false,
    final bool alignTrailing = false,
    final List<StyledText> trailing = const [],
    final int trailingWidth = 0,
  }) {
    final ptr = _arena.allocateNative(24, _document);
    ptr[0] = BinaryIR.opDecoratedStart;
    ptr[1] = leadingWidth;
    ptr[2] = trailingWidth;

    int flags = 0;
    if (repeatLeading) {
      flags |= 1;
    }
    if (repeatTrailing) {
      flags |= 2;
    }
    if (alignTrailing) {
      flags |= 4;
    }
    ptr[3] = flags;

    ptr.cast<ffi.Uint32>()[1] = tags;

    int hintIdx = 0;
    switch (leadingHint) {
      case DecorationHint.structuredHeader:
        hintIdx = 1;
      case DecorationHint.structuredSeparator:
        hintIdx = 2;
      case DecorationHint.structuredMessage:
        hintIdx = 3;
      case DecorationHint.hierarchyTrace:
        hintIdx = 4;
      case _:
        break;
    }

    ptr.cast<ffi.Uint32>()[2] = hintIdx;
    ptr.cast<ffi.Uint32>()[3] = leading.length;
    ptr.cast<ffi.Uint32>()[4] = trailing.length;

    _nodeCount++;

    for (final segment in leading) {
      writeText(segment.text, style: segment.style, tags: segment.tags);
    }
    for (final segment in trailing) {
      writeText(segment.text, style: segment.style, tags: segment.tags);
    }
  }

  void writeDecoratedEnd() {
    final ptr = _arena.allocateNative(8, _document);
    ptr[0] = BinaryIR.opDecoratedEnd;
    _nodeCount++;
  }

  void writeFiller({
    required final String char,
    final int count = 0,
    final Object? style,
    final int tags = LogTag.none,
  }) {
    final mask = style is LogStyle ? style.bitmask : (style is int ? style : 0);
    final ptr = _arena.allocateNative(16, _document);
    ptr[0] = BinaryIR.opFiller;
    ptr[1] = char.codeUnitAt(0);
    ptr.cast<ffi.Uint32>()[1] = tags;
    ptr.cast<ffi.Uint32>()[2] = mask;
    ptr.cast<ffi.Uint32>()[3] = count;
    _nodeCount++;
  }

  void writeAlignmentStart(
    final LogAlignment alignment, {
    final int tags = LogTag.none,
  }) {
    int alignIdx = 0;
    switch (alignment) {
      case LogAlignment.center:
        alignIdx = 1;
      case LogAlignment.right:
        alignIdx = 2;
      case _:
        break;
    }

    final ptr = _arena.allocateNative(16, _document);
    ptr[0] = BinaryIR.opAlignmentStart;
    ptr[1] = alignIdx;
    ptr.cast<ffi.Uint32>()[1] = tags;
    _nodeCount++;
  }

  void writeAlignmentEnd() {
    final ptr = _arena.allocateNative(8, _document);
    ptr[0] = BinaryIR.opAlignmentEnd;
    _nodeCount++;
  }

  void writeLayoutRowStart({
    required final String char,
    final Object? style,
    final int tags = LogTag.none,
  }) {
    final mask = style is LogStyle ? style.bitmask : (style is int ? style : 0);
    final ptr = _arena.allocateNative(16, _document);
    ptr[0] = BinaryIR.opRowStart;
    ptr[1] = char.codeUnitAt(0);
    ptr.cast<ffi.Uint32>()[1] = tags;
    ptr.cast<ffi.Uint32>()[2] = mask;
    _nodeCount++;
  }

  void writeLayoutRowEnd() {
    final ptr = _arena.allocateNative(8, _document);
    ptr[0] = BinaryIR.opRowEnd;
    _nodeCount++;
  }
}
