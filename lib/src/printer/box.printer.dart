import 'dart:io' as io;
import 'package:flutter/foundation.dart';

import '../../logd.dart';

class BoxPrinter {
  BoxPrinter._();
  static int get lineLength =>
      io.stdout.hasTerminal ? io.stdout.terminalColumns - 4 : 80;

  static bool get useColors => io.stdout.supportsAnsiEscapes;

  static String get ansiReset => '\x1B[0m';

  static Map<LogLevel, String> get levelAnsiColors => {
        LogLevel.trace: '\x1B[90m', // Grey
        LogLevel.debug: '\x1B[37m', // White
        LogLevel.info: '\x1B[32m', // Green
        LogLevel.warning: '\x1B[33m', // Yellow
        LogLevel.error: '\x1B[31m', // Red
      };

  static List<String> wrapLine(String text, int maxWidth) {
    final lines = <String>[];
    while (text.isNotEmpty) {
      if (text.length <= maxWidth) {
        lines.add(text);
        break;
      }
      int breakPoint = maxWidth;
      while (breakPoint > 0 && text[breakPoint] != ' ') breakPoint--;
      if (breakPoint == 0) breakPoint = maxWidth;
      lines.add(text.substring(0, breakPoint).trimRight());
      text = text.substring(breakPoint).trimLeft();
    }
    return lines;
  }

  static void printBox(List<String> contentLines, LogLevel level) {
    final color = useColors ? levelAnsiColors[level] ?? '' : '';
    final top = '$color┌${'─' * lineLength}┐$ansiReset';
    final bottom = '$color└${'─' * lineLength}┘$ansiReset';

    debugPrint(top);
    for (String line in contentLines) {
      final padded = line.padRight(lineLength);
      debugPrint('$color│$ansiReset$padded$color│$ansiReset');
    }
    debugPrint(bottom);
    debugPrint('');
  }
}
