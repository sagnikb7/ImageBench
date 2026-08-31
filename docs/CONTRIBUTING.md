# Contributing to ImageBench

ImageBench welcomes human-written, AI-assisted, and agent-authored contributions. The standard is the same for all of them: understandable changes, preserved privacy guarantees, appropriate tests, and clear ownership by the contributor.

## Before You Start

- Read the [agent guide](../AGENTS.md), [documentation map](README.md), and [developer guide](DEVELOPMENT.md).
- Read the [code quality guide](CODE_STYLE.md) before implementation or refactoring.
- Read the [changelog](../CHANGELOG.md) and [versioning policy](VERSIONING.md) when a change is user-visible or release-related.
- Read the [UI design system](../Design/UI_DESIGN_SYSTEM.md) before changing user-facing UI.
- Search existing issues and pull requests before opening overlapping work.
- For significant behavior or architecture changes, open an issue describing the problem and proposed direction first.
- Keep visual redesign work aligned with the [roadmap](ROADMAP.md) so the app gains one coherent design system rather than isolated styles.

## Development Setup

You need macOS 14 or newer and Xcode 16.3 or a newer compatible Swift 6.1 toolchain.

```sh
git clone git@github.com:sagnikb7/ImageBench.git
cd ImageBench
swift test --disable-sandbox
swift run
```

For real mozjpeg and ExifTool integration tests:

```sh
Scripts/fetch-dependencies.sh
```

For the entire verification pipeline:

```sh
Scripts/test-all.sh
```

Run the fast source-quality gate while iterating:

```sh
Scripts/lint.sh
```

## Good Contributions

- reproducible bug fixes with regression tests;
- performance improvements measured on representative images;
- accessibility and keyboard-navigation improvements;
- format support implemented consistently across picker, scanner, engine, and tests;
- clearer error recovery and dependency diagnostics;
- reusable design-system improvements that extend the established Gallery Workbench language;
- documentation that helps users or contributors complete a real task.

Avoid unrelated rewrites, new runtime network dependencies, telemetry, silent overwrites, and changes that bypass the tested engines.

## Pull Requests

Keep pull requests focused. Include:

- the user-facing problem;
- the chosen approach and important tradeoffs;
- screenshots or a short recording for UI changes;
- tests added or updated;
- exact verification commands run;
- known limitations or follow-up work.

PR checklist:

- [ ] Inputs remain untouched and output naming remains collision-safe.
- [ ] Offline behavior is preserved.
- [ ] Long work remains asynchronous and cancellable.
- [ ] New behavior has deterministic tests.
- [ ] Debug tests pass.
- [ ] Release tests pass for cross-cutting changes.
- [ ] Packaging smoke test passes for dependency or release changes.
- [ ] Documentation reflects changed contracts.
- [ ] Qualifying user-visible work is recorded under [CHANGELOG.md](../CHANGELOG.md) **Unreleased**.
- [ ] Version metadata follows the [versioning policy](VERSIONING.md); no unrequested tag or release was created.
- [ ] `Scripts/lint.sh` passes and new abstractions follow the [code quality guide](CODE_STYLE.md).
- [ ] UI changes support keyboard use, VoiceOver labels, contrast, and reduced motion.
- [ ] UI changes follow the [UI design system](../Design/UI_DESIGN_SYSTEM.md) and include visual comparison evidence when material.

## AI-Assisted Contributions

AI tooling is encouraged when it helps contributors understand and improve the project. Please:

- review every generated change;
- understand the code well enough to maintain it;
- mention material AI assistance in the PR description;
- include the verification evidence, not merely a claim that an agent tested it;
- avoid pasting secrets, private photos, signing credentials, or user metadata into external models;
- never ask an agent to disable a failing test without understanding the failure.

A useful agent handoff contains the objective, affected files, constraints from the [agent guide](../AGENTS.md), test results, and remaining uncertainty.

## Reporting Bugs

Include macOS version, Mac architecture, ImageBench version, selected tool and options, input format, whether the bundled or development build was used, and the relevant console output. Do not attach private source images or unredacted location metadata unless you intentionally choose to publish them.

For security or privacy issues, do not open a public issue containing exploit details or personal data. Contact the future security address documented by the repository owner once public hosting is configured.

## License

ImageBench is released under the MIT License. By contributing, you agree that your contribution is provided under that license. Do not remove or alter the notices for bundled third-party components.
