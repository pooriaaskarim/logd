import 'dart:io';

/// Internal utility to find available ports for test servers.
class NetworkTestUtils {
  const NetworkTestUtils._();

  /// Finds an available TCP port starting from [basePort].
  static Future<int> findAvailablePort(final int basePort) async {
    for (var port = basePort; port < basePort + 100; port++) {
      try {
        final server =
            await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
        await server.close();
        return port;
      } on SocketException {
        // Port taken, continue
      }
    }
    throw StateError(
      'Could not find an available port in range '
      '$basePort-${basePort + 100}',
    );
  }
}
