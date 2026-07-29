import 'package:logd/src/handler/handler.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:test/test.dart';

class CustomTestEncoder implements LogEncoder {
  const CustomTestEncoder(this.requiredStrategy);

  @override
  final WrappingStrategy requiredStrategy;

  @override
  void preamble(
    final HandlerContext context,
    final LogLevel level,
    final LogPipelineFactory factory, {
    final LogDocument? document,
  }) {}

  @override
  void postamble(
    final HandlerContext context,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) {}

  @override
  void encode(
    final LogEntry entry,
    final LogDocument document,
    final LogLevel level,
    final HandlerContext context,
    final LogPipelineFactory factory, {
    final int? width,
  }) {}
}

void main() {
  group('EncodingSink strategy fallback', () {
    test('falls back to encoder.requiredStrategy if strategy is null', () {
      const encoder = CustomTestEncoder(WrappingStrategy.document);
      final sink = EncodingSink(
        encoder: encoder,
        delegate: (final data) {},
      );
      expect(sink.strategy, equals(WrappingStrategy.document));
    });

    test('uses WrappingStrategy.none as fallback if encoder has none', () {
      const encoder = CustomTestEncoder(WrappingStrategy.none);
      final sink = EncodingSink(
        encoder: encoder,
        delegate: (final data) {},
      );
      expect(sink.strategy, equals(WrappingStrategy.none));
    });

    test('explicit strategy parameter overrides encoder.requiredStrategy', () {
      const encoder = CustomTestEncoder(WrappingStrategy.document);
      final sink = EncodingSink(
        encoder: encoder,
        delegate: (final data) {},
        strategy: WrappingStrategy.none,
      );
      expect(sink.strategy, equals(WrappingStrategy.none));
    });

    test('HtmlEncoder defaults to WrappingStrategy.document in EncodingSink',
        () {
      final sink = EncodingSink(
        encoder: const HtmlEncoder(),
        delegate: (final data) {},
      );
      expect(sink.strategy, equals(WrappingStrategy.document));
    });
  });
}
