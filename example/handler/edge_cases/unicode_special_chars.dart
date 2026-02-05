// Example: Unicode and Special Characters
//
// Demonstrates:
// - Unicode character handling
// - Emoji support
// - Special ASCII characters
// - Width calculation with wide characters
//
// Expected: Proper handling of all character types

import 'package:logd/logd.dart';

void main() async {
  final handler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      BoxDecorator(
        border: BoxBorderStyle.rounded,
      ),
    ],
    sink: const ConsoleSink(),
    lineLength: 60,
  );

  Logger.configure('example.unicode', handlers: [handler]);
  Logger.get('example.unicode')

    // Unicode characters
    ..info('Unicode: 你好世界 🌍')

    // Emoji
    ..info('Emoji: 🚀 🎉 ✅ ❌ ⚠️ 🔥')

    // Special ASCII
    ..info('Special: !@#\$%^&*()_+-=[]{}|;:,.<>?')

    // Mixed
    ..info('Mixed: Hello 世界! 🎉 Special: !@#')

    // Long unicode string
    ..info('长文本：这是一个非常长的中文消息，应该正确换行');

  print('Verify that unicode and special characters are handled correctly');
}
