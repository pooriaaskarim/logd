# Stack Trace Design Philosophy

## Caller Detection Priority

**Goal**: Extract the user's code location rather than library internals.

**Problem**: Standard stack traces include frames from the logging library itself. For example:
```
#0 Logger._log (package:logd/logger.dart:123)
#1 Logger.info (package:logd/logger.dart:456)
#2 MyService.processRequest (package:myapp/service.dart:78)
```

The relevant frame is #2, not #0 or #1.

**Implementation**: The parser iterates frames, skipping those matching configured package filters (e.g., `package:logd/`) until finding user code.

## Defensive Parsing

**Principle**: Parsing failures must not break logging.

**Rationale**: Stack trace format may vary across:
- Dart VM versions
- Platform differences (VM vs Web vs AOT)
- Obfuscation in release builds

**Behavior**: If regex matching fails or produces malformed data, `extractCaller()` returns `null` rather than throwing exceptions. The logging pipeline continues with degraded information rather than crashing.
