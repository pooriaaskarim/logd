part of '../handler.dart';

/// An internal engine for calculating physical terminal geometry.
///
/// [TerminalLayout] flattens the logical [LogDocument] tree into a sequence
/// of physical lines based on a target width. It handles structural elements
/// like boxes, indentation, and decorations, as well as content elements
/// like word-wrapped text using adaptive, width-agnostic logic.
@internal
class TerminalLayout {
  /// Creates a [TerminalLayout].
  const TerminalLayout({
    required this.width,
  });

  /// The target physical width in characters.
  final int width;

  /// Lays out a [LogDocument] into a [PhysicalDocument].
  PhysicalDocument layout(final LogDocument document, final LogLevel level) {
    if (document.nodes.isEmpty) {
      return const PhysicalDocument(lines: []);
    }

    final physicalLines = <PhysicalLine>[];
    for (final node in document.nodes) {
      physicalLines.addAll(_renderNode(node, level, width));
    }

    return PhysicalDocument(lines: physicalLines);
  }

  List<PhysicalLine> _renderNode(
    final LogNode node,
    final LogLevel level,
    final int availableWidth,
  ) {
    switch (node) {
      case final ContentNode n:
        return _renderContent(n, availableWidth);
      case final BoxNode n:
        return _renderBox(n, level, availableWidth);
      case final IndentationNode n:
        return _renderIndentation(n, level, availableWidth);
      case final DecoratedNode n:
        return _renderDecorated(n, level, availableWidth);
      case final GroupNode n:
        return n.children
            .expand((final c) => _renderNode(c, level, availableWidth))
            .toList();
      case final ParagraphNode n:
        return _renderParagraph(n, level, availableWidth);
      case final FillerNode n:
        return _renderFiller(n, availableWidth);
      case final RowNode n:
        return _renderRow(n, level, availableWidth);
      case final MapNode n:
        return _renderContent(
          HeaderNode(segments: [StyledText(n.toString())]),
          availableWidth,
        );
      case final ListNode n:
        return _renderContent(
          HeaderNode(segments: [StyledText(n.toString())]),
          availableWidth,
        );
    }
  }

  List<PhysicalLine> _renderRow(
    final RowNode node,
    final LogLevel level,
    final int availableWidth,
  ) {
    if (availableWidth <= 0) {
      return [];
    }

    // For a row, we want everything on one line if possible.
    // If it exceeds width, we fall back to paragraph-style wrapping
    //(Adaptive Stacking).
    final segments = <StyledText>[];
    String? fillerChar;
    int fillerTags = LogTag.none;
    LogStyle? fillerStyle;

    for (final child in node.children) {
      if (child is ContentNode) {
        segments.addAll(child.segments);
      } else if (child is FillerNode) {
        fillerChar = child.char;
        fillerTags = child.tags;
        fillerStyle = child.style;
      }
    }

    // Render as flow first
    final draftLines =
        _renderContent(HeaderNode(segments: segments), availableWidth);

    if (fillerChar != null) {
      // Add filler to each line to ensure it reaches full width
      return draftLines.map((final line) {
        final currentLen = line.visibleLength;
        final fillerLen =
            (availableWidth - currentLen).clamp(0, availableWidth);
        if (fillerLen > 0) {
          return PhysicalLine(
            segments: [
              ...line.segments,
              StyledText(
                fillerChar! * fillerLen,
                tags: fillerTags,
                style: fillerStyle,
              ),
            ],
          );
        }
        return line;
      }).toList();
    }

    return draftLines;
  }

  List<PhysicalLine> _renderParagraph(
    final ParagraphNode node,
    final LogLevel level,
    final int availableWidth,
  ) {
    // For now, treat ParagraphNode children as a single flow.
    // We flatten all content children into one virtual ContentNode and render
    // it.
    final allSegments = <StyledText>[];
    for (final child in node.children) {
      if (child is ContentNode) {
        allSegments.addAll(child.segments);
      } else {
        // Nested layout nodes in paragraphs are not yet supported for inline
        // flow. We render them as separate lines.
      }
    }

    return _renderContent(HeaderNode(segments: allSegments), availableWidth);
  }

