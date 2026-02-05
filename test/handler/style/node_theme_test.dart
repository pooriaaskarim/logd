import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Node Theme Resolution', () {
    const theme = LogTheme(
      colorScheme: LogColorScheme.defaultScheme,
      errorStyle: LogStyle(color: LogColor.red, bold: true),
      messageStyle: LogStyle(color: LogColor.white),
    );

    test('resolveNodeStyle uses node tags', () {
      const node = BoxNode(children: [], tags: {LogTag.error});
      final style = theme.resolveNodeStyle(node, LogLevel.info);

      expect(style.color, equals(LogColor.red));
      expect(style.bold, isTrue);
    });

    test('resolveNodeStyle falls back to level color if no tags', () {
      const node = GroupNode(children: []);
      final style = theme.resolveNodeStyle(node, LogLevel.error);

      expect(style.color, equals(LogColor.red));
    });

    test('StyleDecorator applies style to layout nodes based on tags', () {
      const decorator = StyleDecorator(theme: theme);
      const document = LogDocument(
        nodes: [
          BoxNode(
            children: [],
            tags: {LogTag.error},
          ),
        ],
      );

      final decorated = decorator.decorate(
        document,
        const LogEntry(
          loggerName: 'test',
          origin: 'test',
          level: LogLevel.info,
          message: 'msg',
          timestamp: 'now',
        ),
        const LogContext(
            availableWidth: 100, totalWidth: 100, contentLimit: 100,),
      );

      final boxNode = decorated.nodes.first as BoxNode;
      expect(boxNode.style?.color, equals(LogColor.red));
      expect(boxNode.style?.bold, isTrue);
    });
  });
}
