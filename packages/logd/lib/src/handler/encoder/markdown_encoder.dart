part of '../handler.dart';

/// An encoder that transforms [LogDocument] into Markdown (GFM) markup.
///
/// It translates the semantic structure of the log into Markdown elements:
/// - [HeaderNode]: Headers (###) + Emojis based on [LogLevel].
/// - [MessageNode]: Bold text (**message**)
/// - [ErrorNode]: Alert blocks (> [!ERROR])
/// - [LogTag.collapsible]: `<details>` blocks for collapsible content.
/// - [LogTag.stackFrame]: Code blocks (```).
@immutable
class MarkdownEncoder implements LogEncoder {
  /// Creates a [MarkdownEncoder].
  const MarkdownEncoder();

  @override
  void preamble(
    final HandlerContext context,
    final LogLevel level,
    final LogPipelineFactory factory, {
    final LogDocument? document,
  }) {}

  @override
  void postamble(
    final HandlerContext context,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) {}

  @override
  void encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level,
    final HandlerContext context,
    final LogPipelineFactory factory, {
    final int? width,
  }) {
    // 1. Header Extraction Pass: Find all text intended for headers.
    final headers = <String>[];
    for (final node in document.nodes) {
      _extractHeaders(node, headers);
    }

    // 2. Render Single Header with Emoji
    if (headers.isNotEmpty) {
      final emoji = _levelEmoji(entry.level);
      final joined = headers.join(' • ');
      context.writeString('### $emoji $joined\n\n');
    }

    // 3. Render Body Pass: Render all nodes, but specialized skipping.
    for (final node in document.nodes) {
      _renderNode(context, node, document, entry, isBodyPass: true);
    }

    // 4. Thematic Separator
    context.writeString('\n---\n\n');
  }

  /// Recursively collects text segments that should belong in the GFM header.
  void _extractHeaders(final LogNode node, final List<String> target) {
    final text = _getHeaderText(node);
    if (text != null && text.isNotEmpty) {
      target.add(text);
    }
  }

  /// Returns semantic text if the node is header-like, otherwise null.
  String? _getHeaderText(final LogNode node) {
    if (node is HeaderNode) {
      final text = _renderContent(node).trim();
      return _isPureFiller(text) ? null : text;
    }

    if (node is DecoratedNode) {
      final parts = <String>[];
      if (node.leading != null) {
        final text = node.leading!.map((final s) => s.text).join().trim();
        if (text.isNotEmpty && !_isPureFiller(text)) {
          parts.add(text);
        }
      }
      for (final child in node.children) {
        final part = _getHeaderText(child);
        if (part != null && part.isNotEmpty) {
          parts.add(part);
        }
      }
      return parts.isEmpty ? null : parts.join(' ');
    }

    if (node is RowNode || node is GroupNode) {
      final parts = <String>[];
      final children = (node as LayoutNode).children;
      for (final child in children) {
        final part = _getHeaderText(child);
        if (part != null && part.isNotEmpty) {
          parts.add(part);
        }
      }
      return parts.isEmpty ? null : parts.join(' ');
    }

    return null;
  }

  bool _isPureFiller(final String text) {
    // Filter out typical terminal-only filler patterns.
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    if (trimmed.split('').every(
          (final char) =>
              char == '_' || char == '-' || char == ' ' || char == '|',
        )) {
      return true;
    }
    return false;
  }

  void _renderNode(
    final HandlerContext context,
    final LogNode node,
    final LogDocument document,
    final LogEntry entry, {
    final bool isBodyPass = false,
  }) {
    if ((node.tags & LogTag.collapsible) != 0) {
      _renderCollapsible(context, node, document, entry);
      return;
    }

    // In body pass, we suppress nodes that were completely moved to the header.
    if (isBodyPass && node is HeaderNode) {
      return;
    }

    if (node is MessageNode) {
      context.writeString('**${_renderContent(node).trim()}**\n');
    } else if (node is ErrorNode) {
      context
        ..writeString('\n> [!ERROR]\n')
        ..writeString('> ${_renderContent(node)}\n');
    } else if (node is FooterNode) {
      _renderFooter(context, node);
    } else if (node is IndentationNode) {
      context.writeString('> ');
      for (final child in node.children) {
        _renderNode(context, child, document, entry, isBodyPass: isBodyPass);
      }
    } else if (node is DecoratedNode) {
      // If the leading decoration was likely consumed by the header, we skip it
      // in the body to avoid duplication.
      final leadingText = (node.leading != null)
          ? node.leading!.map((final s) => s.text).join().trim()
          : '';

      final skipLeading = isBodyPass &&
          leadingText.isNotEmpty &&
          (_getHeaderText(node) != null || _isPureFiller(leadingText));

      if (!skipLeading && node.leading != null) {
        context
            .writeString('${node.leading!.map((final s) => s.text).join()} ');
      }

      for (final child in node.children) {
        _renderNode(context, child, document, entry, isBodyPass: isBodyPass);
      }

      if (node.trailing != null) {
        context
            .writeString(' ${node.trailing!.map((final s) => s.text).join()}');
      }
    } else if (node is BoxNode) {
      context.writeString('\n> [!NOTE]\n');
      for (final child in node.children) {
        context.writeString('> ');
        _renderNode(context, child, document, entry, isBodyPass: isBodyPass);
      }
      context.writeString('\n');
    } else if (node is MapNode) {
      final toonColumns = document.metadata['toon_columns'] as List<String>?;
      if (toonColumns != null) {
        final arrayName = document.metadata['toon_array'] as String? ?? 'logs';
        final delimiter =
            document.metadata['toon_delimiter'] as String? ?? '\t';
        final columnStr = toonColumns.join(',');
        final row = toonColumns
            .map((final col) => node.map[col]?.toString() ?? '')
            .join(delimiter);

        context
          ..writeString('\n```text\n')
          ..writeString('$arrayName[]{$columnStr}:\n')
          ..writeString('$row\n')
          ..writeString('```\n');
      } else {
        context.writeString('\n```json\n$node\n```\n');
      }
    } else if (node is GroupNode) {
      for (final child in node.children) {
        _renderNode(context, child, document, entry);
      }
    } else if (node is ParagraphNode) {
      for (final child in node.children) {
        _renderNode(context, child, document, entry);
      }
      context.writeString('\n');
    } else if (node is RowNode) {
      for (final child in node.children) {
        _renderNode(context, child, document, entry);
      }
    } else if (node is FillerNode) {
      // Typically ignored in MD except within headers (which we skip here).
    }
  }

  void _renderCollapsible(
    final HandlerContext context,
    final LogNode node,
    final LogDocument document,
    final LogEntry entry,
  ) {
    final summary =
        (node.tags & LogTag.stackFrame) != 0 ? 'Stack Trace' : 'Details';
    context
      ..writeString('\n<details>\n')
      ..writeString('<summary>$summary</summary>\n\n');

    if (node is ContentNode) {
      if ((node.tags & LogTag.stackFrame) != 0) {
        context
          ..writeString('```\n')
          ..writeString('${_renderContent(node)}\n')
          ..writeString('```\n');
      } else {
        context.writeString('${_renderContent(node)}\n');
      }
    } else if (node is LayoutNode) {
      for (final child in node.children) {
        _renderNode(context, child, document, entry);
      }
    }

    context.writeString('\n</details>\n');
  }

  void _renderFooter(final HandlerContext context, final FooterNode node) {
    if ((node.tags & LogTag.stackFrame) != 0) {
      context
        ..writeString('\n```\n')
        ..writeString('${_renderContent(node)}\n')
        ..writeString('```\n');
    } else {
      context.writeString('${_renderContent(node)}\n');
    }
  }

  String _renderContent(final ContentNode node) =>
      node.segments.map((final s) => s.text).join();

  String _levelEmoji(final LogLevel level) => switch (level) {
        LogLevel.trace => '🧬',
        LogLevel.debug => '🔍',
        LogLevel.info => 'ℹ️',
        LogLevel.warning => '⚠️',
        LogLevel.error => '❌',
      };
}
