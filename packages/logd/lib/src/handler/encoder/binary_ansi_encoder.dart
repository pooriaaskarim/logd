part of '../native_handler.dart';

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
    LogStyle? activeStyle;

    void applyStyle(final StringBuffer _, final LogStyle? style) {
      if (activeStyle == style) {
        return;
      }
      if (activeStyle != null) {
        buffer.write('\x1B[0m');
        activeStyle = null;
      }
      if (style != null) {
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
        if (codes.isNotEmpty) {
          buffer.write('\x1B[${codes.join(';')}m');
          activeStyle = style;
        }
      }
    }

    void resetStyle(final StringBuffer buffer) {
      if (activeStyle != null) {
        buffer.write('\x1B[0m');
        activeStyle = null;
      }
    }

    void forceResetStyle() {
      resetStyle(buffer);
    }

    final indentStack = <_IndentEntry>[];
    final tableStack = <_TableState>[];
    final decoratedStack = <_DecoratedState>[];
    final rowFillerStack = <_RowFiller>[];
    _RowFiller? activeRowFiller() =>
        rowFillerStack.isNotEmpty ? rowFillerStack.last : null;

    int activeTrailingWidth() {
      int w = 0;
      for (final state in decoratedStack) {
        w += state.trailingWidth;
      }
      return w;
    }

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

    int getVisualLength(final String text, final int startPos) {
      int length = 0;
      int currentPos = startPos;
      for (final char in text.characters) {
        if (char == '\t') {
          final advance = 8 - (currentPos % 8);
          length += advance;
          currentPos += advance;
        } else {
          final advance = isWide(char) ? 2 : 1;
          length += advance;
          currentPos += advance;
        }
      }
      return length;
    }

    void ensureIndent() {
      if (currentLineWidth == 0) {
        for (final entry in indentStack) {
          entry.write(buffer, applyStyle);
        }
        if (tableStack.isNotEmpty) {
          final state = tableStack.last;
          int tablePad = 0;
          for (int j = 0; j < state.currentColumn; j++) {
            tablePad += state.columnWidths[j] + 2;
          }
          if (tablePad > 0) {
            applyStyle(buffer, null);
            buffer.write(' ' * tablePad);
          }
        }
        final indent = fullIndent();
        currentLineWidth = getVisualLength(indent, 0);
      }
    }

    _WrappedSegment wrapSegmentText(
      final String text,
      final int startLength,
      final int availableWidth, {
      required final bool noWrap,
    }) {
      if (noWrap) {
        return _WrappedSegment(text.split('\n'), '');
      }

      final completedLines = <String>[];
      var currentLineText = '';
      var currentLength = startLength;

      final physicalLines = text.split('\n');
      for (var l = 0; l < physicalLines.length; l++) {
        if (l > 0) {
          completedLines.add(currentLineText);
          currentLineText = '';
          currentLength = 0;
        }

        final lineText = physicalLines[l];
        if (lineText.isEmpty) {
          continue;
        }

        final words = lineText.split(' ');
        for (var i = 0; i < words.length; i++) {
          final isLastWord = i == words.length - 1;
          var word = words[i];
          if (!isLastWord) {
            word = '$word ';
          }

          // If even the single word is too long, we must break it
          if (getVisualLength(word, 0) > availableWidth) {
            if (currentLineText.isNotEmpty) {
              completedLines.add(currentLineText);
              currentLineText = '';
              currentLength = 0;
            } else if (currentLength > 0) {
              completedLines.add('');
              currentLength = 0;
            }

            var remaining = word;
            while (remaining.isNotEmpty &&
                getVisualLength(remaining, 0) > availableWidth) {
              var fitLen = 0;
              var takeCount = 0;
              for (final char in remaining.characters) {
                final clen =
                    (char == '\t') ? 8 - (fitLen % 8) : (isWide(char) ? 2 : 1);
                if (fitLen + clen > availableWidth && takeCount > 0) {
                  break;
                }
                fitLen += clen;
                takeCount += char.length;
              }

              final chunk = remaining.substring(0, takeCount);
              completedLines.add(chunk);
              remaining = remaining.substring(takeCount);
            }
            if (remaining.isNotEmpty) {
              currentLineText = remaining;
              currentLength = getVisualLength(remaining, 0);
            }
            continue;
          }

          final wordLenTrimmed = getVisualLength(
            word.replaceFirst(RegExp(r' +$'), ''),
            currentLength,
          );
          if (currentLength + wordLenTrimmed > availableWidth &&
              currentLength > 0) {
            if (currentLineText.isNotEmpty) {
              completedLines.add(currentLineText);
              currentLineText = '';
            } else {
              completedLines.add('');
            }
            currentLength = 0;
          }

          currentLineText += word;
          currentLength += getVisualLength(word, currentLength);
        }
      }

      return _WrappedSegment(completedLines, currentLineText);
    }

    void closeLine() {
      final filler = activeRowFiller();
      if (filler != null) {
        final boxCount = indentStack.whereType<_BoxIndent>().length;
        final maxContentWidth =
            terminalWidth - boxCount * 2 - activeTrailingWidth();
        final pad = maxContentWidth - currentLineWidth;
        if (pad > 0) {
          applyStyle(buffer, filler.style);
          buffer.write(filler.char * pad);
          currentLineWidth += pad;
        }
      }

      // 1. Render trailing decorations
      for (int i = decoratedStack.length - 1; i >= 0; i--) {
        final state = decoratedStack[i];
        final isFirst = state.isFirstLine;
        state.isFirstLine = false;

        final showTrailing = isFirst || state.repeatTrailing;
        if (state.alignTrailing) {
          int outerTrailingWidth = 0;
          for (int k = 0; k < i; k++) {
            final outerState = decoratedStack[k];
            outerTrailingWidth += outerState.trailingWidth;
          }
          final boxCount = indentStack.whereType<_BoxIndent>().length;
          final targetPos = terminalWidth -
              (boxCount * 2) -
              outerTrailingWidth -
              state.trailingWidth;
          final pad = targetPos - currentLineWidth;
          if (pad > 0) {
            final filler = activeRowFiller();
            if (filler != null) {
              applyStyle(buffer, filler.style);
              buffer.write(filler.char * pad);
            } else {
              final innermostBox =
                  indentStack.reversed.whereType<_BoxIndent>().firstOrNull;
              final style = (innermostBox != null)
                  ? innermostBox.style
                  : theme.getStyle(level, LogTag.none);
              applyStyle(buffer, style);
              buffer.write(' ' * pad);
            }
            currentLineWidth += pad;
          }
        }

        if (showTrailing && state.trailingSegments.isNotEmpty) {
          for (final seg in state.trailingSegments) {
            applyStyle(buffer, seg.style);
            buffer.write(seg.text);
            currentLineWidth += getVisualLength(seg.text, currentLineWidth);
          }
        } else if (state.trailingWidth > 0) {
          final filler = activeRowFiller();
          if (filler != null) {
            applyStyle(buffer, filler.style);
            buffer.write(filler.char * state.trailingWidth);
          } else {
            final style = theme.getStyle(level, LogTag.none);
            applyStyle(buffer, style);
            buffer.write(' ' * state.trailingWidth);
          }
          currentLineWidth += state.trailingWidth;
        }
      }

      // 2. Pad to the right box borders and print them
      final boxCount = indentStack.whereType<_BoxIndent>().length;
      if (boxCount > 0) {
        ensureIndent();
        final suffixLen = boxCount * 2;
        final paddingNeeded = (terminalWidth - suffixLen - currentLineWidth)
            .clamp(0, terminalWidth);

        if (paddingNeeded > 0) {
          final filler = activeRowFiller();
          if (filler != null) {
            applyStyle(buffer, filler.style);
            buffer.write(filler.char * paddingNeeded);
          } else {
            final innermostBox =
                indentStack.reversed.whereType<_BoxIndent>().firstOrNull;
            final style = (innermostBox != null)
                ? innermostBox.style
                : theme.getStyle(level, LogTag.none);
            applyStyle(buffer, style);
            buffer.write(' ' * paddingNeeded);
          }
          currentLineWidth += paddingNeeded;
        }

        for (int j = indentStack.length - 1; j >= 0; j--) {
          final entry = indentStack[j];
          if (entry is _BoxIndent) {
            final sideChar = entry.border.getChar(BoxBorderPosition.vertical);
            applyStyle(buffer, entry.style);
            buffer.write(' ');
            applyStyle(buffer, entry.style);
            buffer.write(sideChar);
            currentLineWidth += 2;
          }
        }
      }
      forceResetStyle();
      buffer.writeln();
      currentLineWidth = 0;
    }

    void renderJsonWrapped(final Map<String, String> map, final int tags) {
      final jsonStr = convert.jsonEncode(map);
      final style = theme.getStyle(level, tags);

      if ((tags & LogTag.noWrap) != 0) {
        ensureIndent();
        applyStyle(buffer, style);
        buffer.write(jsonStr);
        currentLineWidth +=
            getVisualLength(_stripAnsi(jsonStr), currentLineWidth);
        closeLine();
        return;
      }

      final contentSegments = <StyledText>[];

      void flushContentSegments() {
        if (contentSegments.isNotEmpty) {
          final last = contentSegments.last;
          final trimmedText = last.text.replaceFirst(RegExp(r' +$'), '');
          if (trimmedText != last.text) {
            final diff = last.text.length - trimmedText.length;
            currentLineWidth -= diff;
            contentSegments[contentSegments.length - 1] =
                StyledText(trimmedText, style: last.style, tags: last.tags);
          }
          for (final seg in contentSegments) {
            if (seg.text.isEmpty) {
              continue;
            }
            applyStyle(buffer, seg.style ?? style);
            buffer.write(seg.text);
          }
          contentSegments.clear();
        }
      }

      final lines = jsonStr.split('\n');
      for (int l = 0; l < lines.length; l++) {
        if (l > 0) {
          flushContentSegments();
          closeLine();
        }

        final lineText = lines[l];
        if (lineText.isEmpty) {
          continue;
        }

        final boxCount = indentStack.whereType<_BoxIndent>().length;
        final maxContentWidth =
            terminalWidth - boxCount * 2 - activeTrailingWidth();

        final words = lineText.split(' ');
        for (var j = 0; j < words.length; j++) {
          final isLastWord = j == words.length - 1;
          final rawWord = words[j];
          final word = isLastWord ? rawWord : '$rawWord ';

          final indentWidth = getVisualLength(fullIndent(), 0);

          final trimmedWord = word.replaceFirst(RegExp(r' +$'), '');
          final wordLenTrimmed = getVisualLength(trimmedWord, currentLineWidth);

          if (currentLineWidth + wordLenTrimmed > maxContentWidth &&
              currentLineWidth > indentWidth) {
            flushContentSegments();
            closeLine();
            ensureIndent();
          }

          ensureIndent();

          final wordLen = getVisualLength(word, currentLineWidth);
          final availableWidth = maxContentWidth - indentWidth;

          if (wordLen > availableWidth) {
            if (currentLineWidth > indentWidth) {
              flushContentSegments();
              closeLine();
              ensureIndent();
            }

            var remaining = word;
            while (remaining.isNotEmpty) {
              final currentAvail = max(1, maxContentWidth - currentLineWidth);
              final remLen = getVisualLength(remaining, currentLineWidth);
              if (remLen <= currentAvail) {
                contentSegments.add(StyledText(remaining, style: style));
                currentLineWidth += remLen;
                break;
              } else {
                var chunk = '';
                var chunkWidth = 0;
                for (final char in remaining.characters) {
                  final charWidth =
                      getVisualLength(char, currentLineWidth + chunkWidth);
                  if (chunkWidth + charWidth <= currentAvail || chunk.isEmpty) {
                    chunk += char;
                    chunkWidth += charWidth;
                  } else {
                    break;
                  }
                }
                contentSegments.add(StyledText(chunk, style: style));
                currentLineWidth += chunkWidth;

                remaining = remaining.substring(chunk.length);
                flushContentSegments();
                closeLine();
                ensureIndent();
              }
            }
          } else {
            if (word.isNotEmpty) {
              contentSegments.add(StyledText(word, style: style));
              currentLineWidth += wordLen;
            }
          }
        }
      }
      flushContentSegments();
      closeLine();
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

          void openStyle() {
            applyStyle(buffer, style);
          }

          final noWrap = (tags & LogTag.noWrap) != 0;
          final boxCount = indentStack.whereType<_BoxIndent>().length;
          final maxContentWidth =
              terminalWidth - boxCount * 2 - activeTrailingWidth();

          final indentWidth = getVisualLength(fullIndent(), 0);
          final textLen = currentLineWidth == 0
              ? getVisualLength(text, indentWidth)
              : getVisualLength(text, currentLineWidth);
          final expectedWidth = currentLineWidth == 0
              ? indentWidth + textLen
              : currentLineWidth + textLen;

          if (noWrap || (expectedWidth <= maxContentWidth)) {
            final lines = text.split('\n');
            for (int l = 0; l < lines.length; l++) {
              if (l > 0) {
                closeLine();
              }
              ensureIndent();
              final lineText = lines[l];
              if (lineText.isNotEmpty) {
                openStyle();
                buffer.write(lineText);
                currentLineWidth += getVisualLength(lineText, currentLineWidth);
              }
            }
          } else {
            final indentWidth = getVisualLength(fullIndent(), 0);
            final wrapped = wrapSegmentText(
              text,
              max(0, currentLineWidth - indentWidth),
              max(0, maxContentWidth - indentWidth),
              noWrap: noWrap,
            );

            for (final line in wrapped.completedLines) {
              ensureIndent();
              final trimmed = line.replaceFirst(RegExp(r' +$'), '');
              if (trimmed.isNotEmpty) {
                openStyle();
                buffer.write(trimmed);
                currentLineWidth += getVisualLength(trimmed, currentLineWidth);
              }
              closeLine();
            }

            if (wrapped.activeLine.isNotEmpty) {
              ensureIndent();
              openStyle();
              buffer.write(wrapped.activeLine);
              currentLineWidth +=
                  getVisualLength(wrapped.activeLine, currentLineWidth);
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

          applyStyle(buffer, style);
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
          resetStyle(buffer);
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
            applyStyle(buffer, ctx.style);
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
            resetStyle(buffer);
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
          final maxContentWidth =
              terminalWidth - boxCount * 2 - activeTrailingWidth();
          final actualCount = (count == 0)
              ? (maxContentWidth - currentLineWidth).clamp(0, terminalWidth)
              : count;

          applyStyle(buffer, style);
          buffer.write(char * actualCount);
          currentLineWidth += actualCount;
          currentOffset += 16;
          break;

        case BinaryIR.opDecoratedStart:
          final leadingWidth = opPtr[1];
          final trailingWidth = opPtr[2];
          final flags = opPtr[3];
          final repeatLeading = (flags & 1) != 0;
          final repeatTrailing = (flags & 2) != 0;
          final alignTrailing = (flags & 4) != 0;
          // ignore: unused_local_variable
          final tags = opPtr.cast<ffi.Uint32>()[1];
          final hintIdx = opPtr.cast<ffi.Uint32>()[2];
          final leadingCount = opPtr.cast<ffi.Uint32>()[3];
          final trailingCount = opPtr.cast<ffi.Uint32>()[4];

          currentOffset += 24;
          ensureIndent();

          final boxCount = indentStack.whereType<_BoxIndent>().length;
          final maxContentWidth = terminalWidth -
              boxCount * 2 -
              activeTrailingWidth() -
              trailingWidth;
          final contentWidth =
              maxContentWidth - currentLineWidth - leadingWidth;
          final useFallback =
              contentWidth < 12 && !repeatLeading && leadingCount > 0;

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

              if (!useFallback) {
                applyStyle(buffer, segStyle);
                buffer.write(segText);
                currentLineWidth += getVisualLength(segText, currentLineWidth);
              }
              currentOffset += (16 + segLen + 7) & ~7;
            } else {
              currentOffset += 8;
            }
          }

          final trailingSegments = <StyledText>[];
          for (int j = 0; j < trailingCount; j++) {
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

              trailingSegments
                  .add(StyledText(segText, style: segStyle, tags: segTags));
              currentOffset += (16 + segLen + 7) & ~7;
            } else {
              currentOffset += 8;
            }
          }

          i += leadingCount + trailingCount;

          final state = _DecoratedState(
            leadingWidth: useFallback ? 0 : leadingWidth,
            trailingSegments: useFallback ? const [] : trailingSegments,
            trailingWidth: useFallback ? 0 : trailingWidth,
            repeatTrailing: !useFallback && repeatTrailing,
            alignTrailing: !useFallback && alignTrailing,
          );
          decoratedStack.add(state);

          if (useFallback) {
            for (final segment in leadingSegments) {
              final text = resolveFileUris(segment.text);
              final style = segment.style;
              final lines = text.split('\n');
              for (int l = 0; l < lines.length; l++) {
                if (l > 0) {
                  closeLine();
                }

                final lineText = lines[l];
                if (lineText.isEmpty) {
                  continue;
                }

                final dynamicMaxContentWidth =
                    terminalWidth - boxCount * 2 - activeTrailingWidth();

                final words = lineText.split(' ');
                for (var j = 0; j < words.length; j++) {
                  final isLastWord = j == words.length - 1;
                  var word = words[j];

                  // 1. Check if the current word (without space) wraps.
                  final currentWordLen =
                      getVisualLength(word, currentLineWidth);

                  if (currentLineWidth + currentWordLen >
                      dynamicMaxContentWidth) {
                    final indentWidth = getVisualLength(fullIndent(), 0);
                    if (currentLineWidth > indentWidth) {
                      closeLine();
                    }
                  }

                  ensureIndent();

                  // 2. Now currentLineWidth is where the word will be printed.
                  final wordStartLineWidth = currentLineWidth;

                  // 3. Determine if we should append a space
                  bool appendSpace = !isLastWord;
                  bool forceCloseAfter = false;
                  if (appendSpace) {
                    final currentWordLenWithSpace =
                        getVisualLength('$word ', wordStartLineWidth);
                    final nextWord = words[j + 1];
                    final nextWordLen = getVisualLength(
                      nextWord,
                      wordStartLineWidth + currentWordLenWithSpace,
                    );
                    if (wordStartLineWidth +
                            currentWordLenWithSpace +
                            nextWordLen >
                        dynamicMaxContentWidth) {
                      appendSpace = false;
                      forceCloseAfter = true;
                    }
                  }

                  if (appendSpace) {
                    word = '$word ';
                  }
                  final wordLen = getVisualLength(word, currentLineWidth);

                  if (word.isNotEmpty) {
                    final avail = dynamicMaxContentWidth - currentLineWidth;
                    if (wordLen > avail) {
                      // Word is too long, we must chunk it
                      var remaining = word;
                      while (remaining.isNotEmpty) {
                        final currentAvail =
                            max(1, dynamicMaxContentWidth - currentLineWidth);
                        final remLen =
                            getVisualLength(remaining, currentLineWidth);
                        if (remLen <= currentAvail) {
                          applyStyle(buffer, style);
                          buffer.write(remaining);
                          currentLineWidth += remLen;
                          break;
                        } else {
                          var chunk = '';
                          var chunkWidth = 0;
                          for (final char in remaining.characters) {
                            final charWidth = getVisualLength(
                              char,
                              currentLineWidth + chunkWidth,
                            );
                            if (chunkWidth + charWidth <= currentAvail ||
                                chunk.isEmpty) {
                              chunk += char;
                              chunkWidth += charWidth;
                            } else {
                              break;
                            }
                          }
                          applyStyle(buffer, style);
                          buffer.write(chunk);
                          currentLineWidth += chunkWidth;

                          remaining = remaining.substring(chunk.length);
                          closeLine();
                          ensureIndent();
                        }
                      }
                    } else {
                      applyStyle(buffer, style);
                      buffer.write(word);
                      currentLineWidth += wordLen;
                    }
                  }

                  if (forceCloseAfter) {
                    closeLine();
                  }
                }
              }
            }
            closeLine();
            indentStack.add(_StringIndent(''));
          } else {
            if (currentLineWidth - initialWidth < leadingWidth) {
              final pad = leadingWidth - (currentLineWidth - initialWidth);
              buffer.write(' ' * pad);
              currentLineWidth += pad;
            }

            if (repeatLeading) {
              final segs = List<StyledText>.from(leadingSegments);
              int renderedWidth = 0;
              for (final seg in leadingSegments) {
                renderedWidth += getVisualLength(seg.text, renderedWidth);
              }
              if (renderedWidth < leadingWidth) {
                segs.add(StyledText(' ' * (leadingWidth - renderedWidth)));
              }
              indentStack.add(_DecoratedIndent(segs));
            } else {
              String rawDec = ' ' * leadingWidth;
              if (hintIdx == 1 || hintIdx == 2) {
                rawDec = '_' * leadingWidth;
              } else if (hintIdx == 4) {
                rawDec = '│${' ' * (leadingWidth - 1)}';
              }
              final decStyle = theme.getStyle(level, LogTag.hierarchy);
              indentStack
                  .add(_DecoratedIndent([StyledText(rawDec, style: decStyle)]));
            }
          }
          break;

        case BinaryIR.opDecoratedEnd:
          if (decoratedStack.isNotEmpty) {
            decoratedStack.removeLast();
          }
          final idx = indentStack.lastIndexWhere(
            (final e) => e is _DecoratedIndent || e is _StringIndent,
          );
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

          renderJsonWrapped(map, tags);
          break;

        case BinaryIR.opRowStart:
          final char = String.fromCharCode(opPtr[1]);
          final tags = opPtr.cast<ffi.Uint32>()[1];
          final styleBitmask = opPtr.cast<ffi.Uint32>()[2];
          final style = styleBitmask != 0
              ? logStyleFromBitmask(styleBitmask)
              : theme.getStyle(level, tags);
          rowFillerStack.add(_RowFiller(char, style));
          currentOffset += 16;
          break;

        case BinaryIR.opRowEnd:
          closeLine();
          if (rowFillerStack.isNotEmpty) {
            rowFillerStack.removeLast();
          }
          currentOffset += 8;
          break;

        default:
          currentOffset += 8;
          break;
      }
      i++;
    }

    if (currentLineWidth > 0) {
      closeLine();
    }
    forceResetStyle();

    return buffer.toString();
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
  void write(
    final StringBuffer buffer,
    final void Function(StringBuffer, LogStyle?) applyStyle,
  );
}

