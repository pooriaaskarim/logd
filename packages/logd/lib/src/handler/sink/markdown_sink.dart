part of '../handler.dart';

/// A [LogSink] that outputs log entries as Markdown.
///
/// It uses [MarkdownEncoder] to transform the semantic [LogDocument] into
/// GFM (GitHub Flavored Markdown) text.
base class MarkdownSink extends EncodingSink<String> {
  /// Creates a [MarkdownSink].
  ///
  /// - [output]: A callback that receives the encoded Markdown string.
  MarkdownSink(final FutureOr<void> Function(String) output)
      : super(
          encoder: const MarkdownEncoder(),
          delegate: (final data) async => await output(data),
        );
}
