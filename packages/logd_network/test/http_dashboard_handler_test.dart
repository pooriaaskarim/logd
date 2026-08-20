import 'package:logd/logd.dart'
    hide HttpSink, SocketSink, HttpServerSink, HttpDashboardHandler, DropPolicy;
import 'package:logd_network/logd_network.dart';
import 'package:test/test.dart';

void main() {
  group('HttpDashboardHandler Tests', () {
    setUp(() {
      Logger.reset();
    });

    test('HttpDashboardHandler creates valid dashboard pipeline', () {
      final handler = HttpDashboardHandler(port: 8888, title: 'Test Dashboard');

      expect(handler, isA<Handler>());
      expect(handler.formatter, isA<StructuredFormatter>());
      expect(handler.sink, isA<HttpServerSink>());
    });

    test(
      'HttpDashboardHandler cleanly releases resources on dispose',
      () async {
        final handler = HttpDashboardHandler(
          port: 0, // 0 lets OS pick random ephemeral port
          title: 'Test Dashboard',
        );

        // Wait a tiny bit for the internal HttpServer to bind
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Dispose should complete without hanging or crashing
        await expectLater(handler.dispose(), completes);
      },
    );
  });
}
