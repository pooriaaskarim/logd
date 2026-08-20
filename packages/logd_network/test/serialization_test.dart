import 'package:logd/logd.dart'
    hide HttpSink, SocketSink, HttpServerSink, HttpDashboardHandler, DropPolicy;
import 'package:logd_network/logd_network.dart';
import 'package:test/test.dart';

void main() {
  group('Logd Network Serialization Tests', () {
    setUp(() {
      Logger.reset();
      registerLogdNetworkSerializers();
    });

    test('HttpSink round-trip serialization and deserialization', () {
      final original = HttpSink(
        url: 'https://logs.example.com/api/v1',
        headers: const {'Authorization': 'Bearer token-123'},
        batchSize: 25,
        flushInterval: const Duration(seconds: 45),
        maxRetries: 7,
        maxBufferSize: 500,
        dropPolicy: DropPolicy.discardNewest,
      );

      final json = LoggerSerializationRegistry.serializeSink(original);
      expect(json['type'], equals('HttpSink'));

      final restored =
          LoggerSerializationRegistry.deserializeSink(json) as HttpSink;
      expect(restored.url, equals('https://logs.example.com/api/v1'));
      expect(restored.headers, equals({'Authorization': 'Bearer token-123'}));
      expect(restored.batchSize, equals(25));
      expect(restored.flushInterval, equals(const Duration(seconds: 45)));
      expect(restored.maxRetries, equals(7));
      expect(restored.maxBufferSize, equals(500));
      expect(restored.dropPolicy, equals(DropPolicy.discardNewest));
    });

    test('SocketSink round-trip serialization and deserialization', () {
      final original = SocketSink(
        url: 'wss://stream.example.com/logs',
        headers: const {'X-Custom-Protocol': 'v1'},
        reconnectInterval: const Duration(seconds: 10),
        maxBufferSize: 800,
        dropPolicy: DropPolicy.discardOldest,
      );

      final json = LoggerSerializationRegistry.serializeSink(original);
      expect(json['type'], equals('SocketSink'));

      final restored =
          LoggerSerializationRegistry.deserializeSink(json) as SocketSink;
      expect(restored.url, equals('wss://stream.example.com/logs'));
      expect(restored.headers, equals({'X-Custom-Protocol': 'v1'}));
      expect(restored.reconnectInterval, equals(const Duration(seconds: 10)));
      expect(restored.maxBufferSize, equals(800));
      expect(restored.dropPolicy, equals(DropPolicy.discardOldest));
    });
  });
}
