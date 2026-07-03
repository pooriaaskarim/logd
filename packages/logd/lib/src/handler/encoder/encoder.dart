library;

import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../../logd.dart' show ConsoleSink, LogSink;
import '../../core/theme/log_theme.dart';
import '../../logger/logger.dart';
import '../document/document.dart';
import '../engine/engine.dart';
import '../handler.dart' show ConsoleSink, LogSink;
import '../io_stub.dart' if (dart.library.io) '../io_native.dart' as io;
import '../layout/layout.dart';
import '../sink/sink.dart' show ConsoleSink, LogSink;

part 'ansi_encoder.dart';
part 'ansi_encoder_adapter.dart';
part 'auto_console_encoder.dart';
part 'fast_string_writer.dart';
part 'html_encoder.dart';
part 'json_encoder.dart';
part 'log_encoder.dart';
part 'markdown_encoder.dart';
part 'plain_text_encoder.dart';
part 'toon_encoder.dart';
