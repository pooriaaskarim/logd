# Migration Guide: `logd` v0.9.x to `logd_network`

`logd_network` provides HTTP batching, WebSocket streaming, and a live web dashboard server for `logd`.

## 1. Add the Dependency

Add `logd_network` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^0.9.7
  logd_network: ^0.1.4
```

Run `dart pub get` or `flutter pub get`.

## 2. Registering Serializers (For Isolates)

If using background isolates or `HttpDashboardHandler.async()`, register the network serializers during bootstrap:

```dart
void main() {
  // Register network serializers for isolate support
  registerLogdNetworkSerializers();

  Logger.configure('app', handlers: [
    HttpDashboardHandler.async(port: 8080),
  ]);
}
```

## 3. Real-Time Dashboard Usage

`HttpDashboardHandler` starts a local web server (default: `http://localhost:8080`) where you can view live log streams in any web browser.
