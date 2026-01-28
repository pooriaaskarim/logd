import 'package:logd/logd.dart';

/// This example demonstrates the implicit wrapping behavior.
///
/// Decorators like `BoxDecorator` and aligned `SuffixDecorator` now automatically
/// wrap content that exceeds the available width. This ensures that layout
/// constraints are respected even when using formatters like `JsonFormatter`
/// that produce single long lines.
void main() async {
  print('=== Logd / Wrapping Showcase ===\n');

  // SCENARIO 1: Unwrapped JSON (Default)
  // JsonFormatter produces one long line. Box expands to fit it.
  final rawHandler = Handler(
    formatter: const JsonFormatter(metadata: {}),
    decorators: [
      const BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: const ConsoleSink(),
    lineLength: 40,
  );

  Logger.configure('raw', handlers: [rawHandler]);
  print('--- 1. Raw JSON (Expands Box) ---');
  Logger.get('raw').info(
    'This is a very long message that will force the box to expand beyond the requested 40 chars width limit.',
  );

  print('\n${'=' * 60}\n');

  // SCENARIO 2: Implicitly Wrapped Box
  // BoxDecorator enforces the 40 char limit by splitting the JSON string automatically.
  final wrappedHandler = Handler(
    formatter: const JsonFormatter(metadata: {}),
    decorators: [
      const BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: const ConsoleSink(),
    lineLength: 40,
  );

  Logger.configure('wrapped', handlers: [wrappedHandler]);
  print('--- 2. Wrapped JSON (Respects Width) ---');
  Logger.get('wrapped').info(
    'This is the same long message, but now it wraps gracefully inside the box.',
  );

  print('\n${'=' * 60}\n');

  // SCENARIO 3: Wrapped + Suffix (Sidebar Effect)
  // SuffixDecorator (aligned) ensures content fits first.
  final sidebarHandler = Handler(
    formatter: const JsonFormatter(metadata: {}),
    decorators: [
      const SuffixDecorator(' [SIDEBAR]', aligned: true),
      const BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: const ConsoleSink(),
    lineLength: 50,
  );

  Logger.configure('sidebar', handlers: [sidebarHandler]);
  print('--- 3. Wrapped + Sidebar Suffix ---');
  Logger.get('sidebar').info(
    'This message wraps, and the suffix aligns perfectly on every line.',
  );

  print('\n=== Wrapping Showcase Complete ===');
}
