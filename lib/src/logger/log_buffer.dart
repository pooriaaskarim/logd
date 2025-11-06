part of 'logger.dart';

class LogBuffer extends StringBuffer {
  LogBuffer._();

  static LogLevel _level = LogLevel.debug;

  /// Creates a **Trace** Log Buffer
  static LogBuffer? get t {
    if (Logger.enabled) {
      _level = LogLevel.trace;
      return LogBuffer._();
    }
    return null;
  }

  /// Creates a **Debug** Log Buffer
  static LogBuffer? get d {
    if (Logger.enabled) {
      _level = LogLevel.debug;
      return LogBuffer._();
    }
    return null;
  }

  /// Creates a **Info** Log Buffer
  static LogBuffer? get i {
    if (Logger.enabled) {
      _level = LogLevel.info;
      return LogBuffer._();
    }
    return null;
  }

  /// Creates a **Warning** Log Buffer
  static LogBuffer? get w {
    if (Logger.enabled) {
      _level = LogLevel.warning;
      return LogBuffer._();
    }
    return null;
  }

  /// Creates a **Error** Log Buffer
  static LogBuffer? get e {
    if (Logger.enabled) {
      _level = LogLevel.error;
      return LogBuffer._();
    }
    return null;
  }

  @override
  void writeAll(final Iterable objects, [final String separator = ""]) {
    for (final object in objects) {
      writeln(object);
    }
  }

  void sync() {
    Logger._log(this, level: _level);
    clear();
  }
}
