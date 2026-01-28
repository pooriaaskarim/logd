import 'package:logd/logd.dart';

/// This example demonstrates the `HierarchyDepthPrefixDecorator`.
/// It visualizes the nesting level of log entries by using the hierarchical
/// logger naming system.
Future<void> main() async {
  print('=== Logd / Hierarchy Depth Showcase ===\n');

  // SCENARIO 1: Simple Indentation (Tree Style)
  final treeHandler = Handler(
    formatter: const PlainFormatter(metadata: {}),
    decorators: [
      const HierarchyDepthPrefixDecorator(
        indent: '│   ',
      ),
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('tree', handlers: [treeHandler]);
  print('--- Tree Style ---');
  _log('tree', 0, 'Project Root');
  _log('tree', 1, 'src/');
  _log('tree', 2, 'main.dart');
  _log('tree', 2, 'utils.dart');
  _log('tree', 1, 'test/');
  _log('tree', 2, 'unit/');
  _log('tree', 3, 'math_test.dart');
  _log('tree', 0, 'README.md');

  print('\n${'=' * 60}\n');

  // SCENARIO 2: Combined with Box (Box inside Depth)
  // The indentation happens OUTSIDE the box.
  final boxedHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const HierarchyDepthPrefixDecorator(
        indent: '    ',
      ),
      const BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: const ConsoleSink(),
    lineLength: 50,
  );

  Logger.configure('boxed', handlers: [boxedHandler]);
  print('--- Boxed Steps ---');
  _log('boxed', 0, 'Workflow Start');
  _log('boxed', 1, 'Step 1: Download');
  _log('boxed', 1, 'Step 2: Process');
  _log('boxed', 2, 'Sub-task: Unzip');
  _log('boxed', 2, 'Sub-task: Verify Signature');
  _log('boxed', 1, 'Step 3: Save');
  _log('boxed', 0, 'Workflow Complete');

  print('\n=== Hierarchy Depth Showcase Complete ===');
}

void _log(String root, int depth, String msg) {
  // Generate logger name to reflect depth
  final name =
      depth == 0 ? root : '$root.${List.filled(depth, 'sub').join('.')}';

  Logger.get(name).info(msg);
}
