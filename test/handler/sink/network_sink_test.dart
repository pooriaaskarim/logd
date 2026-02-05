import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logd/logd.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

void main() {
  const httpUrl = 'https://example.com/logs';
  const wsUrl = 'ws://example.com/logs';

  group('HttpSink', () {
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      registerFallbackValue(Uri.parse(httpUrl));
    });

    test('buffers logs until batchSize reached', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((final _) async => http.Response('OK', 200));

      final sink = HttpSink(
        url: httpUrl,
        batchSize: 3,
        client: mockClient,
      );

      await sink.output([LogLine.text('log1')], LogLevel.info);
      await sink.output([LogLine.text('log2')], LogLevel.info);
      verifyNever(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      );

      await sink.output([LogLine.text('log3')], LogLevel.info);
      await Future.delayed(Duration.zero);

      verify(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: jsonEncode(['log1', 'log2', 'log3']),
        ),
      ).called(1);
    });

    test('flushes logs on timer interval', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((final _) async => http.Response('OK', 200));

      final sink = HttpSink(
        url: httpUrl,
        flushInterval: const Duration(milliseconds: 50),
        client: mockClient,
      );

      await sink.output([LogLine.text('queued')], LogLevel.info);
      await Future.delayed(const Duration(milliseconds: 100));

      verify(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: contains('queued'),
        ),
      ).called(1);

      await sink.dispose();
    });

    test('retries on failure with exponential backoff', () async {
      var attempts = 0;
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((final _) async {
        attempts++;
        if (attempts < 2) {
          return http.Response('Error', 500);
        }
        return http.Response('OK', 200);
      });

      final sink = HttpSink(
        url: httpUrl,
        batchSize: 1,
        maxRetries: 3,
        client: mockClient,
      );

      await sink.output([LogLine.text('retry-me')], LogLevel.info);
      await Future.delayed(const Duration(milliseconds: 600));

      expect(attempts, equals(2));
      await sink.dispose();
    });
  });

  group('SocketSink', () {
    late MockWebSocketChannel mockChannel;
    late MockWebSocketSink mockSink;

    setUp(() {
      mockChannel = MockWebSocketChannel();
      mockSink = MockWebSocketSink();
      when(() => mockChannel.sink).thenReturn(mockSink);
      when(() => mockChannel.ready).thenAnswer((final _) async => {});
      when(() => mockSink.close()).thenAnswer((final _) async => {});
    });

    test('sends logs immediately when connected', () async {
      final sink = SocketSink(
        url: wsUrl,
        channel: mockChannel,
      );

      await sink.output([LogLine.text('instant')], LogLevel.info);
      await Future.delayed(Duration.zero);

      verify(() => mockSink.add('instant')).called(1);
    });

    test('buffers logs during downtime and drains on reconnect', () async {
      final readyCompleter = Completer<void>();
      when(() => mockChannel.ready)
          .thenAnswer((final _) => readyCompleter.future);

      final sink = SocketSink(
        url: wsUrl,
        channel: mockChannel,
      );

      // don't await because it will block on readyCompleter
      final f = sink.output([LogLine.text('buffered')], LogLevel.info);

      await Future.delayed(Duration.zero);
      verifyNever(() => mockSink.add(any()));

      readyCompleter.complete();
      await f; // finish the output call

      verify(() => mockSink.add('buffered')).called(1);
    });
  });

  group('NetworkSink Edge Cases', () {
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    test('respects DropPolicy.discardNewest when buffer is full', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((final _) async => http.Response('OK', 200));

      final sink = HttpSink(
        url: 'https://example.com/logs',
        maxBufferSize: 2,
        batchSize: 10, // Don't auto-flush
        dropPolicy: DropPolicy.discardNewest,
        client: mockClient,
      );

      await sink.output([LogLine.text('first')], LogLevel.info);
      await sink.output([LogLine.text('second')], LogLevel.info);
      await sink
          .output([LogLine.text('third')], LogLevel.info); // Should be dropped

      await sink.dispose();

      // Verify only first 2 logs were sent
      verify(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: jsonEncode(['first', 'second']),
        ),
      ).called(1);
    });

    test('does not output when enabled is false', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((final _) async => http.Response('OK', 200));

      final sink = HttpSink(
        url: 'https://example.com/logs',
        batchSize: 1,
        enabled: false,
        client: mockClient,
      );

      await sink.output([LogLine.text('ignored')], LogLevel.info);
      await Future.delayed(Duration.zero);

      verifyNever(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      );
    });

    test('dispose flushes remaining buffer', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((final _) async => http.Response('OK', 200));

      final sink = HttpSink(
        url: 'https://example.com/logs',
        batchSize: 100, // High threshold
        client: mockClient,
      );

      await sink.output([LogLine.text('pending')], LogLevel.info);
      verifyNever(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      );

      await sink.dispose();

      verify(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: jsonEncode(['pending']),
        ),
      ).called(1);
    });
  });
}
