# logd_markdown

GitHub-Flavored Markdown (GFM) encoder, formatter, and file handler satellite package for `logd`.

## Features

- **GitHub-Flavored Markdown**: Generates structured Markdown log documents with emoji headings, alert callouts (`> [!ERROR]`), and syntax-highlighted code blocks.
- **Asynchronous Isolate Support**: Offload Markdown serialization and file I/O to background worker isolates using `MarkdownFileHandler.async()`.
- **Isolate Registry**: Includes `registerLogdMarkdownSerializers()` for cross-isolate configuration transfer.

## Installation

Add `logd_markdown` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^0.9.7
  logd_markdown: ^0.1.0
```

## Quick Start

```dart
import 'package:logd/logd.dart' hide MarkdownEncoder, MarkdownFileHandler;
import 'package:logd_markdown/logd_markdown.dart';

void main() async {
  registerLogdMarkdownSerializers();

  final handler = MarkdownFileHandler.async(path: 'logs/app.md');

  Logger.configure('main', handlers: [handler]);

  final logger = Logger.get('main');
  logger.info('Application started successfully');

  await handler.dispose();
}
```
