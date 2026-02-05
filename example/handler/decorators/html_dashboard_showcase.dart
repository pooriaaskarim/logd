// Example: HTML Dashboard Showcase
//
// This example demonstrates the "Composition over Configuration" philosophy
// by combining different decorators and formatters for HTML output.
//
// Decorators allowed to be chained sequentially to transform the log stream:
// - Structural: BoxDecorator (Collapsible containers)
// - Content: PrefixDecorator and SuffixDecorator (Metadata tagging)
// - Positional: HierarchyDepthPrefixDecorator (Tree-structured nesting)
// - Visual: StyleDecorator (Color and theme application)

import 'package:logd/logd.dart';

void main() async {
  print('Generating HTML Dashboard Showcase...');

  // Use a shared sink for all examples
  final dashboardSink = HtmlLayoutSink(
    FileSink('logs/html_dashboard_showcase.html'),
    encoder: const HtmlEncoder(darkMode: true),
  );

  // 1. Box Decoration (Standard structural container)
  // This is the most common use case for HTML dashboards.
  final boxHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const BoxDecorator(border: BoxBorderStyle.rounded),
      const StyleDecorator(
          theme: LogTheme(
              colorScheme: LogColorScheme.darkScheme,
              borderStyle: LogStyle(color: LogColor.brightMagenta))),
    ],
    sink: dashboardSink,
  );

  // 2. Linear Tagging (Grep-friendly lines with color)
  // Useful for high-density logs where vertical space is prioritized.
  final taggedHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const PrefixDecorator('[NETWORK] '),
      const StyleDecorator(
          theme: LogTheme(colorScheme: LogColorScheme.pastelScheme)),
    ],
    sink: dashboardSink,
  );

  // 3. Enclosed Metadata (Prefix + Suffix)
  // Useful for bookending information with icons or status tags.
  final metadataHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const PrefixDecorator('⚙️ '),
      const SuffixDecorator('[RESOLVED]', aligned: true),
      const StyleDecorator(
          theme: LogTheme(colorScheme: LogColorScheme.darkScheme)),
    ],
    sink: dashboardSink,
  );

  // 4. Hierarchical Composition (Nesting + Boxing)
  // Demonstrates how hierarchy decorators shift the entire UI container.
  final treeHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const BoxDecorator(border: BoxBorderStyle.double),
      const HierarchyDepthPrefixDecorator(indent: '  '),
      const StyleDecorator(
          theme: LogTheme(colorScheme: LogColorScheme.pastelScheme)),
    ],
    sink: dashboardSink,
  );

  // 5. Multi-layer Context (Multiple Prefixes + Boxing)
  // Shows how multiple decorators of the same type can be stacked.
  final multiContextHandler = Handler(
    formatter: const StructuredFormatter(),
    decorators: [
      const PrefixDecorator('[PRODUCTION] '),
      const PrefixDecorator('[NODE-01] '),
      const BoxDecorator(border: BoxBorderStyle.sharp),
      const StyleDecorator(
          theme: LogTheme(colorScheme: LogColorScheme.darkScheme)),
    ],
    sink: dashboardSink,
  );

  // Registry Configuration
  Logger.configure('sys.box', handlers: [boxHandler]);
  Logger.configure('sys.net', handlers: [taggedHandler]);
  Logger.configure('sys.io', handlers: [metadataHandler]);
  Logger.configure('sys.tree', handlers: [treeHandler]);
  Logger.configure('sys.prod', handlers: [multiContextHandler]);

  // Execute logging scenarios
  print('Running logging scenarios...');

  Logger.get('sys.box').info('Standard interactive box initialized.');

  Logger.get('sys.net').debug('Fetching packet from stream...');

  Logger.get('sys.io').info('Syncing local buffer to persistent storage.');

  final tree = Logger.get('sys.tree');
  tree.info('Parent Process Started');
  Logger.get('sys.tree.child').info('Child Process Child Node Ready');
  Logger.get('sys.tree.child.leaf').error('Leaf node transition error!');

  Logger.get('sys.prod').info('Deployment manifest verified.');

  // Cleanup
  await dashboardSink.close();

  print('\nExample generated at: logs/decorator_composition.html');
  print(
      'Open this file in a browser to see the following decorator interactions:');
  print('- BoxDecorator transformed into native HTML collapsible containers.');
  print(
      '- HierarchyDepthPrefixDecorator shifting containers semantically via CSS.');
  print('- Suffix/Prefix decorators providing bookended metadata.');
  print(
      '- StyleDecorator mapping LogColors to CSS border and text properties.');
}
