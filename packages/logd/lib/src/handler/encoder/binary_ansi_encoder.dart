part of '../handler.dart';

/// A high-performance [LogEncoder] that renders a [BinaryIR] stream into ANSI
/// text.
///
/// This encoder serves as the reference implementation for the Native Engine.
/// It processes the linearized instruction stream (B-IR) in a single pass,
/// minimizing memory allocations and object traversal.
@internal
final class BinaryAnsiEncoder {
  const BinaryAnsiEncoder({
    this.theme = const LogTheme(colorScheme: LogColorScheme.defaultScheme),
  });

  /// The theme used to resolve semantic styles for tags.
  final LogTheme theme;

  /// Renders the [BinaryIR] buffer starting at [irPtr] into a string.
  String encode(
    final ffi.Pointer<ffi.Uint8> irPtr, {
    required final int terminalWidth,
    final LogLevel level = LogLevel.info,
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
    final indentStack = <_IndentEntry>[];
    final tableStack = <_TableState>[];

    String fullIndent() {
      final base = indentStack.map((final e) => e.value).join();
      if (tableStack.isNotEmpty) {
        final state = tableStack.last;
        int tablePad = 0;
        for (int j = 0; j < state.currentColumn; j++) {
          tablePad += state.columnWidths[j] + 2; // +2 for column spacing
        }
        return base + (' ' * tablePad);
      }
      return base;
    }

    void ensureIndent() {
      if (currentLineWidth == 0) {
        final indent = fullIndent();
        buffer.write(indent);
        currentLineWidth = _stripAnsi(indent).length;
      }
    }

    void closeLine() {
      final boxCount = indentStack.whereType<_BoxIndent>().length;
      if (boxCount > 0) {
        ensureIndent();
        final suffixLen = boxCount * 2;
        final paddingNeeded = (terminalWidth - suffixLen - currentLineWidth)
            .clamp(0, terminalWidth);
        if (paddingNeeded > 0) {
          buffer.write(' ' * paddingNeeded);
          currentLineWidth += paddingNeeded;
        }
        for (int j = indentStack.length - 1; j >= 0; j--) {
          final entry = indentStack[j];
          if (entry is _BoxIndent) {
            final sideChar = entry.border.getChar(BoxBorderPosition.vertical);
            buffer.write(' ');
            _applyStyle(buffer, entry.style);
            buffer.write(sideChar);
            _resetStyle(buffer);
            currentLineWidth += 2;
          }
        }
      }
      buffer.writeln();
      currentLineWidth = 0;
    }

    // 3. Process Instructions
    int i = 0;
    while (i < nodeCount) {
      final opPtr = irPtr + currentOffset;
      final op = opPtr[0];

      switch (op) {
        case BinaryIR.opGlobalMetadata:
          final pairCount = opPtr.cast<ffi.Uint32>()[2];
          currentOffset += 16;
          for (int j = 0; j < pairCount; j++) {
            final entryPtr = irPtr + currentOffset;
            final keyLen = (entryPtr + 2).cast<ffi.Uint16>()[0];
            final valLen = (entryPtr + 4).cast<ffi.Uint32>()[0];
            currentOffset += (8 + keyLen + valLen + 7) & ~7;
          }
          break;

        case BinaryIR.opText:
          final tags = opPtr.cast<ffi.Uint32>()[1];
          final styleBitmask = opPtr.cast<ffi.Uint32>()[2];
          final len = opPtr.cast<ffi.Uint32>()[3];
          final dataPtr = opPtr + 16;

          if ((tags & LogTag.preview) != 0) {
            currentOffset += (16 + len + 7) & ~7;
            break;
          }

          final rawText = convert.utf8.decode(dataPtr.asTypedList(len));
          final text = resolveFileUris(rawText);
          final style = styleBitmask != 0
              ? logStyleFromBitmask(styleBitmask)
              : theme.getStyle(level, tags);

          // Handle explicit newlines in the text
          final lines = text.split('\n');
          for (int l = 0; l < lines.length; l++) {
            if (l > 0) {
              closeLine();
            }

            final lineText = lines[l];
            final words = lineText.split(' ');
            for (var j = 0; j < words.length; j++) {
              final word = words[j];
              final wordLen = word.length;
              final spacePrefix = (j == 0) ? '' : ' ';

              ensureIndent();

              final boxCount = indentStack.whereType<_BoxIndent>().length;
              final maxContentWidth = terminalWidth - boxCount * 2;
              if (currentLineWidth + wordLen + spacePrefix.length >
                  maxContentWidth) {
                int indentWidth = 0;
                for (final entry in indentStack) {
                  if (entry is _StringIndent) {
                    indentWidth += entry.value.length;
                  } else if (entry is _BoxIndent) {
                    indentWidth += 2;
                  }
                }
                if (currentLineWidth > indentWidth) {
                  closeLine();
                  ensureIndent();
                }

                final avail = maxContentWidth - currentLineWidth;
                if (wordLen > avail) {
                  var remaining = word;
                  while (remaining.isNotEmpty) {
                    final currentAvail =
                        max(1, maxContentWidth - currentLineWidth);
                    if (remaining.length <= currentAvail) {
                      _applyStyle(buffer, style);
                      buffer.write(remaining);
                      _resetStyle(buffer);
                      currentLineWidth += remaining.length;
                      break;
                    } else {
                      final chunk =
                          remaining.characters.take(currentAvail).toString();
                      _applyStyle(buffer, style);
                      buffer.write(chunk);
                      _resetStyle(buffer);
                      currentLineWidth += chunk.length;

                      remaining = remaining.substring(chunk.length);
                      closeLine();
                      ensureIndent();
                    }
                  }
                } else {
                  _applyStyle(buffer, style);
                  buffer.write(word);
                  _resetStyle(buffer);
                  currentLineWidth += wordLen;
                }
              } else {
                if (j > 0) {
                  buffer.write(' ');
                  currentLineWidth++;
                }
                _applyStyle(buffer, style);
                buffer.write(word);
                _resetStyle(buffer);
                currentLineWidth += wordLen;
              }
            }
          }
          currentOffset += (16 + len + 7) & ~7;
          break;

        case BinaryIR.opNewline:
          closeLine();
          currentOffset += 8;
          break;

        case BinaryIR.opBoxStart:
          final type = opPtr[1];
          final tags = opPtr.cast<ffi.Uint32>()[1];
          final styleBitmask = opPtr.cast<ffi.Uint32>()[2];
          final border = BoxBorderStyle.values[type];
          final style = styleBitmask != 0
              ? logStyleFromBitmask(styleBitmask)
              : theme.getStyle(level, tags);

          ensureIndent();

          _applyStyle(buffer, style);
          buffer.write(
            border.getCorner(BoxBorderPosition.top, BoxBorderCorner.left),
          );
          buffer.write(
            border.getChar(BoxBorderPosition.horizontal) *
                (terminalWidth - currentLineWidth - 2).clamp(0, 1000),
          );
          buffer.write(
            border.getCorner(BoxBorderPosition.top, BoxBorderCorner.right),
          );
          _resetStyle(buffer);
          buffer.writeln();

          indentStack.add(_BoxIndent(border, style, this));
          currentLineWidth = 0;
          currentOffset += 16;
          break;

        case BinaryIR.opBoxEnd:
          if (indentStack.any((final e) => e is _BoxIndent)) {
            if (currentLineWidth > 0) {
              closeLine();
            }
            final idx = indentStack.lastIndexOf(
              indentStack.lastWhere((final e) => e is _BoxIndent),
            );
            final ctx = indentStack.removeAt(idx) as _BoxIndent;
            ensureIndent();
            _applyStyle(buffer, ctx.style);
            buffer
              ..write(
                ctx.border
                    .getCorner(BoxBorderPosition.bottom, BoxBorderCorner.left),
              )
              ..write(
                ctx.border.getChar(BoxBorderPosition.horizontal) *
                    (terminalWidth - currentLineWidth - 2).clamp(0, 1000),
              )
              ..write(
                ctx.border
                    .getCorner(BoxBorderPosition.bottom, BoxBorderCorner.right),
              );
            _resetStyle(buffer);
            buffer.writeln();
            currentLineWidth = 0;
          }
          currentOffset += 8;
          break;

        case BinaryIR.opIndentStart:
          // ignore: unused_local_variable
          final tags = opPtr.cast<ffi.Uint32>()[1];
          final len = opPtr.cast<ffi.Uint32>()[3];
          final dataPtr = opPtr + 16;
          final indent = convert.utf8.decode(dataPtr.asTypedList(len));
          indentStack.add(_StringIndent(indent));
          currentOffset += (16 + len + 7) & ~7;
          break;

        case BinaryIR.opIndentEnd:
          final idx =
              indentStack.lastIndexWhere((final e) => e is _StringIndent);
          if (idx != -1) {
            indentStack.removeAt(idx);
          }
          currentOffset += 8;
          break;

        case BinaryIR.opFiller:
          final char = String.fromCharCode(opPtr[1]);
          final tags = opPtr.cast<ffi.Uint32>()[1];
          final styleBitmask = opPtr.cast<ffi.Uint32>()[2];
          final count = opPtr.cast<ffi.Uint32>()[3];
          final style = styleBitmask != 0
              ? logStyleFromBitmask(styleBitmask)
              : theme.getStyle(level, tags);

          ensureIndent();
          final boxCount = indentStack.whereType<_BoxIndent>().length;
          final maxContentWidth = terminalWidth - boxCount * 2;
          final actualCount = (count == 0)
              ? (maxContentWidth - currentLineWidth).clamp(0, terminalWidth)
              : count;

          _applyStyle(buffer, style);
          buffer.write(char * actualCount);
          _resetStyle(buffer);
          currentLineWidth += actualCount;
          currentOffset += 16;
          break;

        case BinaryIR.opDecoratedStart:
          final leadingWidth = opPtr[1];
          // ignore: unused_local_variable
          final repeatLeading = opPtr[2] == 1;
          // ignore: unused_local_variable
          final repeatTrailing = opPtr[3] == 1;
          // ignore: unused_local_variable
          final tags = opPtr.cast<ffi.Uint32>()[1];
          // ignore: unused_local_variable
          final hintIdx = opPtr.cast<ffi.Uint32>()[2];
          final leadingCount = opPtr.cast<ffi.Uint32>()[3];

          currentOffset += 16;
          ensureIndent();

          final boxCount = indentStack.whereType<_BoxIndent>().length;
          final maxContentWidth = terminalWidth - boxCount * 2;
          final contentWidth =
              maxContentWidth - currentLineWidth - leadingWidth;
          final useFallback = contentWidth < 12 && !repeatLeading;

          final leadingSegments = <StyledText>[];
          final initialWidth = currentLineWidth;

          for (int j = 0; j < leadingCount; j++) {
            final segPtr = irPtr + currentOffset;
            final segOp = segPtr[0];
            if (segOp == BinaryIR.opText) {
              final segTags = segPtr.cast<ffi.Uint32>()[1];
              final segStyleBitmask = segPtr.cast<ffi.Uint32>()[2];
              final segLen = segPtr.cast<ffi.Uint32>()[3];
              final segDataPtr = segPtr + 16;
              final segText =
                  convert.utf8.decode(segDataPtr.asTypedList(segLen));
              final segStyle = segStyleBitmask != 0
                  ? logStyleFromBitmask(segStyleBitmask)
                  : theme.getStyle(level, segTags);

              leadingSegments
                  .add(StyledText(segText, style: segStyle, tags: segTags));

              _applyStyle(buffer, segStyle);
              buffer.write(segText);
              _resetStyle(buffer);
              currentLineWidth += segText.length;
              currentOffset += (16 + segLen + 7) & ~7;
            } else {
              currentOffset += 8;
            }
          }
          i += leadingCount;

          if (useFallback) {
            closeLine();
            indentStack.add(_StringIndent(''));
          } else {
            if (currentLineWidth - initialWidth < leadingWidth) {
              final pad = leadingWidth - (currentLineWidth - initialWidth);
              buffer.write(' ' * pad);
              currentLineWidth += pad;
            }

            if (repeatLeading) {
              final sb = StringBuffer();
              int renderedWidth = 0;
              for (final seg in leadingSegments) {
                _applyStyle(sb, seg.style);
                sb.write(seg.text);
                _resetStyle(sb);
                renderedWidth += seg.text.length;
              }
              if (renderedWidth < leadingWidth) {
                sb.write(' ' * (leadingWidth - renderedWidth));
              }
              indentStack.add(_StringIndent(sb.toString()));
            } else {
              indentStack.add(_StringIndent(' ' * leadingWidth));
            }
          }
          break;

        case BinaryIR.opDecoratedEnd:
          final idx =
              indentStack.lastIndexWhere((final e) => e is _StringIndent);
          if (idx != -1) {
            indentStack.removeAt(idx);
          }
          currentOffset += 8;
          break;

        case BinaryIR.opTableStart:
          final colCount = opPtr[1];
          // ignore: unused_local_variable
          final tags = opPtr.cast<ffi.Uint32>()[1];
          final widthsPtr = opPtr.cast<ffi.Uint16>() + 8;
          final widths = <int>[];
          for (int j = 0; j < colCount; j++) {
            widths.add(widthsPtr[j]);
          }
          tableStack.add(_TableState(widths));
          currentOffset += (16 + colCount * 2 + 7) & ~7;
          break;

        case BinaryIR.opTableEnd:
          if (tableStack.isNotEmpty) {
            tableStack.removeLast();
          }
          currentOffset += 8;
          break;

        case BinaryIR.opTableRowStart:
          if (tableStack.isNotEmpty) {
            tableStack.last.currentColumn = -1;
          }
          currentOffset += 16;
          break;

        case BinaryIR.opTableRowEnd:
          closeLine();
          currentOffset += 8;
          break;

        case BinaryIR.opTableCellStart:
          if (tableStack.isNotEmpty) {
            tableStack.last.currentColumn++;
            tableStack.last.cellStartWidth = currentLineWidth;
          }
          currentOffset += 16;
          break;

        case BinaryIR.opTableCellEnd:
          if (tableStack.isNotEmpty) {
            final state = tableStack.last;
            if (state.currentColumn < state.columnWidths.length) {
              final targetWidth = state.columnWidths[state.currentColumn];
              final cellWidth = currentLineWidth - state.cellStartWidth;
              if (cellWidth < targetWidth) {
                final pad = targetWidth - cellWidth;
                buffer.write(' ' * pad);
                currentLineWidth += pad;
              }
            }
            buffer.write('  '); // Column spacing
            currentLineWidth += 2;
          }
          currentOffset += 8;
          break;

        case BinaryIR.opAlignmentStart:
          final alignIdx = opPtr[1];
          ensureIndent();
          if (alignIdx == BinaryIR.alignCenter) {
            final pad = ((terminalWidth - currentLineWidth) ~/ 4)
                .clamp(0, terminalWidth);
            buffer.write(' ' * pad);
            currentLineWidth += pad;
          } else if (alignIdx == BinaryIR.alignRight) {
            final pad = ((terminalWidth - currentLineWidth) ~/ 2)
                .clamp(0, terminalWidth);
            buffer.write(' ' * pad);
            currentLineWidth += pad;
          }
          currentOffset += 16;
          break;

        case BinaryIR.opAlignmentEnd:
          currentOffset += 8;
          break;

        case BinaryIR.opMetadata:
          // ignore: unused_local_variable
          final tags = opPtr.cast<ffi.Uint32>()[1];
          final pairCount = opPtr.cast<ffi.Uint32>()[2];
          final map = <String, String>{};
          currentOffset += 16;
          for (int j = 0; j < pairCount; j++) {
            final entryPtr = irPtr + currentOffset;
            final keyLen = (entryPtr + 2).cast<ffi.Uint16>()[0];
            final valLen = (entryPtr + 4).cast<ffi.Uint32>()[0];

            final key = convert.utf8.decode((entryPtr + 8).asTypedList(keyLen));
            final val = convert.utf8
                .decode((entryPtr + 8 + keyLen).asTypedList(valLen));
            map[key] = val;

            currentOffset += (8 + keyLen + valLen + 7) & ~7;
          }

          ensureIndent();
          currentLineWidth += _renderJson(buffer, map, level);
          closeLine();
          break;

        default:
          currentOffset += 8;
          break;
      }
      i++;
    }

    return buffer.toString();
  }

  int _renderJson(
    final StringBuffer buffer,
    final Map<String, String> map,
    final LogLevel level,
  ) {
    int length = 0;
    buffer.write('{');
    length += 1;
    int count = 0;
    for (final entry in map.entries) {
      if (count > 0) {
        buffer.write(', ');
        length += 2;
      }

      // Key (Yellow)
      _applyStyle(buffer, theme.getStyle(level, LogTag.loggerName));
      buffer.write('"${entry.key}"');
      _resetStyle(buffer);
      length += entry.key.length + 2;

      buffer.write(': ');
      length += 2;

      // Value (Green/Cyan/White based on content)
      final val = entry.value;
      if (val == 'true' || val == 'false') {
        _applyStyle(buffer, theme.getStyle(level, LogTag.origin));
      } else if (RegExp(r'^-?\d+\.?\d*$').hasMatch(val)) {
        _applyStyle(buffer, theme.getStyle(level, LogTag.timestamp));
      } else {
        _applyStyle(buffer, const LogStyle(color: LogColor.green));
      }
      buffer.write('"${entry.value}"');
      _resetStyle(buffer);
      length += entry.value.length + 2;

      count++;
    }
    buffer.write('}');
    length += 1;
    return length;
  }

  void _applyStyle(final StringBuffer buffer, final LogStyle? style) {
    if (style == null) {
      return;
    }
    final codes = <int>[];

    if (style.bold == true) {
      codes.add(1);
    }
    if (style.dim == true) {
      codes.add(2);
    }
    if (style.italic == true) {
      codes.add(3);
    }
    if (style.inverse == true) {
      codes.add(7);
    }
    if (style.underline == true) {
      codes.add(4);
    }

    if (style.color != null) {
      codes.add(_getColorCode(style.color!, background: false));
    }
    if (style.backgroundColor != null) {
      codes.add(_getColorCode(style.backgroundColor!, background: true));
    }

    if (codes.isEmpty) {
      return;
    }
    buffer.write('\x1B[${codes.join(';')}m');
  }

  int _getColorCode(final LogColor color, {required final bool background}) {
    final base = background ? 40 : 30;
    return switch (color) {
      LogColor.black => base + 0,
      LogColor.red => base + 1,
      LogColor.green => base + 2,
      LogColor.yellow => base + 3,
      LogColor.blue => base + 4,
      LogColor.magenta => base + 5,
      LogColor.cyan => base + 6,
      LogColor.white => base + 7,
      LogColor.brightBlack => base + 60,
      LogColor.brightRed => base + 61,
      LogColor.brightGreen => base + 62,
      LogColor.brightYellow => base + 63,
      LogColor.brightBlue => base + 64,
      LogColor.brightMagenta => base + 65,
      LogColor.brightCyan => base + 66,
      LogColor.brightWhite => base + 67,
    };
  }

  void _resetStyle(final StringBuffer buffer) {
    buffer.write('\x1B[0m');
  }

  String _stripAnsi(final String text) =>
      text.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
}

LogStyle logStyleFromBitmask(final int mask) {
  if (mask == 0) {
    return const LogStyle();
  }
  final fg = mask & 0xF;
  final bg = (mask >> 4) & 0xF;
  return LogStyle(
    color: fg == 15 ? null : LogColor.values[fg],
    backgroundColor: bg == 15 ? null : LogColor.values[bg],
    bold: (mask & (1 << 8)) != 0,
    dim: (mask & (1 << 9)) != 0,
    italic: (mask & (1 << 10)) != 0,
    inverse: (mask & (1 << 11)) != 0,
    underline: (mask & (1 << 12)) != 0,
  );
}

abstract class _IndentEntry {
  String get value;
}

class _StringIndent extends _IndentEntry {
  _StringIndent(this.value);
  @override
  final String value;
}

class _BoxIndent extends _IndentEntry {
  _BoxIndent(this.border, this.style, this.encoder);
  final BoxBorderStyle border;
  final LogStyle? style;
  final BinaryAnsiEncoder encoder;

  @override
  String get value {
    final sb = StringBuffer();
    encoder._applyStyle(sb, style);
    sb.write(border.getChar(BoxBorderPosition.vertical));
    encoder._resetStyle(sb);
    sb.write(' ');
    return sb.toString();
  }
}

class _TableState {
  _TableState(this.columnWidths);
  final List<int> columnWidths;
  int currentColumn = -1;
  int cellStartWidth = 0;
}
