# Migration Guide: `logd` v0.9.x to `logd_markdown`

Starting with `logd` v0.9.7, the built-in Markdown handlers and encoders are deprecated. They have been extracted into the standalone `logd_markdown` package.

## 1. Add the Dependency

Add `logd_markdown` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^0.9.7
  logd_markdown: ^0.1.0
```

Run `dart pub get` or `flutter pub get`.

## 2. Update Imports

Since `logd` v0.9.7 still contains deprecated shims for Markdown classes, importing both `package:logd/logd.dart` and `package:logd_markdown/logd_markdown.dart` will cause `Ambiguous import` errors.

You must `hide` the deprecated classes from the `logd` import:

```dart
// Before
import 'package:logd/logd.dart';

// After
import 'package:logd/logd.dart' hide MarkdownEncoder, MarkdownFileHandler;
import 'package:logd_markdown/logd_markdown.dart';
```

## 3. Registering Serializers (For Isolates)

If you use `MarkdownFileHandler.async()` or execute logging pipelines on background isolates, register the `logd_markdown` serializers during your application's bootstrap phase:

```dart
void main() {
  registerLogdMarkdownSerializers();
  
  Logger.configure('app', handlers: [
    MarkdownFileHandler.async(path: 'app_logs.md'),
  ]);
}
```

## 4. Removal in v0.10.0

The deprecated shims in `package:logd` will be completely removed in `v0.10.0`.
