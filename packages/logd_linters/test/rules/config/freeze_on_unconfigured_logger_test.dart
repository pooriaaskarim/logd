// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Tests for D1 — `logd_freeze_on_unconfigured_logger`.
library;

import 'package:logd/logd.dart';

void configureLogger() {
  // expect_lint: logd_freeze_on_unconfigured_logger
  Logger.get('app').freezeInheritance();

  // OK: configure before freeze
  Logger.configure('app', logLevel: LogLevel.debug);
  Logger.get('app').freezeInheritance();
}

void main() {}
