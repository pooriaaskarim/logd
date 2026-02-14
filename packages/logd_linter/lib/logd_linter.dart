import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/lints/avoid_abandoned_log_buffers.dart';

/// Entry point for the logd_linter custom_lint plugin.
PluginBase createPlugin() {
  print('[LOGD_LINTER] createPlugin() called!');
  return _LogdLinterPlugin();
}

class _LogdLinterPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(final CustomLintConfigs configs) => [
        const AvoidAbandonedLogBuffers(),
      ];
}
