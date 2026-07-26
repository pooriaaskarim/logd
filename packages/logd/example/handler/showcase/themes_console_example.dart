import 'package:logd/logd.dart';

/// Comprehensive example showcasing all Console terminal themes in `logd`.
///
/// Run this example in your terminal:
/// ```powershell
/// dart run example/handler/showcase/themes_console_example.dart
/// ```
void main() {
  print('================================================================');
  print('               LOGD CONSOLE THEMES SHOWCASE                     ');
  print('================================================================\n');

  _demoDefaultTheme();
  _demoDarkTheme();
  _demoLightTheme();
  _demoPastelTheme();
  _demoCustomTheme();
}

/// 1. Default Theme (`DarkTheme()`)
void _demoDefaultTheme() {
  print('\x1B[1m--- 1. DEFAULT THEME (DarkTheme) ---\x1B[0m');

  final handler = Handler(
    formatter: const StructuredFormatter(),
    decorators: const [StyleDecorator(DarkTheme()), BoxDecorator()],
    sink: ConsoleSink(),
  );

  Logger.configure('theme.default', handlers: [handler]);
  final logger = Logger.get('theme.default');

  _logAllLevels(logger, 'Default theme with standard terminal palette');
}

/// 2. High Contrast Theme (`HighContrastTheme()`)
void _demoDarkTheme() {
  print('\n\x1B[1m--- 2. HIGH CONTRAST THEME (HighContrastTheme) ---\x1B[0m');

  final handler = Handler(
    formatter: const StructuredFormatter(),
    decorators: const [
      StyleDecorator(HighContrastTheme()),
      BoxDecorator(),
    ],
    sink: ConsoleSink(),
  );

  Logger.configure('theme.dark', handlers: [handler]);
  final logger = Logger.get('theme.dark');

  _logAllLevels(logger, 'Dark mode optimized with high-contrast bright colors');
}

/// 3. Light Theme (`LightTheme()`)
void _demoLightTheme() {
  print('\n\x1B[1m--- 3. LIGHT THEME (LightTheme) ---\x1B[0m');

  final handler = Handler(
    formatter: const StructuredFormatter(),
    decorators: const [StyleDecorator(LightTheme()), BoxDecorator()],
    sink: ConsoleSink(),
  );

  Logger.configure('theme.light', handlers: [handler]);
  final logger = Logger.get('theme.light');

  _logAllLevels(logger, 'Light terminal theme with dark text for readability');
}

/// 4. Pastel Theme (`PastelTheme()`)
void _demoPastelTheme() {
  print('\n\x1B[1m--- 4. PASTEL THEME (PastelTheme) ---\x1B[0m');

  final handler = Handler(
    formatter: const StructuredFormatter(),
    decorators: const [StyleDecorator(PastelTheme()), BoxDecorator()],
    sink: ConsoleSink(),
  );

  Logger.configure('theme.pastel', handlers: [handler]);
  final logger = Logger.get('theme.pastel');

  _logAllLevels(logger, 'Pastel color palette for soft visual feedback');
}

/// 5. Custom Styled Theme
void _demoCustomTheme() {
  print(
      '\n\x1B[1m--- 5. CUSTOM STYLED THEME (Tailored Styles & Colors) ---\x1B[0m');

  const customTheme = LogTheme(
    colorScheme: LogColorScheme(
      trace: LogColor.green,
      debug: LogColor.brightCyan,
      info: LogColor.brightBlue,
      warning: LogColor.brightYellow,
      error: LogColor.brightRed,
    ),
    timestampStyle: LogStyle(color: LogColor.magenta, bold: true, italic: true),
    loggerNameStyle:
        LogStyle(color: LogColor.brightMagenta, bold: true, underline: true),
    levelStyle:
        LogStyle(color: LogColor.brightWhite, bold: true, inverse: true),
    borderStyle: LogStyle(color: LogColor.cyan, dim: true),
  );

  final handler = Handler(
    formatter: const StructuredFormatter(),
    decorators: const [StyleDecorator(customTheme), BoxDecorator()],
    sink: ConsoleSink(),
  );

  Logger.configure('theme.custom', handlers: [handler]);
  final logger = Logger.get('theme.custom');

  _logAllLevels(logger, 'Custom theme with custom level/timestamp overrides');
}

/// Emits logs across all severity levels for demonstration
void _logAllLevels(final Logger logger, final String description) {
  logger.trace('TRACE: Low-level diagnostic details ($description)');
  logger.debug('DEBUG: Debugging application state ($description)');
  logger.info('INFO: Application operation successful');
  logger.warning('WARNING: High resource usage detected');
  logger.error(
    'ERROR: Operational failure encountered',
    error: StateError('Unable to establish database connection'),
  );
}
