import 'package:flutter_test/flutter_test.dart';
import 'package:logd/src/core/log_level.dart';
import 'package:logd/src/handler/handler.dart';

void main() {
  group('TerminalLayout Table Rendering', () {
    late LogPipelineFactory factory;
    late TerminalLayout layout;
    late StandardDocument doc;

    setUp(() {
      factory = const StandardPipelineFactory();
      layout = TerminalLayout(width: 40, factory: factory);
      doc = StandardDocument();
    });

    test('renders a simple 2-column table', () {
      doc
        ..startTable(columnWidths: [10, 30])
        ..startRow()
        ..startCell()
        ..text('Key')
        ..endCell()
        ..startCell()
        ..text('Value')
        ..endCell()
        ..endRow()
        ..endTable();

      final physical = layout.layout(doc, LogLevel.info);
      expect(physical.lines.length, equals(1));

      final line = physical.lines.first.toString();
      // "Key       Value                         "
      expect(line.startsWith('Key'), isTrue);
      expect(line.substring(10).startsWith('Value'), isTrue);
      expect(line.length, equals(40));
    });

    test('handles multi-line cells with zipping', () {
      doc
        ..startTable(columnWidths: [20, 20])
        ..startRow()
        ..startCell()
        ..text('Short')
        ..endCell()
        ..startCell()
        ..text('Very Long Value That Should Wrap')
        ..endCell()
        ..endRow()
        ..endTable();

      final physical = layout.layout(doc, LogLevel.info);
      // "Short" is 1 line, "Very Long Value That Should Wrap" is 2 lines
      // (width 20)
      // Line 0: "Short               Very Long Value That"
      // Line 1: "                    Should Wrap         "
      expect(physical.lines.length, equals(2));

      final line0 = physical.lines[0].toString();
      expect(line0.startsWith('Short'), isTrue);
      expect(line0.substring(20).startsWith('Very Long Value That'), isTrue);

      final line1 = physical.lines[1].toString();
      expect(line1.substring(20).startsWith('Should Wrap'), isTrue);
    });

    test('supports colSpan', () {
      doc
        ..startTable(columnWidths: [10, 10, 20])
        ..startRow()
        ..startCell(colspan: 2)
        ..text('Spanned')
        ..endCell()
        ..startCell()
        ..text('Third')
        ..endCell()
        ..endRow()
        ..endTable();

      final physical = layout.layout(doc, LogLevel.info);
      final line = physical.lines.first.toString();
      // "Spanned             Third               "
      //  012345678901234567890123456789
      expect(line.startsWith('Spanned'), isTrue);
      expect(line.substring(20).startsWith('Third'), isTrue);
    });
  });
}
