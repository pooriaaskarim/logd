part of '../handler.dart';

/// A wrapper sink that provides the HTML document structure (`<html>`,
/// `<head>`, `<body>`)
/// around the logs written by an [HtmlEncoder].
///
/// This sink wraps another [LogSink] (which handles the actual I/O, like [FileSink] or [NetworkSink])
/// and ensures the output is a valid, standalone HTML document.
base class HtmlLayoutSink extends LogSink {
  /// Creates an [HtmlLayoutSink].
  ///
  /// - [sink]: The inner sink to write to (e.g. a FileSink).
  /// - [encoder]: The encoder to use (must be consistent logic, specifically
  /// for CSS).
  HtmlLayoutSink(
    this.sink, {
    this.encoder = const HtmlEncoder(),
  });

  /// The inner sink that performs the actual I/O.
  final LogSink sink;

  /// The encoder (used primarily to retrieve CSS styles for the header).
  final HtmlEncoder encoder;

  bool _headerWritten = false;
  bool _closed = false;

  @override
  int get preferredWidth => sink.preferredWidth;

  @override
  Future<void> output(
    final LogDocument document,
    final LogLevel level,
  ) async {
    if (_closed) {
      InternalLogger.log(
        LogLevel.warning,
        'HtmlLayoutSink is closed, cannot write logs',
      );
      return;
    }

    if (!_headerWritten) {
      // Write Header
      await sink.output(
        LogDocument(
          nodes: [
            MessageNode(segments: [StyledText(_htmlHeader())]),
          ],
        ),
        level,
      );
      _headerWritten = true;
    }

    // We assume the incoming lines are already encoded HTML fragments
    // (produced by an HtmlEncoder wrapped in an EncodingSink, OR
    // we can encode them here if we want this sink to do the encoding too?)
    //
    // Design Choice: If this is a Layout Sink, it likely expects the inner sink
    // to just accept text.
    // But `sink.output` takes generic `LogLine`s.
    //
    // If the USER uses `EncodingSink(HtmlEncoder)` ->
    // `HtmlLayoutSink(FileSink)`...
    // The `EncodingSink` would turn Lines -> String.
    // But `HtmlLayoutSink` is a `LogSink`. `output` takes `LogLine`.
    //
    // Correct usage:
    // `Layout(EncodingSink(FileSink))`? No.
    // `EncodingSink` output is `Future<void>`. It's not a `LogSink` wrapper in
    // that sense.
    //
    // Let's make `HtmlLayoutSink` do the ENCODING itself just like
    // `EncodingSink`,
    // OR wrap the `EncodingSink` logic.
    //
    // Proposed Architecture from Docs:
    // `FileSink(encoder: HtmlEncoder())`
    //
    // But `FileSink` doesn't know about `<html>` tags!
    //
    // So `HtmlLayoutSink` is effectively:
    // `GenericSink(encoder: HtmlEncoder, output: (s) => file.write)` + Header/Footer management.
    //
    // But we want to reuse `FileSink`'s rotation logic.
    //
    // So `HtmlLayoutSink` should wrap a `LogSink` (like `FileSink`).
    // And it should FEED it String-content LogLines.
    //
    // So `HtmlLayoutSink` acts as the Encoder Driver.
    // It takes raw `LogLines` -> Encodes them -> Sends to inner Sink.

    final encoded = encoder.encode(document, level);
    await sink.output(
      LogDocument(
        nodes: [
          MessageNode(segments: [StyledText(encoded)]),
        ],
      ),
      level,
    );
  }

  /// Closes the sink, writing the HTML footer.
  ///
  /// This must be called to ensure valid HTML.
  Future<void> close() async {
    if (_closed) {
      return;
    }

    if (_headerWritten) {
      await sink.output(
        LogDocument(
          nodes: [
            MessageNode(segments: [StyledText(_htmlFooter())]),
          ],
        ),
        LogLevel.info,
      );
    }
    _closed = true;
    // We do not close the inner sink automatically as it might be shared?
    // Or we should? Usually wrappers close inner.
    // FileSink has close(). LogSink doesn't enforce close() in interface
    // but implies it via specific implementations.
    // We'll leave inner sink management to user or add a flag `closeInner`.
  }

  String _htmlHeader() => '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Log Output</title>
  <style>
${encoder.css}
  </style>
</head>
<body>
<div class="log-container">
''';

  String _htmlFooter() => '''
</div>
</body>
</html>
''';
}