class _StringIndent extends _IndentEntry {
  _StringIndent(this.value);
  @override
  final String value;
  @override
  void write(
    final StringBuffer buffer,
    final void Function(StringBuffer, LogStyle?) applyStyle,
  ) {
    if (value.isNotEmpty) {
      applyStyle(buffer, null);
      buffer.write(value);
    }
  }
}

class _BoxIndent extends _IndentEntry {
  _BoxIndent(this.border, this.style, this.encoder);
  final BoxBorderStyle border;
  final LogStyle? style;
  final BinaryAnsiEncoder encoder;

  @override
  String get value => '${border.getChar(BoxBorderPosition.vertical)} ';

  @override
  void write(
    final StringBuffer buffer,
    final void Function(StringBuffer, LogStyle?) applyStyle,
  ) {
    applyStyle(buffer, style);
    buffer.write(border.getChar(BoxBorderPosition.vertical));
    applyStyle(buffer, style);
    buffer.write(' ');
  }
}

class _DecoratedIndent extends _IndentEntry {
  _DecoratedIndent(this.segments);
  final List<StyledText> segments;

  @override
  String get value => segments.map((final s) => s.text).join();

  @override
  void write(
    final StringBuffer buffer,
    final void Function(StringBuffer, LogStyle?) applyStyle,
  ) {
    for (final seg in segments) {
      if (seg.text.isNotEmpty) {
        applyStyle(buffer, seg.style);
        buffer.write(seg.text);
      }
    }
  }
}

class _TableState {
  _TableState(this.columnWidths);
  final List<int> columnWidths;
  int currentColumn = -1;
  int cellStartWidth = 0;
}

class _DecoratedState {
  _DecoratedState({
    required this.leadingWidth,
    required this.trailingSegments,
    required this.trailingWidth,
    required this.repeatTrailing,
    required this.alignTrailing,
  });

  final int leadingWidth;
  final List<StyledText> trailingSegments;
  final int trailingWidth;
  final bool repeatTrailing;
  final bool alignTrailing;

  bool isFirstLine = true;
}

class _RowFiller {
  _RowFiller(this.char, this.style);
  final String char;
  final LogStyle? style;
}

class _WrappedSegment {
  const _WrappedSegment(this.completedLines, this.activeLine);
  final List<String> completedLines;
  final String activeLine;
}
