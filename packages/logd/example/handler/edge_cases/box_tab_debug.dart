import 'package:logd/logd.dart';

void main() {
  print('=== Box Tab Debug ===');

  // Replicate Stress 3 config
  const tabBoxHandler = Handler(
    formatter: PlainFormatter(metadata: {}),
    decorators: [
      BoxDecorator(borderStyle: BorderStyle.sharp),
    ],
    sink: ConsoleSink(lineLength: 40),
  );

  Logger.configure('tab', handlers: [tabBoxHandler]);
  // "[INFO] " + "\tFirst Tab"
  // [INFO] is 7 chars.
  // +2 start offset => starts at 9.
  // \t at 9 snaps to 16. (delta 7).
  // Total visual: 7 + 7 + 9 ("First Tab") = 23.
  // Content width: 40 - 4 = 36.
  // Padding: 36 - 23 = 13.

  print('Expected behavior: Box width exactly 40 chars.');
  print('1234567890123456789012345678901234567890');
  Logger.get('tab').info('\tFirst Tab');

  // Mixed
  Logger.get('tab').info('NoTab\tTab');
}
