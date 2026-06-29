import 'dart:isolate';
import 'package:logd/logd.dart';
import 'package:test/test.dart';

void main() {
  group('Logger Serialization & Isolate Export/Import', () {
    setUp(() {
      // Setup default configuration for global before we customize
      Logger.configure('global', logLevel: LogLevel.info);
    });

    test('should serialize and deserialize a complex LoggerConfig', () {
      final config = LoggerConfig(
        enabled: true,
        logLevel: LogLevel.debug,
        includeFileLineInHeader: true,
        stackMethodCount: const {
          LogLevel.debug: 3,
          LogLevel.error: 10,
        },
        timestamp: Timestamp(
          formatter: 'yyyy-MM-dd HH:mm:ss',
          timezone: Timezone.utc(),
        ),
        stackTraceParser: const StackTraceParser(
          ignorePackages: ['test_api', 'path'],
        ),
        handlers: const [
          Handler(
            formatter: PlainFormatter(),
            sink: ConsoleSink(),
            filters: [
              LevelFilter(LogLevel.debug),
              ContextFilter('app_id', value: 'my_app'),
            ],
            decorators: [
              BoxDecorator(),
              StyleDecorator(
                theme: LogTheme(colorScheme: LogColorScheme.darkScheme),
              ),
              PrefixDecorator('>>> '),
              SuffixDecorator(' <<<', aligned: false),
            ],
          ),
        ],
        autoSinkBuffer: true,
      );

      final json = config.toJson();

      // Basic structure validation
      expect(json['enabled'], isTrue);
      expect(json['logLevel'], equals('debug'));
      expect(json['includeFileLineInHeader'], isTrue);
      expect(
        (json['stackMethodCount'] as Map<String, dynamic>)['debug'],
        equals(3),
      );
      expect(
        (json['stackMethodCount'] as Map<String, dynamic>)['error'],
        equals(10),
      );
      expect(
        (json['timestamp'] as Map<String, dynamic>)['formatter'],
        equals('yyyy-MM-dd HH:mm:ss'),
      );
      expect(
        (json['timestamp'] as Map<String, dynamic>)['timezone'],
        equals('UTC'),
      );
      expect(
        (json['stackTraceParser'] as Map<String, dynamic>)['ignorePackages'],
        contains('test_api'),
      );
      expect(json['autoSinkBuffer'], isTrue);

      // Reconstruct
      final deserialized = LoggerConfig.fromJson(json);

      expect(deserialized.enabled, isTrue);
      expect(deserialized.logLevel, equals(LogLevel.debug));
      expect(deserialized.includeFileLineInHeader, isTrue);
      expect(deserialized.stackMethodCount?[LogLevel.debug], equals(3));
      expect(deserialized.stackMethodCount?[LogLevel.error], equals(10));
      expect(
        deserialized.timestamp?.formatter.pattern,
        equals('yyyy-MM-dd HH:mm:ss'),
      );
      expect(deserialized.timestamp?.timezone?.name, equals('UTC'));
      expect(
        deserialized.stackTraceParser?.ignorePackages,
        contains('test_api'),
      );
      expect(deserialized.autoSinkBuffer, isTrue);

      expect(deserialized.handlers?.length, equals(1));
      final handler = deserialized.handlers![0];
      expect(handler.formatter, isA<PlainFormatter>());
      expect(handler.sink, isA<ConsoleSink>());
      expect(handler.filters, hasLength(2));
      expect(handler.filters[0], isA<LevelFilter>());
      expect(handler.filters[1], isA<ContextFilter>());
      expect(handler.decorators, hasLength(4));
      expect(handler.decorators[0], isA<BoxDecorator>());
      expect(handler.decorators[1], isA<StyleDecorator>());
      expect(handler.decorators[2], isA<PrefixDecorator>());
      expect(handler.decorators[3], isA<SuffixDecorator>());
    });

    test('should export and import configurations globally', () {
      Logger.configure(
        'custom_logger',
        enabled: true,
        logLevel: LogLevel.warning,
      );

      final configMap = Logger.exportConfig();
      expect(configMap['registry'], isA<Map>());
      expect(
        (configMap['registry'] as Map<String, dynamic>)['custom_logger'],
        isNotNull,
      );

      // Now reset and import
      Logger.configure('custom_logger', logLevel: LogLevel.info);
      expect(Logger.get('custom_logger').logLevel, equals(LogLevel.info));

      Logger.importConfig(configMap);
      expect(Logger.get('custom_logger').logLevel, equals(LogLevel.warning));
    });

    test('should transfer config across isolates and apply it', () async {
      final receivePort = ReceivePort();
      Logger.configure(
        'isolate_logger',
        enabled: true,
        logLevel: LogLevel.error,
      );

      final config = Logger.exportConfig();

      await Isolate.spawn(_isolateMain, {
        'config': config,
        'sendPort': receivePort.sendPort,
      });

      final LogLevel levelInIsolate = await receivePort.first;
      expect(levelInIsolate, equals(LogLevel.error));
    });
  });
}

void _isolateMain(final Map<String, dynamic> message) {
  final config = message['config'] as Map<String, dynamic>;
  final sendPort = message['sendPort'] as SendPort;

  Logger.importConfig(config);
  final logger = Logger.get('isolate_logger');
  sendPort.send(logger.logLevel);
}
