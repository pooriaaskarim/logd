# Changelog

## 0.1.0

- Initial release of `logd_linters`.
- Added 12 custom rules grouped by concern:
  - **Arena Lifecycle**: `logd_document_retained_across_cycles`, `logd_missing_release_in_engine`, `logd_checkout_without_release`.
  - **Formatter/Decorator Purity**: `logd_formatter_performs_string_rendering`, `logd_decorator_not_immutable`, `logd_formatter_not_immutable`.
  - **Consumer Usage**: `logd_avoid_print_sink_in_production`, `logd_logtag_use_bitmask`, `logd_log_buffer_not_sunk`, `logd_handler_missing_engine`, `logd_metadata_set_duplicate`.
  - **Inheritance Configuration**: `logd_freeze_on_unconfigured_logger`.
