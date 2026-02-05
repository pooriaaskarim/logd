import 'package:logd/src/handler/handler.dart';

const mockContext = LogContext(availableWidth: 80);

List<String> renderLines(final LogDocument structure, {final int width = 80}) {
  final result = <String>[];

  void process(final LogNode block) {
    switch (block) {
      case final ContentNode contentNode:
        final buffer = StringBuffer();
        for (final segment in contentNode.segments) {
          final style = segment.style;
          if (style != null) {
            if (style.bold == true) {
              buffer.write(AnsiStyle.bold.sequence);
            }
            if (style.dim == true) {
              buffer.write(AnsiStyle.dim.sequence);
            }
            if (style.italic == true) {
              buffer.write(AnsiStyle.italic.sequence);
            }
            if (style.inverse == true) {
              buffer.write(AnsiStyle.reverse.sequence);
            }
            if (style.color != null) {
              final ansiCode = AnsiColorCode.fromLogColor(style.color!);
              buffer.write(ansiCode.foreground);
            }

            buffer
              ..write(segment.text)
              ..write(AnsiStyle.reset.sequence);
          } else {
            buffer.write(segment.text);
          }
        }
        final fullText = buffer.toString();
        result.addAll(fullText.split('\n'));

      case final IndentationNode indentNode:
        final indent = indentNode.indentString;
        var renderedIndent = indent;
        if (indentNode.style != null) {
          final buffer = StringBuffer();
          final s = indentNode.style!;
          if (s.bold == true) {
            buffer.write('\x1B[1m');
          }
          if (s.dim == true) {
            buffer.write('\x1B[2m');
          }
          if (s.color != null) {
            buffer.write(AnsiColorCode.fromLogColor(s.color!).foreground);
          }
          buffer
            ..write(indent)
            ..write('\x1B[0m');
          renderedIndent = buffer.toString();
        }
        final childLines = <String>[];
        // Capture child lines
        final originalResult = List<String>.from(result);
        result.clear();
        for (final child in indentNode.children) {
          process(child);
        }
        childLines.addAll(result);
        result
          ..clear()
          ..addAll(originalResult)
          ..addAll(childLines.map((final l) => '$renderedIndent$l'));

      case final BoxNode boxNode:
        final childLines = <String>[];
        final originalResult = List<String>.from(result);
        result.clear();
        for (final child in boxNode.children) {
          process(child);
        }
        childLines.addAll(result);
        result.clear();
        result.addAll(originalResult);

        var top = '╭────────────────────────────────────────────────────────╮';
        var middlePrefix = '│ ';
        var middleSuffix = ' │';
        var bottom =
            '╰────────────────────────────────────────────────────────╯';

        if (boxNode.style != null) {
          final s = boxNode.style!;
          final buffer = StringBuffer();
          if (s.bold == true) {
            buffer.write('\x1B[1m');
          }
          if (s.dim == true) {
            buffer.write('\x1B[2m');
          }
          if (s.color != null) {
            buffer.write(AnsiColorCode.fromLogColor(s.color!).foreground);
          }
          final prefix = buffer.toString();

          top = '$prefix$top\x1B[0m';
          middlePrefix = '$prefix│ \x1B[0m';
          middleSuffix = '$prefix │\x1B[0m';
          bottom = '$prefix$bottom\x1B[0m';
        }

        result.add(top);
        for (final line in childLines) {
          result.add('$middlePrefix$line$middleSuffix');
        }
        result.add(bottom);

      case final DecoratedNode decoratedNode:
        final prefix = decoratedNode.leading?.map((final s) => s.text).join() ??
            (decoratedNode.leadingHint != null
                ? ' ' * decoratedNode.leadingWidth
                : '');
        final suffix =
            decoratedNode.trailing?.map((final s) => s.text).join() ??
                (decoratedNode.trailingHint != null
                    ? ' ' * decoratedNode.trailingWidth
                    : '');

        final childLines = <String>[];
        final originalResult = List<String>.from(result);
        result.clear();
        for (final child in decoratedNode.children) {
          process(child);
        }
        childLines.addAll(result);
        result.clear();
        result.addAll(originalResult);

        for (final line in childLines) {
          var finalLine = '$prefix$line';
          if (decoratedNode.alignTrailing) {
            // Naive visible length calculation for mock (ignores ANSI)
            final plainLine = line.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
            final plainPrefix =
                prefix.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
            final plainSuffix =
                suffix.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
            final padding = (width -
                    plainLine.length -
                    plainPrefix.length -
                    plainSuffix.length)
                .clamp(0, 1000);
            finalLine = '$prefix$line${' ' * padding}$suffix';
          } else {
            finalLine = '$prefix$line$suffix';
          }
          result.add(finalLine);
        }

      case final GroupNode groupNode:
        if (groupNode.title != null) {
          result.add(groupNode.title!);
        }
        for (final child in groupNode.children) {
          process(child);
        }
    }
  }

  for (final block in structure.nodes) {
    process(block);
  }

  return result;
}
