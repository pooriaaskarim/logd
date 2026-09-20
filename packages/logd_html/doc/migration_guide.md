# Migration Guide: `logd` v0.9.x to `logd_html`

Starting with `logd` v0.9.7, the built-in HTML handlers, formatters, encoders, and stylesheets are deprecated. They have been extracted into the standalone `logd_html` package to reduce the core package size and allow independent versioning of HTML utilities.

This guide explains how to migrate your existing codebase.

## 1. Add the Dependency

Add `logd_html` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^latest_version
  logd_html: ^latest_version
```

Run `dart pub get` or `flutter pub get`.

## 2. Update Imports

Since `logd` v0.9.7 still contains deprecated shims for HTML classes, importing both `package:logd/logd.dart` and `package:logd_html/logd_html.dart` will cause `Ambiguous import` errors.

You must `hide` the deprecated classes from the `logd` import:

```dart
// Before
import 'package:logd/logd.dart';

// After
import 'package:logd/logd.dart' hide HtmlEncoder, HtmlFileHandler, HtmlFormatter, HtmlStylesheet, DefaultHtmlStylesheet;
import 'package:logd_html/logd_html.dart';
```

## 3. Registering Serializers (For Full Isolate Config Sync)

Because `HtmlFormatter` is `@immutable`, using `HtmlFileHandler.async()` automatically transfers the formatter across isolate boundaries without manual registration.

However, if you export and import the full logger configuration registry across isolates using `Logger.exportConfig()` and `Logger.importConfig()`, you must register HTML serializers during your application bootstrap:

```dart
void main() {
  // Required only when using Logger.exportConfig() / Logger.importConfig()
  registerLogdHtmlSerializers();
}
```

## 4. Removal in v0.10.0

The deprecated shims in `package:logd` will be completely removed in `v0.10.0`. Once you upgrade to v0.10.0, you can remove the `hide` clauses from your imports.
