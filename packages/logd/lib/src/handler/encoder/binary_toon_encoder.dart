part of '../handler.dart';

/// A high-performance [LogEncoder] that renders a [BinaryIR] stream into
/// Token-Oriented Object Notation (TOON).
///
/// This encoder is used by the Native Engine's background isolate to
/// support structured logging with zero-latency.
@internal
final class BinaryToonEncoder {
  const BinaryToonEncoder();

  /// Renders the [BinaryIR] buffer into TOON format.
  String encode(
    final ffi.Pointer<ffi.Uint8> irPtr,
  ) {
    final buffer = StringBuffer();

    // 1. Read Header
    final magic = irPtr.cast<ffi.Uint32>()[0];
    if (magic != BinaryIR.magic) {
      return 'Error: Invalid Binary IR';
    }

    final nodeCount = irPtr.cast<ffi.Uint32>()[2];
    int currentOffset = BinaryIR.headerSize;

    // 2. State
    final globalMetadata = <String, Object?>{};
    final List<Map<String, Object?>> rows = [];

    // 3. Process Instructions
    for (int i = 0; i < nodeCount; i++) {
      final opPtr = irPtr + currentOffset;
      final op = opPtr[0];

      switch (op) {
        case BinaryIR.opGlobalMetadata:
          final count = opPtr.cast<ffi.Uint32>()[1];
          currentOffset += 8;
          for (int j = 0; j < count; j++) {
            final entry = _readMetadataEntry(irPtr + currentOffset);
            globalMetadata[entry.key] = entry.value;
            currentOffset += entry.totalSize;
          }

        case BinaryIR.opMetadata:
          final count = opPtr.cast<ffi.Uint32>()[1];
          currentOffset += 8;
          final map = <String, Object?>{};
          for (int j = 0; j < count; j++) {
            final entry = _readMetadataEntry(irPtr + currentOffset);
            map[entry.key] = entry.value;
            currentOffset += entry.totalSize;
          }
          rows.add(map);

        case BinaryIR.opText:
          final len = opPtr.cast<ffi.Uint32>()[3];
          currentOffset += 16 + len;
        case BinaryIR.opNewline:
          currentOffset += 8;
        case BinaryIR.opBoxStart:
        case BinaryIR.opBoxEnd:
          currentOffset += 8;
        case BinaryIR.opIndentStart:
          final len = opPtr.cast<ffi.Uint32>()[3];
          currentOffset += 16 + len;
        case BinaryIR.opIndentEnd:
          currentOffset += 8;
        case BinaryIR.opFiller:
          currentOffset += 20;
        default:
          currentOffset += 8;
      }
    }

    // 4. Render TOON
    final arrayName = globalMetadata['toon_array'] as String? ?? 'logs';
    final delimiter = globalMetadata['toon_delimiter'] as String? ?? '\t';
    final columns = globalMetadata['toon_columns'] as List<dynamic>?;

    if (columns == null || rows.isEmpty) {
      return '';
    }

    // Header (Simplified for offload)
    buffer.write('$arrayName[]${columns.join(',')}:');

    // Rows
    for (int i = 0; i < rows.length; i++) {
      final rowMap = rows[i];
      final row = columns.map((final col) {
        final val = rowMap[col.toString()];
        return _escape(val?.toString() ?? '', delimiter);
      }).join(delimiter);
      
      buffer.write(row);
      if (i < rows.length - 1) {
        buffer.write('\n');
      }
    }

    return buffer.toString();
  }

  _MetadataEntry _readMetadataEntry(final ffi.Pointer<ffi.Uint8> ptr) {
    final type = ptr[0];
    final keyLen = (ptr + 2).cast<ffi.Uint16>()[0];
    final key = convert.utf8.decode((ptr + 4).asTypedList(keyLen));

    final valLenPtr = (ptr + 4 + keyLen).cast<ffi.Uint32>();
    final valLen = valLenPtr[0];
    final valStr = convert.utf8.decode((ptr + 8 + keyLen).asTypedList(valLen));

    Object? value = valStr;
    if (type == BinaryIR.metaInt) {
      value = int.tryParse(valStr);
    } else if (type == BinaryIR.metaBool) {
      value = valStr == 'true';
    } else if (type == BinaryIR.metaJson) {
      try {
        value = convert.jsonDecode(valStr);
      } catch (_) {}
    }

    return _MetadataEntry(key, value, 8 + keyLen + valLen);
  }

  String _escape(final String value, final String delimiter) {
    if (value.isEmpty) {
      return '';
    }
    if (!value.contains(delimiter) && !value.contains('\n')) {
      return value;
    }
    return '"${value.replaceAll('"', r'\"').replaceAll('\n', r'\n')}"';
  }
}

class _MetadataEntry {
  _MetadataEntry(this.key, this.value, this.totalSize);
  final String key;
  final Object? value;
  final int totalSize;
}
