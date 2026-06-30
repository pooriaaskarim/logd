// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Tests for C1 — `logd_avoid_print_sink_in_production`.
library;

import 'package:logd/src/handler/handler.dart';

void configureLogger() {
  // expect_lint: logd_avoid_print_sink_in_production
  final handler = Handler(
    formatter: const PlainFormatter(metadata: {}),
    sink: PrintSink(),
  );

  // OK: uses ConsoleSink
  final handlerOk = Handler(
    formatter: const PlainFormatter(metadata: {}),
    sink: ConsoleSink(),
  );

  // ignore: unused_local_variable
  final h1 = handler;
  // ignore: unused_local_variable
  final h2 = handlerOk;
}

void main() {}
