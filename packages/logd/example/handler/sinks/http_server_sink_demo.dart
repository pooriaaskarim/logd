import 'dart:async';
import 'dart:io';

import 'package:logd/logd.dart';

void main() async {
  print('\x1B[1m\x1B[96mlogd\x1B[0m | Embedded Viewer Dashboard Showcase');
  print(
      '\x1B[2m─────────────────────────────────────────────────────────────\x1B[0m');

  // Find a free port starting at 8080
  int port;
  try {
    final testSocket = await ServerSocket.bind('localhost', 8080);
    port = testSocket.port;
    await testSocket.close();
  } catch (_) {
    final testSocket = await ServerSocket.bind('localhost', 0);
    port = testSocket.port;
    await testSocket.close();
  }

  // Create the server sink
  final sink = HttpServerSink(
    address: 'localhost',
    port: port,
    encoder: const HtmlEncoder(),
  );

  await sink.ready;

  // Configure a logger that outputs structured logs to the dashboard
  final handler = Handler(
    formatter: const ToonPrettyFormatter(
      metadata: {
        LogMetadata.timestamp,
        LogMetadata.logger,
        LogMetadata.origin,
      },
    ),
    decorators: const [
      StyleDecorator(),
      BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: sink,
  );

  Logger.configure('sys.server', handlers: [handler]);
  final logger = Logger.get('sys.server');

  print('\x1B[1m\x1B[92m[Dashboard Server Started]\x1B[0m');
  print('👉 Open your browser at: \x1B[4mhttp://localhost:$port\x1B[24m');
  print('Press Ctrl+C to terminate the demo.');
  print(
      '\x1B[2m─────────────────────────────────────────────────────────────\x1B[0m');

  // Emit some initial startup logs
  logger.info('Starting backend dashboard demo application...');
  await Future<void>.delayed(const Duration(milliseconds: 300));

  logger.info('Initializing memory caches and connection pools.');
  await Future<void>.delayed(const Duration(milliseconds: 300));

  logger.warning(
    'CPU usage is elevated (84%) during cold-start build compilation.',
  );
  await Future<void>.delayed(const Duration(milliseconds: 300));

  logger.error(
    'Failed to resolve API gateway configuration from config-service-v2.',
    error: const HttpException('Connection timed out after 5000ms'),
    stackTrace: StackTrace.current,
  );

  // Set up a periodic timer to emit simulated operational logs
  int logCount = 0;
  Timer.periodic(const Duration(seconds: 2), (final timer) {
    logCount++;
    final context = {
      'iteration': logCount,
      'memory_usage_mb': 142 + (logCount % 5) * 12,
      'latency_ms': 5 + (logCount % 10) * 8,
    };

    if (logCount % 5 == 0) {
      logger.warning(
        'Simulated dynamic warning alert',
        context: context,
      );
    } else if (logCount % 7 == 0) {
      logger.error(
        'Database write conflict detected',
        context: context,
        error: StateError('Transaction lock contention'),
      );
    } else {
      logger.info(
        'Periodic health check tick',
        context: context,
      );
    }
  });
}
