import 'package:logd/logd.dart';

void main() async {
  print('=== Logd Edge Case: Extreme Layout Stress Test ===\n');

  // Case 1: The Tiny Box (Minimum width)
  // Ensures clamping and logic doesn't crash on negative widths.
  const tinyHandler = Handler(
    formatter: StructuredFormatter(),
    decorators: [
      BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: ConsoleSink(lineLength: 8), // Tiny! Internal space ~2-4 chars
  );

  Logger.configure('tiny', handlers: [tinyHandler]);
  print('STRESS 1: Tiny Box (8 chars)');
  Logger.get('tiny').info('Hello World from the tiny box!');

  // Case 2: The "Unbreakable" Token
  // Long words without spaces must be broken mid-char if necessary.
  const glueHandler = Handler(
    formatter: PlainFormatter(metadata: {}),
    sink: ConsoleSink(lineLength: 20),
  );

  Logger.configure('glue', handlers: [glueHandler]);
  print('\nSTRESS 2: Unbreakable Word Wrapping');
  Logger.get('glue').info('Supercalifragilisticexpialidocious_is_one_very'
      '_long_string_without_spaces');

  // Case 3: Tabs in Frames (Visual Alignment Test)
  // Verifies specialized box tab-expansion logic.
  const tabBoxHandler = Handler(
    formatter: PlainFormatter(metadata: {}),
    decorators: [
      BoxDecorator(borderStyle: BorderStyle.sharp),
    ],
    sink: ConsoleSink(lineLength: 40),
  );

  Logger.configure('tab', handlers: [tabBoxHandler]);
  print('\nSTRESS 3: Tab-Indented Content in Frames');
  Logger.get('tab').info('\tFirst Tab\n\t\tSecond Tab\nNon-tabbed line');

  // Case 4: Deep Recursion Safety in JsonFormatter
  const deepJsonHandler = Handler(
    formatter: JsonPrettyFormatter(color: true),
    decorators: [StyleDecorator()],
    sink: ConsoleSink(),
  );

  Logger.configure('deep', handlers: [deepJsonHandler]);
  print('\nSTRESS 4: Deep JSON Nesting');
  Map<String, dynamic> buildDeep(final int depth) {
    if (depth == 0) {
      return {'leaf': 'reached'};
    }
    return {'node_$depth': buildDeep(depth - 1)};
  }

  Logger.get('deep').info('Deep structural dive', error: buildDeep(8));

  // Case 5: Semantic Tag Mixing
  // Ensuring tags from different phases (Formatter + Box + Suffix) all style
  // correctly.
  const mixHandler = Handler(
    formatter: ToonPrettyFormatter(),
    decorators: [
      StyleDecorator(theme: LogTheme(colorScheme: LogColorScheme.darkScheme)),
      BoxDecorator(borderStyle: BorderStyle.double),
      SuffixDecorator(
        ' [FINAL] ',
        style: LogStyle(color: LogColor.green, bold: true),
      ),
    ],
    sink: ConsoleSink(lineLength: 40),
  );

  Logger.configure('mixer', handlers: [mixHandler]);
  print('\nSTRESS 5: Tag Intersection (Toon + Box + Suffix)');
  Logger.get('mixer')
      .warning('Mixing Toon semantics with Box and Suffix decorators.');

  print('\n=== Stress Test Complete ===');
}
