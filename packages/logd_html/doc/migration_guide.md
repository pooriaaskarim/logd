# Migration Guide: `logd` v0.9.x to `logd_html`

Starting with `logd` v0.9.7, the built-in HTML handlers, formatters, encoders, and stylesheets are deprecated. They have been extracted into the standalone `logd_html` package to reduce the core package size and allow independent versioning of HTML utilities.

This guide explains how to migrate your existing codebase.

## 1. Add the Dependency

Add `logd_html` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^0.9.7
  logd_html: ^0.1.0
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

## 3. Registering Serializers (For Isolates)

If you use `HtmlFileHandler.async()` or execute logging pipelines on background isolates, you MUST register the `logd_html` serializers during your application's bootstrap phase:

```dart
void main() {
  // Required to prevent cross-isolate serialization crashes
  registerLogdHtmlSerializers();
  
  Logger.configure(
    handlers: [
      HtmlFileHandler.async(path: 'app_logs.html'),
    ],
  );
}
```

## 4. Removal in v0.10.0

The deprecated shims in `package:logd` will be completely removed in `v0.10.0`. Once you upgrade to v0.10.0, you can remove the `hide` clauses from your imports.
