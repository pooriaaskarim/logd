// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Tests for C5 — `logd_handler_missing_engine`.
library;

import 'dart:typed_data';
import 'package:logd/logd.dart';

void configureHandlers() {
  // expect_lint: logd_handler_missing_engine
  final handler = Handler(
    formatter: const PlainFormatter(metadata: {}),
    sink: IsolateSink(const MyByteSink()),
  );

  // OK: uses ArenaEngine explicitly
  final handlerOk = Handler(
    formatter: const PlainFormatter(metadata: {}),
    sink: IsolateSink(const MyByteSink()),
    engine: const ArenaEngine(),
  );

  // ignore: unused_local_variable
  final h1 = handler;
  // ignore: unused_local_variable
  final h2 = handlerOk;
}

base class MyByteSink extends LogSink<Uint8List> {
  const MyByteSink();
  @override
  Future<void> output(
    final Uint8List data,
    final LogEntry entry,
    final LogLevel level,
    final LogPipelineFactory factory,
  ) async {}
}

void main() {}
