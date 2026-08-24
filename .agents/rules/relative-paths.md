---
trigger: always_on
---

# Relative Paths Only

Always use relative paths instead of full absolute paths across this repository and in all communication:

1. **User Communication & Documentation**: In all text responses, markdown links, code comments, documentation, and commit messages, refer to files using relative paths from the workspace root (e.g., `packages/logd/lib/src/...`, `.agents/rules/...`). Never use full absolute paths (e.g., `/home/ono/Projects/...`).
2. **Code & Scripts**: In shell scripts, Dart code, configuration files, and tests within this repository, never hardcode absolute filesystem paths. Always use paths relative to the project/package root.
3. **Markdown Links**: Render links using relative paths (e.g., `[file.dart](file://packages/logd/lib/src/file.dart)` or `[file.dart](packages/logd/lib/src/file.dart)`).
