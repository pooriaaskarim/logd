// ignore_for_file: comment_references

library;

import 'package:meta/meta.dart';

import 'package:logd/logd.dart' hide HttpServerSink;
import '../sink/http_server_sink.dart';

/// A pre-wired [Handler] that hosts a real-time web dashboard over HTTP/WS.
///
/// Pre-wires [StructuredFormatter], [HtmlEncoder], and an [HttpServerSink]
/// binding to [address] and [port].
@immutable
class HttpDashboardHandler extends Handler {
  /// Creates an [HttpDashboardHandler].
  HttpDashboardHandler({
    final String address = 'localhost',
    final int port = 8080,
    final String? title,
    final int bufferCapacity = 100,
    final int? lineLength,
    final LogFormatter? formatter,
    final List<LogDecorator>? decorators,
    super.filters = const [],
    super.engine = const StandardEngine(),
    super.timeout,
  }) : super(
          formatter: formatter ?? const StructuredFormatter(),
          sink: HttpServerSink(
            address: address,
            port: port,
            encoder: HtmlEncoder(title: title ?? 'logd Real-Time Dashboard'),
            bufferCapacity: bufferCapacity,
            lineLength: lineLength,
          ),
          decorators: decorators ?? const [],
        );
}
