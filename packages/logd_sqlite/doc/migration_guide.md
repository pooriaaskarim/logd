# Migration Guide: `logd` v0.9.x to `logd_sqlite`

Starting with `logd` v0.9.7, relational SQLite log persistence is supported via the standalone `logd_sqlite` satellite package.

This guide explains how to integrate and migrate existing log storage to `logd_sqlite`.

## 1. Add the Dependency

Add `logd_sqlite` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^0.9.7
  logd_sqlite: ^0.1.3
```

Run `dart pub get` or `flutter pub get`.

## 2. Registering Serializers (For Isolates)

If you use `SqliteHandler.async()` or execute logging pipelines on background isolates, register the `logd_sqlite` serializers during your application's bootstrap phase:

```dart
void main() {
  // Required to prevent cross-isolate serialization crashes
  registerLogdSqliteSerializers();
  
  Logger.configure('app', handlers: [
    SqliteHandler.async(path: 'app_logs.db'),
  ]);
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
