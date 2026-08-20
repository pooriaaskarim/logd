// ignore_for_file: experimental_member_use
import 'package:logd/logd.dart';

/// Helper to create a simplified LogDocument from strings.
LogDocument createTestDocument(
  final List<String> lines, {
  final LogPipelineFactory? factory,
}) {
  final f = factory ?? Arena.instance;
  final doc = f.checkoutDocument();
  for (final line in lines) {
    doc.nodes.add(f.checkoutMessage()..segments.add(StyledText(line)));
  }
  return doc;
}

/// Helper for testing formatters: checks out a doc, formats it, and returns it.
/// REMEMBER: The caller must release the document.
LogDocument formatDoc(
  final LogFormatter formatter,
  final LogEntry entry, {
  final LogPipelineFactory? factory,
}) {
  final f = factory ?? Arena.instance;
  final doc = f.checkoutDocument();
  formatter.format(entry, doc, f);
  return doc;
}

/// Helper for testing decorators: applies the decorator in-place.
void decorateDoc(
  final LogDecorator decorator,
  final LogDocument document,
  final LogEntry entry, {
  final LogPipelineFactory? factory,
}) {
  decorator.decorate(document, entry, factory ?? Arena.instance);
}
