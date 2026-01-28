import 'dart:convert';
import 'package:logd/logd.dart';

void main() async {
  print(
      '╔═════════════════════════════════════════════════════════════════════╗');
  print(
      '║                    LOGD: COMPREHENSIVE GALLERY                      ║');
  print(
      '╚═════════════════════════════════════════════════════════════════════╝\n');

  // ===========================================================================
  // 1. THE CLOUD ARCHITECT (Structured + Box + Aligned Suffix + Styling)
  // ===========================================================================
  final cloudHandler = Handler(
    formatter: const StructuredFormatter(
      metadata: {LogMetadata.timestamp, LogMetadata.origin, LogMetadata.logger},
    ),
    decorators: [
      const StyleDecorator(
          theme: LogTheme(colorScheme: LogColorScheme.darkScheme)),
      const SuffixDecorator(' [v1.0.2] ',
          aligned: true, style: LogStyle(color: LogColor.green, dim: true)),
      BoxDecorator(borderStyle: BorderStyle.rounded),
    ],
    sink: const ConsoleSink(),
    lineLength: 80,
  );

  Logger.configure('backend', handlers: [cloudHandler]);
  print('--- GALLERY 1: THE CLOUD ARCHITECT ---');
  print('(Structured + Box + Aligned Suffix + Dark Style)\n');

  Logger.get('backend.init')
      .info('System initialization started. Loading modules...');
  Logger.get('backend.db').error(
      'Failed to connect to database cluster "db-alpha".',
      error: 'ConnectionTimeoutException: Unable to reach host on port 5432');

  // ===========================================================================
  // 2. THE DATA SCIENTIST (Toon + Custom Prefix + Style)
  // ===========================================================================
  final dataHandler = Handler(
    formatter: const ToonFormatter(
      color: true,
      metadata: {LogMetadata.timestamp},
    ),
    decorators: [
      const StyleDecorator(),
      const PrefixDecorator(' TELEMETRY >> ',
          style: LogStyle(color: LogColor.yellow, bold: true)),
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('telemetry', handlers: [dataHandler]);
  print('\n--- GALLERY 2: THE DATA SCIENTIST ---');
  print('(Toon + Custom Styled Prefix + Standard Styling)\n');

  Logger.get('telemetry.sensor_a')
      .debug('Sensor A | value=0.452 | state=nominal');
  Logger.get('telemetry.core')
      .warning('Reactor Core | temp=1240K | cooling=offline');

  // ===========================================================================
  // 3. THE INSPECTOR (JsonPretty + Nested + Color + Box + Hierarchy)
  // ===========================================================================
  final inspectorHandler = Handler(
    formatter: const JsonPrettyFormatter(
      color: true,
      prettyPrintNestedJson: true,
      metadata: {},
    ),
    decorators: [
      const StyleDecorator(theme: _InspectorTheme()),
      const HierarchyDepthPrefixDecorator(
          indent: '│ ', style: LogStyle(color: LogColor.blue)),
      BoxDecorator(borderStyle: BorderStyle.double),
    ],
    sink: const ConsoleSink(),
    lineLength: 65,
  );

  Logger.configure('proxy', handlers: [inspectorHandler]);
  print('\n--- GALLERY 3: THE INSPECTOR ---');
  print(
      '(JsonPretty + Nested Expansion + Hierarchy + Double Box + Custom Theme)\n');

  final payload = {
    'request': {
      'id': 'REQ-778',
      'headers': {'auth': 'bearer ****', 'type': 'json'},
      'body': jsonEncode({
        'action': 'sync',
        'items': [1, 2, 3],
        'metadata': {'v': 1.2, 'stable': true}
      })
    },
    'response_time': '45ms'
  };

  Logger.get('proxy.spy.net')
      .info('API Transaction intercepted.', error: payload);

  // ===========================================================================
  // 4. THE MINIMALIST (Plain + Hierarchy)
  // ===========================================================================
  final debugHandler = Handler(
    formatter: const PlainFormatter(metadata: {LogMetadata.timestamp}),
    decorators: [
      const HierarchyDepthPrefixDecorator(
          indent: '│   ', style: LogStyle(color: LogColor.magenta, dim: true)),
    ],
    sink: const ConsoleSink(),
  );

  Logger.configure('app', handlers: [debugHandler]);
  print('\n--- GALLERY 4: THE MINIMALIST ---');
  print('(Plain + Styled Vertical Hierarchy)\n');

  Logger.get('app').info('Root process');
  Logger.get('app.task').debug('Child task');
  Logger.get('app.task.deep').debug('Deep sub-task');

  // ===========================================================================
  // 5. THE SURVIVOR (Plain + Prefix + Suffix + Box + Style - Chaos Mode)
  // ===========================================================================
  final chaosHandler = Handler(
    formatter: const PlainFormatter(metadata: {}),
    decorators: [
      const PrefixDecorator(' [IN] ',
          style:
              LogStyle(backgroundColor: LogColor.blue, color: LogColor.white)),
      const SuffixDecorator(' [OUT] ',
          style: LogStyle(
              backgroundColor: LogColor.magenta, color: LogColor.white)),
      BoxDecorator(borderStyle: BorderStyle.sharp),
      const StyleDecorator(),
    ],
    sink: const ConsoleSink(),
    lineLength: 35,
  );

  Logger.configure('chaos', handlers: [chaosHandler]);
  print('\n--- GALLERY 5: THE SURVIVOR (CHAOS MODE) ---');
  print('(Multi-Decorator + 35 Width Extreme Wrapping)\n');

  Logger.get('chaos').warning(
      'Stability alert! Message forced to wrap inside a tiny box with both prefix and suffix attached.');

  print(
      '\n═════════════════════════════════════════════════════════════════════');
  print(
      '║                    GALLERY PRESENTATION COMPLETE                    ║');
  print(
      '╚═════════════════════════════════════════════════════════════════════');
}

class _InspectorTheme extends LogTheme {
  const _InspectorTheme() : super(colorScheme: LogColorScheme.darkScheme);
  @override
  LogStyle getStyle(LogLevel level, Set<LogTag> tags) {
    if (tags.contains(LogTag.key)) {
      return const LogStyle(color: LogColor.magenta, bold: true);
    }
    if (tags.contains(LogTag.punctuation)) {
      return const LogStyle(color: LogColor.blue, dim: true);
    }
    if (tags.contains(LogTag.value)) {
      return const LogStyle(color: LogColor.green);
    }
    return super.getStyle(level, tags);
  }
}
