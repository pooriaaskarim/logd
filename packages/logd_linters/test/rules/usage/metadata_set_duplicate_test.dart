// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Tests for C6 — `logd_metadata_set_duplicate`.
library;

import 'package:logd/logd.dart';

void configureFormatter() {
  // expect_lint: logd_metadata_set_duplicate
  const formatter = PlainFormatter(
    metadata: {
      LogMetadata.timestamp,
    },
  );

  // OK: unique values
  const formatterOk = PlainFormatter(
    metadata: {
      LogMetadata.timestamp,
      LogMetadata.logger,
    },
  );

  // ignore: unused_local_variable
  const f1 = formatter;
  // ignore: unused_local_variable
  const f2 = formatterOk;
}

void main() {}
