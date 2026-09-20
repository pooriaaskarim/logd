// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:logd/logd.dart';

void main() async {
  // Configured pipeline conforming to all logd_linters static analysis rules
  final handler = ConsoleHandler();

  Logger.configure(
    'global',
    handlers: [handler],
  );

  final logger = Logger.get('app.service');
  logger.info('Clean, lint-validated pipeline initialized successfully.');

  // AsyncHandler lifecycle: always dispose handlers when terminating
  await handler.dispose();
}
