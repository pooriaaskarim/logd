import 'package:logd/logd.dart';

void main() {
  print('=== Box Tab Debug: Standard Engine ===');
  final standardHandler = Handler(
    formatter: const PlainFormatter(metadata: {}),
    decorators: const [
      BoxDecorator(borderStyle: BorderStyle.sharp),
    ],
    sink: const ConsoleSink(lineLength: 40),
    engine: const StandardEngine(),
  );

  Logger.configure('tab_std', handlers: [standardHandler]);
  print('1234567890123456789012345678901234567890');
  Logger.get('tab_std').info('\tFirst Tab');
  Logger.get('tab_std').info('NoTab\tTab');

  print('\n=== Box Tab Debug: Native Engine ===');
  final nativeHandler = Handler(
    formatter: const PlainFormatter(metadata: {}),
    decorators: const [
      BoxDecorator(borderStyle: BorderStyle.sharp),
    ],
    sink: const ConsoleSink(lineLength: 40),
    engine: NativeEngine(),
  );

  Logger.configure('tab_nat', handlers: [nativeHandler]);
  print('1234567890123456789012345678901234567890');
  Logger.get('tab_nat').info('\tFirst Tab');
  Logger.get('tab_nat').info('NoTab\tTab');
}
