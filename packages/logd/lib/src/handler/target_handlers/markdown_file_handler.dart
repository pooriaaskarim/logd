// ignore_for_file: comment_references

library;

import 'package:meta/meta.dart';

import '../engine/async_handler.dart';
import '../handler.dart';
import '../sink/file_sink.dart';

/// A pre-wired [Handler] that outputs GitHub-Flavored Markdown (GFM) to a file.
///
/// Uses [StructuredFormatter], [MarkdownEncoder], and [FileSink].
///
/// To offload formatting, Markdown encoding, and file I/O to a background
/// isolate, use the [MarkdownFileHandler.async] constructor.
@immutable
class MarkdownFileHandler extends Handler {
  /// Creates a synchronous [MarkdownFileHandler].
  MarkdownFileHandler({
    required final String path,
    final FileRotation? fileRotation,
    final int? lineLength,
    final LogFormatter? formatter,
    final List<LogDecorator>? decorators,
    super.filters = const [],
    super.engine = const StandardEngine(),
    super.timeout,
  }) : super(
          formatter: formatter ?? const StructuredFormatter(),
          sink: FileSink(
            path,
            encoder: const MarkdownEncoder(),
            fileRotation: fileRotation,
            lineLength: lineLength,
          ),
          decorators: decorators ?? const [],
        );

  /// Creates an asynchronous [MarkdownFileHandler] offloaded to a background
  /// isolate.
  static AsyncHandler async({
    required final String path,
    final FileRotation? fileRotation,
    final int? lineLength,
    final LogFormatter? formatter,
    final List<LogDecorator>? decorators,
    final List<LogFilter> filters = const [],
    final LogEngine engine = const StandardEngine(),
    final Duration? timeout,
  }) =>
      AsyncHandler(
        formatter: formatter ?? const StructuredFormatter(),
        sink: FileSink(
          path,
          encoder: const MarkdownEncoder(),
          fileRotation: fileRotation,
          lineLength: lineLength,
        ),
        decorators: decorators ?? const [],
        filters: filters,
        engine: engine,
        timeout: timeout,
      );
}
