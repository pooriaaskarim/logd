import 'package:logd/src/handler/handler.dart';

final mockContext = LogContext(availableWidth: 80);

List<String> renderLines(final Iterable<LogLine> lines) {
  final result = <String>[];
  for (final line in lines) {
    final buffer = StringBuffer();
    for (final segment in line.segments) {
      final style = segment.style;
      if (style != null) {
        if (style.bold == true) buffer.write(AnsiStyle.bold.sequence);
        if (style.dim == true) buffer.write(AnsiStyle.dim.sequence);
        if (style.italic == true) buffer.write(AnsiStyle.italic.sequence);
        if (style.inverse == true) buffer.write(AnsiStyle.reverse.sequence);
        if (style.color != null) {
          final ansiCode = AnsiColorCode.fromLogColor(style.color!);
          buffer.write(ansiCode.foreground);
        }

        buffer.write(segment.text);

        buffer.write(AnsiStyle.reset.sequence);
      } else {
        buffer.write(segment.text);
      }
    }
    result.add(buffer.toString());
  }
  return result;
}