  List<PhysicalLine> _renderFiller(
    final FillerNode node,
    final int availableWidth,
  ) {
    if (availableWidth <= 0) {
      return [];
    }
    return [
      PhysicalLine(
        segments: [
          StyledText(
            node.char * availableWidth,
            tags: node.tags,
            style: node.style,
          ),
        ],
      ),
    ];
  }

  List<PhysicalLine> _renderContent(
    final ContentNode node,
    final int availableWidth,
  ) {
    final lines = <PhysicalLine>[];
    var currentLine = <StyledText>[];
    var currentLength = 0;

    for (final segment in node.segments) {
      // If segment is tagged noWrap, we bypass width constraints.
      if ((segment.tags & LogTag.noWrap) != 0) {
        // Just append the whole text. If there are newlines, respect them.
        final physicalLines = segment.text.split('\n');
        for (var l = 0; l < physicalLines.length; l++) {
          if (l > 0) {
            lines.add(PhysicalLine(segments: currentLine));
            currentLine = [];
            currentLength = 0;
          }
          final lineText = physicalLines[l];
          if (lineText.isEmpty) {
            continue;
          }

          currentLine.add(
            StyledText(lineText, style: segment.style, tags: segment.tags),
          );
          currentLength += _getVisibleLength(lineText, currentLength);
        }
        continue;
      }

      final physicalLines = segment.text.split('\n');

      for (var l = 0; l < physicalLines.length; l++) {
        if (l > 0) {
          // Explicit newline in segment
          lines.add(PhysicalLine(segments: currentLine));
          currentLine = [];
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
          final wordLen = _getVisibleLength(word, currentLength);
          if (wordLen > availableWidth) {
            // Finish current line if not empty
            if (currentLine.isNotEmpty) {
              lines.add(PhysicalLine(segments: currentLine));
              currentLine = [];
              currentLength = 0;
            }

            // Break the word into chunks
            var remaining = word;
            while (remaining.isNotEmpty &&
                _getVisibleLength(remaining) > availableWidth) {
              // Find how many characters fit
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
              lines.add(
                PhysicalLine(
                  segments: [
                    StyledText(chunk, style: segment.style, tags: segment.tags),
                  ],
                ),
              );
              remaining = remaining.substring(takeCount);
            }
            if (remaining.isNotEmpty) {
              currentLine.add(
                StyledText(
                  remaining,
                  style: segment.style,
                  tags: segment.tags,
                ),
              );
              currentLength = _getVisibleLength(remaining);
            }
            continue;
          }

          final wordLenTrimmed = _getVisibleLength(
            word.replaceFirst(RegExp(r' +$'), ''),
            currentLength,
          );
          if (currentLength + wordLenTrimmed > availableWidth &&
              currentLength > 0) {
            lines.add(PhysicalLine(segments: currentLine));
            currentLine = [];
            currentLength = 0;
          }

          currentLine
              .add(StyledText(word, style: segment.style, tags: segment.tags));
          currentLength += _getVisibleLength(word, currentLength);
        }
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(PhysicalLine(segments: currentLine));
    }

    // Post-process to trim trailing spaces from each physical line
    // to match legacy wrapVisible behavior.
    return lines.map((final line) {
      if (line.segments.isEmpty) {
        return line;
      }
      final last = line.segments.last;
      final trimmedText = last.text.replaceFirst(RegExp(r' +$'), '');
      if (trimmedText == last.text) {
        return line;
      }

      final newSegments = List<StyledText>.from(line.segments);
      newSegments[newSegments.length - 1] =
          StyledText(trimmedText, style: last.style, tags: last.tags);
      return PhysicalLine(segments: newSegments);
    }).toList();
  }

  List<PhysicalLine> _renderBox(
    final BoxNode node,
    final LogLevel level,
    final int availableWidth,
  ) {
    final border = node.border;
    final lines = <PhysicalLine>[];

    // Top Border
    if (border != BoxBorderStyle.none) {
      lines.add(
        _renderBorderLine(
          border,
          BoxBorderPosition.top,
          availableWidth,
          node.style,
        ),
      );
    }

    // Title (if any)
    if (node.title != null) {
      final titleBar = border.getChar(BoxBorderPosition.vertical);
      final titleLen = _getVisibleLength(node.title!.text);
      final padding = availableWidth - titleLen - 4;
      final padLeft = padding ~/ 2;
      final padRight = padding - padLeft;

      lines.add(
        PhysicalLine(
          segments: [
            StyledText(
              titleBar,
              style: node.style,
              tags: LogTag.border,
            ),
            StyledText(
              '  ${' ' * padLeft}${node.title!.text}${' ' * padRight}  ',
              tags: LogTag.header,
            ),
            StyledText(
              titleBar,
              style: node.style,
              tags: LogTag.border,
            ),
          ],
        ),
      );

      if (border != BoxBorderStyle.none) {
        lines.add(
          _renderBorderLine(
            border,
            BoxBorderPosition.middle,
            availableWidth,
            node.style,
          ),
        );
      }
    }

    // Content
    final contentWidth = (availableWidth - 4).clamp(0, 1000000);
    for (final child in node.children) {
      final rawLines = _renderNode(child, level, contentWidth);
      for (final rawLine in rawLines) {
        // Truncate assuming line starts at index 2 (border + space)
        final line = rawLine.truncate(contentWidth, startX: 2);
        final sideChar = border.getChar(BoxBorderPosition.vertical);

        // Calculate visible length assuming line starts at index 2
        // (border + space)
        // This is crucial for correct TAB expansion inside boxes.
        final visibleLen = line.getVisibleLength(startX: 2);

        final paddingNeeded = contentWidth - visibleLen;
        final padding = ' ' * (paddingNeeded > 0 ? paddingNeeded : 0);

        lines.add(
          PhysicalLine(
            segments: [
              StyledText(
                sideChar,
                style: node.style,
                tags: LogTag.border,
              ),
              StyledText(' ', style: node.style, tags: LogTag.none),
              ...line.segments,
              StyledText('$padding ', style: node.style, tags: LogTag.none),
              StyledText(
                sideChar,
                style: node.style,
                tags: LogTag.border,
              ),
            ],
          ),
        );
      }
    }

    // Bottom Border
    if (border != BoxBorderStyle.none) {
      lines.add(
        _renderBorderLine(
          border,
          BoxBorderPosition.bottom,
          availableWidth,
          node.style,
        ),
      );
    }

    return lines;
  }

  PhysicalLine _renderBorderLine(
    final BoxBorderStyle border,
    final BoxBorderPosition pos,
    final int width,
    final LogStyle? style,
  ) {
    final left = border.getCorner(pos, BoxBorderCorner.left);
    final right = border.getCorner(pos, BoxBorderCorner.right);
    final horizontal = border.getChar(BoxBorderPosition.horizontal);

    return PhysicalLine(
      segments: [
        StyledText(
          '$left${horizontal * (width - 2)}$right',
          style: style,
          tags: LogTag.border,
        ),
      ],
    );
  }

  List<PhysicalLine> _renderIndentation(
    final IndentationNode node,
    final LogLevel level,
    final int availableWidth,
  ) {
    final indentWidth = _getVisibleLength(node.indentString);
    final lines = <PhysicalLine>[];

    for (final child in node.children) {
      final childContentWidth =
          (availableWidth - indentWidth).clamp(0, 1000000);
      final rawLines = _renderNode(child, level, childContentWidth);
      for (final rawLine in rawLines) {
        if (childContentWidth <= 0) {
          // Narrow space recovery: Drop indent if it would push content
          // off-screen
          lines.add(rawLine);
        } else {
          final line = rawLine.truncate(childContentWidth);
          lines.add(
            PhysicalLine(
              segments: [
                StyledText(
                  node.indentString,
                  style: node.style,
                  tags: LogTag.hierarchy,
                ),
                ...line.segments,
              ],
            ),
          );
        }
      }
    }
    return lines;
  }

  List<PhysicalLine> _renderDecorated(
    final DecoratedNode node,
    final LogLevel level,
    final int availableWidth,
  ) {
    final lines = <PhysicalLine>[];
    final contentWidth =
        (availableWidth - node.leadingWidth - node.trailingWidth)
            .clamp(0, 1000000);

    // Fallback: If decoration consumes too much space, switch to vertical
    // stack. This is crucial for PlainFormatter's hanging indents in
    // narrow/deep layouts. We only do this if repeatLeading is false
    // (typical for headers), because repeating prefixes meant for every line
    // generally shouldn't be stack-broken.
    // We use a threshold of 12 to ensure content has enough space to
    // be readable.
    if (contentWidth < 12 && !node.repeatLeading && node.leading != null) {
      // 1. Render Leading (Header) with full width
      final lines = <PhysicalLine>[
        ..._renderContent(HeaderNode(segments: node.leading!), availableWidth),
      ];
      // 2. Render Children (Message) with full width
      final childLines = node.children
          .expand((final c) => _renderNode(c, level, availableWidth))
          .toList();
      lines.addAll(childLines);
      return lines;
    }

    final childLines = node.children
        .expand((final c) => _renderNode(c, level, contentWidth))
        .map((final l) => l.truncate(contentWidth, startX: node.leadingWidth))
        .toList();

    if (childLines.isEmpty) {
      childLines.add(const PhysicalLine(segments: []));
    }

    for (var i = 0; i < childLines.length; i++) {
      final line = childLines[i];
      final isFirst = i == 0;

      final leadingSegments =
          (node.leading != null && (isFirst || node.repeatLeading))
              ? node.leading!
              : (node.leadingWidth > 0
                  ? [
                      StyledText(
                        _getDecorationString(
                          node.leadingHint,
                          node.leadingWidth,
                          isContinuation: !isFirst,
                        ),
                        style: node.style,
                        tags: LogTag.hierarchy,
                      ),
                    ]
                  : const <StyledText>[]);

      final trailingSegments =
          (node.trailing != null && (isFirst || node.repeatTrailing))
              ? node.trailing!
              : (node.trailingWidth > 0
                  ? [
                      StyledText(
                        _getDecorationString(
                          node.trailingHint,
                          node.trailingWidth,
                          isContinuation: !isFirst,
                        ),
                        style: node.style,
                        tags: LogTag.hierarchy,
                      ),
                    ]
                  : const <StyledText>[]);

      final paddingNeeded =
          contentWidth - line.getVisibleLength(startX: node.leadingWidth);
      final padChar =
          node.leadingHint == DecorationHint.structuredSeparator ? '_' : ' ';
      final padding = (node.alignTrailing && paddingNeeded > 0)
          ? (padChar * paddingNeeded)
          : '';

      final pLine = PhysicalLine(
        segments: [
          ...leadingSegments,
          ...line.segments,
          if (padding.isNotEmpty) StyledText(padding, tags: LogTag.none),
          ...trailingSegments,
        ],
      );
      lines.add(pLine);
    }

    return lines;
  }

  String _getDecorationString(
    final String? hint,
    final int width, {
    final bool isContinuation = false,
  }) {
    if (width <= 0) {
      return '';
    }
    if (hint == DecorationHint.structuredSeparator) {
      return '_' * width;
    }
    if (hint == DecorationHint.structuredHeader) {
      return '_' * width;
    }
    if (hint == DecorationHint.structuredMessage && isContinuation) {
      return ' ' * width;
    }
    if (hint == DecorationHint.hierarchyTrace) {
      return isContinuation ? '│${' ' * (width - 1)}' : '│${' ' * (width - 1)}';
    }
    return ' ' * width;
  }

  int _getVisibleLength(final String text, [final int startX = 0]) {
    var x = startX;
    for (final char in text.characters) {
      if (char == '\t') {
        x += 8 - (x % 8);
      } else {
        x += isWide(char) ? 2 : 1;
      }
    }
    return x - startX;
  }
}
