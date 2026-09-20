import 'package:logd/logd.dart';
import 'package:logd/src/handler/handler.dart' show TerminalLayout;
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('PrefixDecorator', () {
    late LogEntry testEntry;

    setUp(() {
      testEntry = LogEntry(
        loggerName: 'test',
        origin: 'prefix_decorator_test.dart',
        level: LogLevel.info,
        message: 'hello prefix',
        timestamp: '2026-09-20T12:00:00.000Z',
      );
    });

    test('prepends fixed prefix to log lines', () {
      const prefix = '>>> ';
      const decorator = PrefixDecorator(prefix);

      final doc = createTestDocument(['first line', 'second line']);
      try {
        decorateDoc(decorator, doc, testEntry);

        final layout = TerminalLayout(width: 80, factory: Arena.instance);
        final rendered = layout.layout(doc, LogLevel.info).lines;

        expect(rendered.length, equals(2));
        expect(rendered[0].segments.first.text, equals(prefix));
        expect(rendered[0].segments.first.tags, equals(LogTag.prefix));
        expect(rendered[1].segments.first.text, equals(prefix));
        expect(rendered[1].segments.first.tags, equals(LogTag.prefix));
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });

    test('returns early without modifying document when prefix is empty', () {
      const decorator = PrefixDecorator('');
      final doc = createTestDocument(['original line']);
      try {
        decorateDoc(decorator, doc, testEntry);

        expect(doc.nodes.length, equals(1));
        // Node should remain the original checkoutMessage, not a DecoratedNode
        expect(doc.nodes.first, isNot(isA<DecoratedNode>()));
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });

    test('applies LogStyle to the prefix', () {
      const prefix = '[TAG] ';
      const style = LogStyle(color: LogColor.cyan, bold: true);
      const decorator = PrefixDecorator(prefix, style: style);

      final doc = createTestDocument(['styled line']);
      try {
        decorateDoc(decorator, doc, testEntry);

        final node = doc.nodes.first as DecoratedNode;
        expect(node.leading!.first.style, equals(style));
        expect(node.leading!.first.text, equals(prefix));
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });

    test('reports correct paddingWidth matching prefix length', () {
      const decorator1 = PrefixDecorator('1234');
      const decorator2 = PrefixDecorator('');

      expect(decorator1.paddingWidth(testEntry), equals(4));
      expect(decorator2.paddingWidth(testEntry), equals(0));
    });

    test('equality and hashCode', () {
      const d1 = PrefixDecorator('>> ', style: LogStyle(bold: true));
      const d2 = PrefixDecorator('>> ', style: LogStyle(bold: true));
      const d3 = PrefixDecorator('>> ');
      const d4 = PrefixDecorator('<< ');

      expect(d1, equals(d2));
      expect(d1.hashCode, equals(d2.hashCode));
      expect(d1, isNot(equals(d3)));
      expect(d1, isNot(equals(d4)));
    });

    test('composes with BoxDecorator', () {
      const prefix = '* ';
      const prefixDecorator = PrefixDecorator(prefix);
      const box = BoxDecorator();

      final doc = createTestDocument(['boxed and prefixed']);
      try {
        // ContentDecorator (Prefix) executes before StructuralDecorator (Box)
        prefixDecorator.decorate(doc, testEntry, Arena.instance);
        box.decorate(doc, testEntry, Arena.instance);

        final layout = TerminalLayout(width: 30, factory: Arena.instance);
        final boxed = layout.layout(doc, LogLevel.info).lines;

        // Line 0 is top border, Line 1 contains content
        expect(boxed.length, equals(3));
        expect(boxed[1].segments.any((final s) => s.text == prefix), isTrue);
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });
  });
}
