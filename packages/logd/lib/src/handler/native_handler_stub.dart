import 'dart:async';
import 'dart:typed_data';

import '../core/context/io/file_system.dart';
import '../logger/logger.dart';
import '../stack_trace/stack_trace.dart';
import 'handler.dart';

class Arena implements LogPipelineFactory {
  Arena._();
  static final Arena instance = Arena._();

  LogEntry checkoutLogEntry({
    required final String loggerName,
    required final String origin,
    required final LogLevel level,
    required final String message,
    required final String timestamp,
    final List<CallbackInfo>? stackFrames,
    final Object? error,
    final StackTrace? stackTrace,
    final Map<String, dynamic>? context,
  }) =>
      LogEntry(
        loggerName: loggerName,
        origin: origin,
        level: level,
        message: message,
        timestamp: timestamp,
        stackFrames: stackFrames,
        error: error,
        stackTrace: stackTrace,
        context: context,
      );

  void releaseLogEntry(final LogEntry entry) {}

  @override
  LogDocument checkoutDocument() => StandardDocument.pooled();

  @override
  HeaderNode checkoutHeader() => HeaderNode.pooled();

  @override
  MessageNode checkoutMessage() => MessageNode.pooled();

  @override
  ErrorNode checkoutError() => ErrorNode.pooled();

  @override
  FooterNode checkoutFooter() => FooterNode.pooled();

  @override
  MetadataNode checkoutMetadata() => MetadataNode.pooled();

  @override
  BoxNode checkoutBox() => BoxNode.pooled();

  @override
  IndentationNode checkoutIndentation() => IndentationNode.pooled();

  @override
  GroupNode checkoutGroup() => GroupNode.pooled();

  @override
  DecoratedNode checkoutDecorated() => DecoratedNode.pooled();

  @override
  ParagraphNode checkoutParagraph() => ParagraphNode.pooled();

  @override
  RowNode checkoutRow() => RowNode.pooled();

  @override
  SectionNode checkoutSection() => SectionNode.pooled();

  @override
  FillerNode checkoutFiller() => FillerNode.pooled();

  @override
  MapNode checkoutMap() => MapNode.pooled();

  @override
  ListNode checkoutList() => ListNode.pooled();

  @override
  AlignmentNode checkoutAlignment() => AlignmentNode.pooled();

  @override
  TableNode checkoutTable() => TableNode.pooled();

  @override
  TableRowNode checkoutTableRow() => TableRowNode.pooled();

  @override
  TableCellNode checkoutTableCell() => TableCellNode.pooled();

  @override
  Map<K, V> checkoutDataMap<K, V>() => <K, V>{};

  @override
  List<T> checkoutDataList<T>() => <T>[];

  @override
  Set<T> checkoutDataSet<T>() => <T>{};

  @override
  HandlerContext checkoutContext() => HandlerContext.pooled();

  @override
  PhysicalDocument checkoutPhysicalDocument() => PhysicalDocument.pooled();

  @override
  PhysicalLine checkoutPhysicalLine() => PhysicalLine.pooled();

  @override
  void release(final Object obj) {}

  Future<void> waitForPoolCapacity() async {}
  void reclaimInFlightBuffers() {}

  int get poolSize => 0;

  void clear() {}
  void disposeNative() {}
}

class NativeEngine implements LogEngine {
  const NativeEngine();

  @override
  LogPipelineFactory get factory =>
      throw UnsupportedError('NativeEngine is native-only.');

  @override
  Future<void> execute(
    final LogEntry entry,
    final LogFormatter formatter,
    final List<LogDecorator> decorators,
    final LogSink sink,
  ) =>
      throw UnsupportedError('NativeEngine is native-only.');
}

class ArenaEngine implements LogEngine {
  const ArenaEngine();

  @override
  LogPipelineFactory get factory =>
      throw UnsupportedError('ArenaEngine is native-only.');

  @override
  Future<void> execute(
    final LogEntry entry,
    final LogFormatter formatter,
    final List<LogDecorator> decorators,
    final LogSink sink,
  ) =>
      throw UnsupportedError('ArenaEngine is native-only.');
}

base class IsolateSink extends LogSink<Uint8List> {
  IsolateSink(this.target) : super(enabled: target.enabled) {
    throw UnsupportedError('IsolateSink is native-only.');
  }

  final LogSink target;

  @override
  Future<void> output(
    final Uint8List document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) =>
      throw UnsupportedError('IsolateSink is native-only.');
}

base class NativeIsolateSink extends LogSink<dynamic> {
  NativeIsolateSink(final LogSink target) : super(enabled: target.enabled) {
    throw UnsupportedError('NativeIsolateSink is native-only.');
  }

  @override
  Future<void> output(
    final dynamic document,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) =>
      throw UnsupportedError('NativeIsolateSink is native-only.');
}

abstract class FileRotation {
  FileRotation({
    this.compress = false,
    this.backupCount = 5,
  });

  final bool compress;
  final int backupCount;

  Future<bool> needsRotation(final File currentFile, final Uint8List newData);
  Future<void> rotate(final String basePath);
}

class SizeRotation extends FileRotation {
  SizeRotation({
    final String maxSize = '512 KB',
    super.compress,
    super.backupCount,
    this.filenameFormatter,
  }) : maxBytes = maxSize.length * 0;

  final int maxBytes;
  final String Function(
    String baseWithoutExt,
    String? ext,
    int? index,
  )? filenameFormatter;

  @override
  Future<bool> needsRotation(final File currentFile, final Uint8List newData) =>
      throw UnsupportedError('SizeRotation is native-only.');

  @override
  Future<void> rotate(final String basePath) =>
      throw UnsupportedError('SizeRotation is native-only.');
}

class TimeRotation extends FileRotation {
  TimeRotation({
    this.interval = const Duration(days: 1),
    super.compress,
    super.backupCount,
    this.filenameFormatter,
  });

  final Duration interval;
  final String Function(
    String baseWithoutExt,
    String? ext,
    DateTime rotationTime,
  )? filenameFormatter;

  @override
  Future<bool> needsRotation(final File currentFile, final Uint8List newData) =>
      throw UnsupportedError('TimeRotation is native-only.');

  @override
  Future<void> rotate(final String basePath) =>
      throw UnsupportedError('TimeRotation is native-only.');
}

base class FileSink extends EncodingSink {
  FileSink(
    this.basePath, {
    super.encoder = const PlainTextEncoder(),
    this.fileRotation,
    super.strategy = WrappingStrategy.none,
    final int? lineLength,
    super.enabled = true,
  }) : super(
          preferredWidth: lineLength ?? 120,
          delegate: _dummyDelegate,
        );

  final String basePath;
  final FileRotation? fileRotation;

  static FutureOr<void> _dummyDelegate(final Uint8List data) {}
}

class BinaryIR {
  static const int alignLeft = 0;
  static const int alignCenter = 1;
  static const int alignRight = 2;
  static const int alignJustify = 3;
}

class BinaryIRWriter {}

class BinaryAnsiEncoder {}

class BinaryToonEncoder {}
