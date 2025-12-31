part of '../handler.dart';
//
// /// Sends logs to a network endpoint via HTTP POST.
// class NetworkSink implements LogSink {
//   const NetworkSink({required this.url, this.enabled = true});
//
//   /// The URL to POST logs to.
//   final String url;
//
//   @override
//   final bool enabled;
//
//   @override
//   Future<void> output(final List<String> lines, final LogLevel level) async {
//     try {
//       await http.post(Uri.parse(url), body: lines.join('\n'));
//     } catch (e, s) {
//       InternalLogger.log(
//         LogLevel.error,
//         'NetworkSink error',
//         error: e,
//         stackTrace: s,
//       );
//     }
//   }
// }
