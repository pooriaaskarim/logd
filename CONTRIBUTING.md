# Contributing to logd

Thank you for considering contributing to `logd`! We welcome contributions from the community to help improve this logging library for Dart and Flutter.

## Code of Conduct
By participating in this project, you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md). Please report unacceptable behavior to the project maintainers.

## Reporting Issues
- Before opening a new issue, check if a similar issue already exists in the [issue tracker](https://github.com/your-repo/logd/issues).
- Provide a clear title, detailed description, steps to reproduce, expected vs. actual behavior, and relevant logs or screenshots.
- Use labels (e.g., bug, enhancement, documentation) to categorize your issue.

## Feature Requests
- Open an issue with the "enhancement" label.
- Describe the feature, its use case, and why it would be valuable.
- If possible, include design ideas or code snippets.

## Pull Requests
We encourage pull requests for bug fixes, features, and improvements. Follow these steps:
1. **Fork the Repository**: Create your own fork of the project.
2. **Create a Branch**: Use a descriptive name (e.g., `feature/dynamic-inheritance` or `fix/timestamp-bug`).
3. **Make Changes**: Follow the coding guidelines below.
4. **Add Tests**: Ensure new features or fixes include unit tests. Run `dart test` to verify.
5. **Update Documentation**: If applicable, update README.md, API docs, or examples.
6. **Commit Messages**: Use clear, concise messages following [Conventional Commits](https://www.conventionalcommits.org) (e.g., `feat: add caching to config resolution`).
7. **Push and Open PR**: Push to your fork and submit a pull request to the main branch. Reference related issues (e.g., "Fixes #123").
8. **Review Process**: Be responsive to feedback. PRs may require rebasing or additional changes.

## Coding Guidelines
- **Style**: Follow Effective Dart guidelines. Use `dart format` to style code.
- **Testing**: Aim for high coverage. Use `dart test` and add tests for new code.
- **Documentation**: Add or update docstrings for public APIs. Follow existing style (concise, with intentions, parameters, how-to-use, examples).
- **Performance**: Consider efficiency, especially in hot paths like logging.
- **Dependencies**: Avoid adding new dependencies unless essential; discuss in an issue first.

## Setting Up Development Environment
1. Clone your fork: `git clone https://github.com/your-username/logd.git`
2. Install dependencies: `dart pub get`
3. Run tests: `dart test`
4. Build examples: Check the `example/` directory.

## Questions?
If you have questions, open an issue or join discussions in the repository.

Thanks for contributing!
