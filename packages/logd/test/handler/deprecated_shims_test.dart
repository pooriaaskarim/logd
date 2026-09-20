// ignore_for_file: deprecated_member_use

import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Deprecated Shims (v0.9.7 backwards compatibility)', () {
    test('requiredStrategy delegates to wrappingStrategy across all encoders',
        () {
      const encoders = <LogEncoder>[
        PlainTextEncoder(),
        AnsiEncoder(),
        JsonEncoder(),
        AutoConsoleEncoder(),
        AutoTextEncoder(),
        HtmlEncoder(),
        MarkdownEncoder(),
        ToonEncoder(),
      ];

      for (final encoder in encoders) {
        expect(
          encoder.requiredStrategy,
          equals(encoder.wrappingStrategy),
          reason: '${encoder.runtimeType}.requiredStrategy '
              'must equal wrappingStrategy',
        );
      }
    });

    test('LogTheme deprecated factories return valid themes', () {
      const dark = LogTheme.dark();
      const light = LogTheme.light();

      expect(dark, isA<LogTheme>());
      expect(light, isA<LogTheme>());
      expect(dark.brightness, equals(LogBrightness.dark));
      expect(light.brightness, equals(LogBrightness.light));
    });

    test('ColorDecorator deprecated alias matches StyleDecorator', () {
      const ColorDecorator decorator = ColorDecorator();
      expect(decorator, isA<StyleDecorator>());
    });

    test('ToonFormatter deprecated shim in core instantiates and formats', () {
      const formatter = ToonFormatter();
      final entry = LogEntry(
        loggerName: 'shim.test',
        origin: 'test.dart',
        level: LogLevel.info,
        message: 'testing deprecated shim',
        timestamp: '2026-08-15 12:00:00.000',
      );

      const factory = StandardPipelineFactory();
      final doc = factory.checkoutDocument();
      try {
        formatter.format(entry, doc, factory);
        expect(doc.metadata.containsKey(AutoEncoder.encoderKey), isTrue);
      } finally {
        doc.releaseRecursive(Arena.instance);
      }
    });
  });
}
