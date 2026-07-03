part of '../native_handler.dart';

/// The entry point for the background isolate worker.
///
/// This worker performs the following tasks:
/// 1. Receives a [NativePacket] from the main isolate.
/// 2. Decodes the Binary IR using [BinaryAnsiEncoder].
/// 3. Serializes the output to bytes.
/// 4. Dispatches the bytes to the underlying [LogSink].
/// 5. Signals completion to recycle the native buffer.
void _spawnNativeWorker(final List<dynamic> args) {
  final sendPort = args[0] as SendPort;
  final target = args[1] as EncodingSink;

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((final message) async {
    if (message is NativePacket) {
      try {
        final String output;
        if (target.encoder is ToonEncoder) {
          const encoder = BinaryToonEncoder();
          output = encoder.encode(message.pointer);
        } else {
          const encoder = BinaryAnsiEncoder();
          output = encoder.encode(
            message.pointer,
            terminalWidth: message.terminalWidth,
          );
        }

        // 2. Encode to UTF-8 bytes
        final data = convert.utf8.encode(output);

        // 3. Dispatch to Sink Delegate
        await target.delegate(data);
      } finally {
        // 4. Signal completion to recycle the buffer
        message.completionPort.send(message.address);
      }
    } else if (message is _IsolateCommand) {
      if (message.type == _CommandType.stop) {
        await target.dispose();
        message.replyPort?.send(null);
        receivePort.close();
      }
    } else if (message is _IsolateLog) {
      final data = message.data.materialize().asUint8List();
      await target.delegate(data);
    }
  });
}
