/// A composable, structured logging library for Dart.
///
/// Logd differs from other logging libraries by treating log entries as
/// structured [LogDocument]s rather than simple strings. This allows for
/// rich layout, styling, and multiple output formats (ANSI, JSON, HTML)
/// from a single pipeline.
///
/// The core components are:
/// - [LogDocument]: The entry point for emitting logs.
/// - [Handler]: Orchestrates the processing pipeline (Filter -> Formatter -> Decorator -> Sink).
/// - [LogFormatter]: Converts a [LogEntry] into a structured [LogDocument].
/// - [LogDecorator]: Wraps or transforms the [LogDocument] (e.g., adding boxes, colors).
/// - [LogSink]: Outputs the final result to a destination (Console, File, Network).
library;

import 'src/handler/handler.dart';
import 'src/logger/logger.dart';

export 'src/core/log_level.dart';
export 'src/core/theme/log_theme.dart';
export 'src/handler/handler.dart' hide DecoratorPipeline, TerminalLayout;
export 'src/logger/logger.dart'
    hide InternalLogger, LogEntry, LoggerCache, LoggerConfig;
export 'src/stack_trace/stack_trace.dart' hide CallbackInfo, StackFrameSet;
export 'src/time/timestamp.dart'
    hide TimestampFormatter, TimestampFormatterCache;
export 'src/time/timezone.dart' hide OffsetLiteralExt, TimezoneOffsetExt;
