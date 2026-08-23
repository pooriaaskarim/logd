// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: cascade_invocations

/// Tests for C6 — `logd_handler_missing_dispose`.
library;

import 'package:logd/logd.dart';

void badUsage() {
  // expect_lint: logd_handler_missing_dispose
  final handler = AsyncHandler(
    formatter: const PlainFormatter(),
    sink: ConsoleSink(),
  );
  Logger.configure('app', handlers: [handler]);
}

void badUsageTyped() {
  // expect_lint: logd_handler_missing_dispose
  final Handler handler = AsyncHandler(
    formatter: const PlainFormatter(),
    sink: ConsoleSink(),
  );
  Logger.configure('app', handlers: [handler]);
}

Future<void> goodUsage() async {
  final handler = AsyncHandler(
    formatter: const PlainFormatter(),
    sink: ConsoleSink(),
  );
  Logger.configure('app', handlers: [handler]);
  await handler.dispose();
}

Future<void> goodUsageCascade() async {
  final handler = AsyncHandler(
    formatter: const PlainFormatter(),
    sink: ConsoleSink(),
  )..dispose();
  Logger.configure('app', handlers: [handler]);
}

class ClassFieldService {
  final AsyncHandler _handler = AsyncHandler(
    formatter: const PlainFormatter(),
    sink: ConsoleSink(),
  );

  Future<void> dispose() async {
    await _handler.dispose();
  }
}

void main() {}
