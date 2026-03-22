import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('BoxDecorator', () {
    final lines = ['line 1', 'line 2'];
    const entry = LogEntry(
      loggerName: 'test',
      origin: 'test',
      level: LogLevel.info,
      message: 'msg',
      timestamp: 'now',
    );

    test('adds rounded borders by default', () {
      const decorator = BoxDecorator();
      final doc = createTestDocument(lines);
      try {
        decorateDoc(decorator, doc, entry);
        final rendered = renderLines(doc);

        expect(rendered.first, startsWith('╭'));
        expect(rendered.last, startsWith('╰'));
        expect(rendered[1], startsWith('│'));
        expect(rendered[1], endsWith('│'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('respects sharp border style', () {
      const decorator = BoxDecorator(
        borderStyle: BorderStyle.sharp,
      );
      final doc = createTestDocument(lines);
      try {
        decorateDoc(decorator, doc, entry);
        final rendered = renderLines(doc);

        expect(rendered.first, startsWith('┌'));
        expect(rendered.last, startsWith('└'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });

    test('respects double border style', () {
      const decorator = BoxDecorator(
        borderStyle: BorderStyle.double,
      );
      final doc = createTestDocument(lines);
      try {
        decorateDoc(decorator, doc, entry);
        final rendered = renderLines(doc);

        expect(rendered.first, startsWith('╔'));
        expect(rendered.last, startsWith('╚'));
      } finally {
        doc.releaseRecursive(LogArena.instance);
      }
    });
  });
}
