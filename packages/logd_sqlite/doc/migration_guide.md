# Migration Guide: `logd` v0.9.x to `logd_sqlite`

Starting with `logd` v0.9.7, relational SQLite log persistence is supported via the standalone `logd_sqlite` satellite package.

This guide explains how to integrate and migrate existing log storage to `logd_sqlite`.

## 1. Add the Dependency

Add `logd_sqlite` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^latest_version
  logd_sqlite: ^latest_version
```

Run `dart pub get` or `flutter pub get`.

## 2. Registering Serializers (For Full Isolate Config Sync)

`SqliteHandler.async()` constructs its native `SqliteSink` directly inside the worker isolate from plain configuration parameters, avoiding isolate handle transfer issues and eliminating the need for serializer registration.

However, if you export and import the full logger configuration registry across isolates using `Logger.exportConfig()` and `Logger.importConfig()`, you must register SQLite serializers during your application bootstrap:

```dart
void main() {
  // Required only when using Logger.exportConfig() / Logger.importConfig()
  registerLogdSqliteSerializers();
}
```

## 3. Querying Database Logs

`SqliteSink` provides a built-in query engine:

```dart
final sink = SqliteSink(dbPath: 'app_logs.db');

// Query warning and error logs containing search terms
final logs = sink.queryLogs(
  minLevel: LogLevel.warning,
  search: 'connection timeout',
  limit: 50,
);
```
