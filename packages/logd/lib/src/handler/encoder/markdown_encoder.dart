part of '../handler.dart';

/// An encoder that transforms [LogDocument] into Markdown (GFM) markup.
///
/// It translates the semantic structure of the log into Markdown elements:
/// - [HeaderNode]: Headers (###)
/// - [MessageNode]: Bold text (**message**)
/// - [LogTag.collapsible]: `<details>` blocks for collapsible content.
/// - [LogTag.stackFrame]: Code blocks (```).
@immutable
class MarkdownEncoder implements LogEncoder {
  /// Creates a [MarkdownEncoder].
  const MarkdownEncoder();

  @override
  void preamble(
    final HandlerContext context,
    final LogLevel level, {
    final LogDocument? document,
  }) {}

  @override
  void postamble(final HandlerContext context, final LogLevel level) {}

  @override
  void encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level,
    final HandlerContext context, {
    final int? width,
  }) {
    for (final node in document.nodes) {
      _renderNode(context, node);
    }
  }

  void _renderNode(final HandlerContext context, final LogNode node) {
    if ((node.tags & LogTag.collapsible) != 0) {
      _renderCollapsible(context, node);
      return;
    }

    if (node is HeaderNode) {
      context.writeString('### ${_renderContent(node)}\n');
    } else if (node is MessageNode) {
      context.writeString('\n**${_renderContent(node)}**\n');
    } else if (node is ErrorNode) {
      context
        ..writeString('\n> [!ERROR]\n')
        ..writeString('> ${_renderContent(node)}\n');
    } else if (node is FooterNode) {
      _renderFooter(context, node);
    } else if (node is IndentationNode) {
      for (final child in node.children) {
        _renderNode(context, child);
      }
    } else if (node is DecoratedNode) {
      for (final child in node.children) {
        _renderNode(context, child);
      }
    } else if (node is GroupNode) {
      for (final child in node.children) {
        _renderNode(context, child);
      }
    } else if (node is ParagraphNode) {
      for (final child in node.children) {
        _renderNode(context, child);
      }
    }
  }

  void _renderCollapsible(final HandlerContext context, final LogNode node) {
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
        _renderNode(context, child);
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
}
