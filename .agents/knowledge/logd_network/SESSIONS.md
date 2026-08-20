# logd_network — Session Logs

---

## 2026-08-20 — Satellite Extraction & Standalone Harness
- Scaffolded `packages/logd_network` with `pubspec.yaml`, `README.md`, `CHANGELOG.md`.
- Migrated source files (`network_sink.dart`, `http_server_sink_native.dart`, `http_server_sink_stub.dart`, `dashboard_html.dart`, `http_dashboard_handler.dart`).
- Implemented `registerLogdNetworkSerializers()` in `lib/src/serialization.dart`.
- Established standardized `example/` folder with interactive menu (`example/main.dart`) and 4 standalone showcases (`http_sink_showcase.dart`, `socket_sink_showcase.dart`, `http_server_sink_showcase.dart`, `http_dashboard_showcase.dart`).
- Migrated unit and live integration test suites (17 tests passing).
- Added soft deprecations (`@Deprecated` targeting `v0.10.0`) to core package and decoupled core examples.
- Documented migration guide in `doc/migration.md` and added `ADR-007`.
