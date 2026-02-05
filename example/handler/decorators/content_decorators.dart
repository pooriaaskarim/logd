import 'package:logd/logd.dart';

void main() {
  print('=== Logd / Content Decorators Verification ===\n');

  // 1. Basic Prefix & Suffix on Single Line
  print('--- 1. Basic Single Line (Prefix + Suffix) ---');
  final basicHandler = Handler(
    formatter: const PlainFormatter(metadata: {}),
    decorators: [
      const PrefixDecorator('[PRE] '),
      const SuffixDecorator(' [SUF]'),
    ],
    sink: const ConsoleSink(),
    lineLength: 80,
  );
  Logger.configure('basic', handlers: [basicHandler]);
  Logger.get('basic').info('Hello World');

  // 2. Multi-line with Explicit Newlines
  print('\n--- 2. Explicit Newlines ---');
  Logger.get('basic').info('Line 1\nLine 2\nLine 3');

  // 3. Wrapping Long Lines (Prefix + Suffix)
  print('\n--- 3. Wrapping Long Lines ---');
  final wrapHandler = Handler(
    formatter: const PlainFormatter(metadata: {}),
    decorators: [
      const PrefixDecorator('> '),
      const SuffixDecorator(' <'),
    ],
    sink: const ConsoleSink(),
    lineLength: 40,
  );
  Logger.configure('wrap', handlers: [wrapHandler]);
  Logger.get('wrap').info(
      'This is a long message that should wrap to multiple lines and have decorators on each line.');

  // 4. Wrapped Stack Trace
  print('\n--- 4. Stack Trace Wrapping ---');
  try {
    throw Exception('Crash!');
  } catch (e, s) {
    Logger.get('wrap').error('Something went wrong', error: e, stackTrace: s);
  }

  // 5. Aligned Suffix
  print('\n--- 5. Aligned Suffix ---');
  final alignHandler = Handler(
    formatter: const PlainFormatter(metadata: {}),
    decorators: [
      const PrefixDecorator('| '),
      const SuffixDecorator(' |', aligned: true),
    ],
    sink: const ConsoleSink(),
    lineLength: 50,
  );
  Logger.configure('align', handlers: [alignHandler]);
  Logger.get('align').info('Short message');
  Logger.get('align').info('A bit longer message here');
  Logger.get('align').info(
      'This message is quite long and might wrap around, checking alignment on wrapped lines too.');

  // 6. Box + Alignment + Prefix (The "Scattered" Test)
  print('\n--- 6. Box + Alignment + Prefix ---');
  final boxHandler = Handler(
    formatter: const PlainFormatter(metadata: {}),
    decorators: [
      const PrefixDecorator('>> '),
      const SuffixDecorator(' <<', aligned: true),
      const BoxDecorator(border: BoxBorderStyle.rounded),
    ],
    sink: const ConsoleSink(),
    lineLength: 60,
  );
  Logger.configure('box', handlers: [boxHandler]);
  Logger.get('box').info('System status check.');
  Logger.get('box').warning('Warning: CPU load high.\nCheck process list.');

  // 7. Empty Lines / Edge Cases
  print('\n--- 7. Edge Cases (Empty Lines) ---');
  // Wrapping shouldn't break on empty segments
  Logger.get('wrap').info('Start\n\nEnd'); // Expect > Start < \n > < \n > End <

  print('\n=== Verification Complete ===');
}
