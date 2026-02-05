part of '../handler.dart';

/// An internal engine for calculating physical terminal geometry.
///
/// [TerminalLayout] flattens the logical [LogDocument] tree into a sequence
/// of physical lines based on a target width. It handles structural elements
/// like boxes, indentation, and decorations, as well as content elements
/// like word-wrapped text.
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
    }
  }

  List<PhysicalLine> _renderContent(
    final ContentNode node,
    final int availableWidth,
  ) {
    final lines = <PhysicalLine>[];
    var currentLine = <StyledText>[];
    var currentLength = 0;

    for (final segment in node.segments) {
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

          if (currentLength + wordLen > availableWidth && currentLength > 0) {
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

    return lines;
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
        _renderBorderLine(border, BoxBorderPosition.top, availableWidth),
      );
    }

    // Title (if any)
    if (node.title != null) {
      final titleBar = border.getChar(BoxBorderPosition.vertical);
      final titleLen = _getVisibleLength(node.title!);
      final padding = availableWidth - titleLen - 4;
      final padLeft = padding ~/ 2;
      final padRight = padding - padLeft;

      lines.add(
        PhysicalLine(
          segments: [
            StyledText(titleBar, tags: const {LogTag.border}),
            StyledText(
              '  ${' ' * padLeft}${node.title}${' ' * padRight}  ',
              tags: const {LogTag.header},
            ),
            StyledText(titleBar, tags: const {LogTag.border}),
          ],
        ),
      );

      if (border != BoxBorderStyle.none) {
        lines.add(
          _renderBorderLine(
            border,
            BoxBorderPosition.middle,
            availableWidth,
          ),
        );
      }
    }

    // Content
    final contentWidth = (availableWidth - 4).clamp(0, 1000000);
    for (final child in node.children) {
      final childLines = _renderNode(child, level, contentWidth);
      for (final line in childLines) {
        final sideChar = border.getChar(BoxBorderPosition.vertical);
        final paddingNeeded = contentWidth - line.visibleLength;
        final padding = ' ' * (paddingNeeded > 0 ? paddingNeeded : 0);

        lines.add(
          PhysicalLine(
            segments: [
              StyledText(sideChar, tags: const {LogTag.border}),
              const StyledText(' ', tags: {}),
              ...line.segments,
              StyledText('$padding ', tags: const {}),
              StyledText(sideChar, tags: const {LogTag.border}),
            ],
          ),
        );
      }
    }

    // Bottom Border
    if (border != BoxBorderStyle.none) {
      lines.add(
        _renderBorderLine(border, BoxBorderPosition.bottom, availableWidth),
      );
    }

    return lines;
  }

  PhysicalLine _renderBorderLine(
    final BoxBorderStyle border,
    final BoxBorderPosition pos,
    final int width,
  ) {
    final left = border.getCorner(pos, BoxBorderCorner.left);
    final right = border.getCorner(pos, BoxBorderCorner.right);
    final horizontal = border.getChar(BoxBorderPosition.horizontal);

    return PhysicalLine(
      segments: [
        StyledText(
          '$left${horizontal * (width - 2)}$right',
          tags: const {LogTag.border},
        ),
      ],
    );
  }

  List<PhysicalLine> _renderIndentation(
    final IndentationNode node,
    final LogLevel level,
    final int availableWidth,
  ) {
    final indentWidth = node.indentString.length;
    final lines = <PhysicalLine>[];

    for (final child in node.children) {
      final childLines = _renderNode(
          child, level, (availableWidth - indentWidth).clamp(0, 1000000));
      for (final line in childLines) {
        lines.add(
          PhysicalLine(
            segments: [
              StyledText(node.indentString, tags: const {LogTag.hierarchy}),
              ...line.segments,
            ],
          ),
        );
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

    for (final child in node.children) {
      final childLines = _renderNode(child, level, contentWidth);
      for (final line in childLines) {
        final leadingSegments = node.leading ??
            [
              StyledText(
                _getDecorationString(node.leadingHint, node.leadingWidth),
                style: node.style,
                tags: const {LogTag.hierarchy},
              ),
            ];

        final trailingSegments = node.trailing ??
            [
              StyledText(
                _getDecorationString(node.trailingHint, node.trailingWidth),
                style: node.style,
                tags: const {LogTag.hierarchy},
              ),
            ];

        final paddingNeeded = contentWidth - line.visibleLength;
        final padChar = node.leadingHint == 'structured_separator' ? '_' : ' ';
        final padding = (node.alignTrailing && paddingNeeded > 0)
            ? (padChar * paddingNeeded)
            : '';

        lines.add(
          PhysicalLine(
            segments: [
              ...leadingSegments,
              ...line.segments,
              if (padding.isNotEmpty) StyledText(padding, tags: const {}),
              ...trailingSegments,
            ],
          ),
        );
      }
    }
    return lines;
  }

  String _getDecorationString(final String? hint, final int width) {
    if (width <= 0) {
      return '';
    }
    if (hint == 'structured_separator') {
      return '_' * width;
    }
    if (hint == 'hierarchy_trace') {
      return '│${' ' * (width - 1)}';
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
