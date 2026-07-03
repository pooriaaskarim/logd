// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Integration test for C1 — `logd_avoid_print_sink_in_production`.
library;

import 'package:logd/src/handler/handler.dart';

const handlerBad = Handler(
  formatter: PlainFormatter(metadata: {}),
  // expect_lint: logd_avoid_print_sink_in_production
  sink: PrintSink(),
);

// OK: uses ConsoleSink
const handlerOk = Handler(
  formatter: PlainFormatter(metadata: {}),
  sink: ConsoleSink(),
);
