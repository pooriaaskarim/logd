// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Custom lint rules for the logd logging library.
///
/// ## Setup
///
/// Add to your package's `pubspec.yaml`:
/// ```yaml
/// dev_dependencies:
///   custom_lint: ^0.7.0
///   logd_linters: ^0.1.0
/// ```
///
/// Enable in `analysis_options.yaml`:
/// ```yaml
/// analyzer:
///   plugins:
///     - custom_lint
/// ```
///
/// ## Rule groups
///
/// - **Arena/Lifecycle (A)**: Protects the LIFO object pool from leaks and
///   use-after-free.
/// - **Purity (B)**: Enforces the semantic vs. physical rendering boundary.
/// - **Consumer Usage (C)**: Guides correct, idiomatic logd usage.
/// - **Config (D)**: Guards the logger inheritance configuration system.
library;

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/arena/checkout_without_release.dart';
import 'src/rules/arena/document_retained_across_cycles.dart';
import 'src/rules/arena/missing_release_in_engine.dart';
import 'src/rules/config/freeze_on_unconfigured_logger.dart';
import 'src/rules/purity/decorator_not_immutable.dart';
import 'src/rules/purity/formatter_not_immutable.dart';
import 'src/rules/purity/formatter_performs_string_rendering.dart';
import 'src/rules/usage/avoid_print_sink_in_production.dart';
import 'src/rules/usage/handler_missing_engine.dart';
import 'src/rules/usage/log_buffer_not_sunk.dart';
import 'src/rules/usage/logtag_use_bitmask.dart';
import 'src/rules/usage/metadata_set_duplicate.dart';

/// The plugin entry point required by `custom_lint_builder`.
PluginBase createPlugin() => _LogdLintersPlugin();

class _LogdLintersPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(final CustomLintConfigs configs) => [
        // A — Arena / Lifecycle
        const DocumentRetainedAcrossCycles(),
        const MissingReleaseInEngine(),
        const CheckoutWithoutRelease(),

        // B — Purity
        const FormatterPerformsStringRendering(),
        const DecoratorNotImmutable(),
        const FormatterNotImmutable(),

        // C — Consumer Usage
        const AvoidPrintSinkInProduction(),
        const LogtagUseBitmask(),
        const LogBufferNotSunk(),
        const HandlerMissingEngine(),
        const MetadataSetDuplicate(),

        // D — Config (opt-in rules are registered but off by default)
        const FreezeOnUnconfiguredLogger(),
      ];
}
