import 'dart:async';
import 'dart:io';
import 'package:logd/logd.dart';
import '../../../../../scripts/servers/network_test_utils.dart';

void main() async {
  print('\x1B[1m\x1B[96mlogd\x1B[0m | Network Sink Professional Showcase');
  print('\x1B[2m─────────────────────────────────────────────────────────────'
      '\x1B[0m');

  Process? socketServer;
  Process? httpServer;

  try {
    // 0. Dynamic Path Discovery
    final scriptFile = File(Platform.script.toFilePath());
    // example/handler/sinks/network_sink_demo.dart
    final projectRoot =
        scriptFile.parent.parent.parent.parent.parent.parent.path;
    final socketDir = '$projectRoot/scripts/servers/socket';
    final httpDir = '$projectRoot/scripts/servers/http';

    // 1. Dynamic Port Discovery
    final socketPort = await NetworkTestUtils.findAvailablePort(12345);
    final httpPort = await NetworkTestUtils.findAvailablePort(8080);

    print('\x1B[2m[System] Reserving ports: Socket=$socketPort, HTTP=$httpPort'
        '\x1B[0m');

    // 2. Start Servers with Arguments
    socketServer = await Process.start(
      './.venv/bin/python',
      ['main.py', '--port', socketPort.toString()],
      workingDirectory: socketDir,
      environment: {'PYTHONUNBUFFERED': '1'},
    );

    httpServer = await Process.start(
      './.venv/bin/python',
      ['main.py', '--port', httpPort.toString()],
      workingDirectory: httpDir,
      environment: {'PYTHONUNBUFFERED': '1'},
    );

    // Stream server output
    socketServer.stdout.listen((final data) => stdout.add(data));
    httpServer.stdout.listen((final data) => stdout.add(data));
    socketServer.stderr.listen((final data) => stderr.add(data));
    httpServer.stderr.listen((final data) => stderr.add(data));

    await Future.delayed(const Duration(seconds: 2));

    // 3. Rich Compositions Showcase

    // --- CASE 1: The Modern Terminal (Socket + Style + Box) ---
    final terminalHandler = Handler(
      formatter: const PlainFormatter(metadata: {LogMetadata.timestamp}),
      decorators: const [
        StyleDecorator(), // Standard colors
        BoxDecorator(borderStyle: BorderStyle.double),
      ],
      sink: SocketSink(url: 'ws://127.0.0.1:$socketPort'),
    );
    Logger.configure('sys.terminal', handlers: [terminalHandler]);

    // --- CASE 2: Machine Data (HTTP + JSON) ---
    final jsonHandler = Handler(
      formatter: const JsonFormatter(),
      sink: HttpSink(
        url: 'http://127.0.0.1:$httpPort/logs',
        batchSize: 2,
      ),
    );
    Logger.configure('api.raw', handlers: [jsonHandler]);

    // --- CASE 3: Pretty Analytical (HTTP + Pretty JSON) ---
    final prettyJsonHandler = Handler(
      formatter: const JsonPrettyFormatter(color: true),
      decorators: const [StyleDecorator()],
      sink: HttpSink(
        url: 'http://127.0.0.1:$httpPort/logs',
        batchSize: 1,
      ),
    );
    Logger.configure('api.pretty', handlers: [prettyJsonHandler]);

    // --- CASE 4: The LLM Cloud (HTTP + TOON) ---
    final toonHandler = Handler(
      formatter: const ToonFormatter(
        arrayName: 'telemetry',
        metadata: {LogMetadata.logger, LogMetadata.timestamp},
      ),
      sink: HttpSink(
        url: 'http://127.0.0.1:$httpPort/logs',
        batchSize: 3,
      ),
    );
    Logger.configure('app.cloud', handlers: [toonHandler]);

    // --- CASE 5: Documentation Stream (Socket + Markdown) ---
    final docsHandler = Handler(
      formatter: const MarkdownFormatter(),
      sink: SocketSink(url: 'ws://127.0.0.1:$socketPort'),
    );
    Logger.configure('dev.docs', handlers: [docsHandler]);

    // 4. Execution
    final tLog = Logger.get('sys.terminal');
    final jLog = Logger.get('api.raw');
    final pLog = Logger.get('api.pretty');
    final cLog = Logger.get('app.cloud');
    final mLog = Logger.get('dev.docs');

    print(
      '\n\x1B[1m[PHASE 1] Terminal Monitoring (Style + Box + Socket)\x1B[0m',
    );
    tLog.info('Kernel specialized: x86_64 virtualization active');
    await _delay();
    tLog.warning('CPU Thermal Throttling: Core 0 at 98°C');
    await _delay();

    print('\n\x1B[1m[PHASE 2] Raw JSON Pipeline (JSON + HTTP Batching)\x1B[0m');
    jLog
      ..info('Raw telemetry event #1')
      ..info('Raw telemetry event #2 (Triggers HTTP POST)');
    await _delay();

    print(
      '\n\x1B[1m[PHASE 3] Pretty JSON Analytical (Pretty JSON + HTTP)\x1B[0m',
    );
    pLog.info('Payload analysis', error: {'status': 'nominal', 'load': 0.42});
    await _delay();

    print('\n\x1B[1m[PHASE 4] Documentation Stream (Markdown + Socket)\x1B[0m');
    mLog.info(
      '# Security Audit\n\n- **Status**: Secure\n- **Signature**:'
      ' `sha256:abcd...`',
    );
    await _delay();

    print('\n\x1B[1m[PHASE 5] LLM Telemetry (TOON + HTTP Batching)\x1B[0m');
    cLog
      ..info('Context window optimized')
      ..info('Vector database sync complete')
      ..info('Ready for prompt processing');
    print('\x1B[2m   (Sent 3 logs, triggering TOON batch report)\x1B[0m');

    // 5. Cleanup
    await Future.wait([
      terminalHandler.sink.dispose(),
      jsonHandler.sink.dispose(),
      prettyJsonHandler.sink.dispose(),
      toonHandler.sink.dispose(),
      docsHandler.sink.dispose(),
    ]);

    print('\n\x1B[32mShowcase complete.\x1B[0m');
    await Future.delayed(const Duration(seconds: 1));
  } catch (e) {
    print('\x1B[91mDemo failed: $e\x1B[0m');
  } finally {
    socketServer?.kill();
    httpServer?.kill();
    print('\x1B[2m[Cleanup] Servers terminated.\x1B[0m');
  }
}

Future<void> _delay([final int seconds = 1]) =>
    Future.delayed(Duration(seconds: seconds));
