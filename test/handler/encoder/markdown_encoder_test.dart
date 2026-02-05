import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownEncoder', () {
    const encoder = MarkdownEncoder();

    test('renders HeaderNode as heading', () {
      const doc = LogDocument(nodes: [
        HeaderNode(segments: [
          StyledText('ERROR | logger'),
        ],),
      ],);

      final output = encoder.encode(doc, LogLevel.error);

      expect(output, contains('### ❌ **ERROR | logger**'));
    });

    test('respects headingLevel', () {
      const e = MarkdownEncoder(headingLevel: 1);
      const doc = LogDocument(nodes: [
        HeaderNode(segments: [
          StyledText('INFO'),
        ],),
      ],);

      final output = e.encode(doc, LogLevel.info);
      expect(output, startsWith('# ℹ️ **INFO**'));
    });

    test('renders BoxNode as standard Markdown title and blockquotes', () {
      const doc = LogDocument(nodes: [
        BoxNode(
          title: 'BOX TITLE',
          children: [
            MessageNode(segments: [StyledText('inside box')]),
          ],
        ),
      ],);

      final output = encoder.encode(doc, LogLevel.info);

      expect(output, contains('**BOX TITLE**'));
      expect(output, contains('---'));
      expect(output, contains('> inside box'));
    });

    test('renders nested IndentationNode as nested blockquotes', () {
      const doc = LogDocument(nodes: [
        IndentationNode(
          children: [
            IndentationNode(
              children: [
                MessageNode(segments: [StyledText('nested twice')]),
              ],
            ),
          ],
        ),
      ],);

      final output = encoder.encode(doc, LogLevel.info);

      expect(output, contains('> > nested twice'));
    });

    test('applies semantic styling based on tags', () {
      const doc = LogDocument(nodes: [
        MessageNode(segments: [
          StyledText('error text', tags: {LogTag.error}),
          StyledText(' - '),
          StyledText('timestamp', tags: {LogTag.timestamp}),
        ],),
      ],);

      final output = encoder.encode(doc, LogLevel.info);

      expect(output, contains('***error text***'));
      expect(output, contains('_timestamp_'));
    });

    test('handles empty documents', () {
      const doc = LogDocument(nodes: []);
      expect(encoder.encode(doc, LogLevel.info), equals(''));
    });
  });
}
