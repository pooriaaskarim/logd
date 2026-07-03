// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: equal_elements_in_set

/// Integration test for C6 — `logd_metadata_set_duplicate`.
library;

import 'package:logd/logd.dart';

void configureFormatter() {
  final formatter = PlainFormatter(
    metadata: {
      LogMetadata.timestamp,
      // expect_lint: logd_metadata_set_duplicate
      LogMetadata.timestamp, // duplicate
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
  final f1 = formatter;
  // ignore: unused_local_variable
  const f2 = formatterOk;
}
