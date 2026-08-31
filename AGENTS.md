# ImageBench Agent Guide

This file applies to the entire repository. It is the operating guide for coding agents and humans using agentic development tools in ImageBench.

## Mission

ImageBench is a native, offline-first macOS image utility. Changes should preserve the qualities that make it trustworthy for large personal photo libraries:

- never modify source images;
- remain useful without a network connection;
- use native macOS frameworks and interaction patterns;
- keep long-running work cancellable and off the main thread;
- prefer deterministic output and explicit errors over silent recovery;
- ship command-line dependencies inside the release app;
- keep behavior covered by repeatable tests.

The current product phase prioritizes correctness, operational stability, accessibility, and release readiness. The Gallery Workbench visual system is implemented; extend its semantic primitives instead of introducing one-off colors, cards, or navigation patterns.

## Start Here

Read these files before making substantial changes:

1. `README.md` for product scope and quick-start instructions.
2. `DOCUMENTATION.md` for the documentation map and update responsibilities.
3. `DEVELOPMENT.md` for architecture, data flows, and release mechanics.
4. `CONTRIBUTING.md` for contribution and AI-assisted-development expectations.
5. `CHANGELOG.md` for shipped history and current Unreleased work.
6. `VERSIONING.md` before changing bundle versions, builds, tags, or release artifacts.
7. `ROADMAP.md` for product sequencing, release work, and future phases.
8. `Design/UI_DESIGN_SYSTEM.md` before changing any user-facing interface.
9. `CODE_STYLE.md` for module boundaries, naming, comments, reuse, and automated style checks.

## Documentation System

`DOCUMENTATION.md` defines which file owns each kind of knowledge. Keep the ecosystem connected instead of duplicating policy across Markdown files.

- Add qualifying user-visible, performance, accessibility, packaging, or contributor-contract changes to the **Unreleased** section of `CHANGELOG.md`.
- Follow `VERSIONING.md` whenever a version, build number, Git tag, artifact name, or release note changes.
- Do not bump versions, create tags, or publish releases unless the user or release owner explicitly requests it.
- Keep roadmap intent separate from changelog fact: planned work belongs in `ROADMAP.md`; completed outcomes belong in `CHANGELOG.md`.
- Update `DOCUMENTATION.md` and the README documentation list when adding a long-lived Markdown guide.
- Prefer links to the owning document over copied instructions that can drift.

## Ground-Truth Commands

Run from the repository root:

```sh
Scripts/lint.sh
swift test --disable-sandbox
swift test -c release --disable-sandbox
Scripts/package-app.sh
Scripts/smoke-test-app.sh
```

The complete verification path is:

```sh
Scripts/test-all.sh
```

That command fetches pinned test dependencies when necessary, runs debug and optimized tests, packages the offline app, and smoke-tests the resulting bundle.

Some headless or restricted agent sandboxes block Core Image rendering even when Swift Package Manager's sandbox is disabled. If color/pixel tests return transparent black images only inside such an environment, rerun the same test command with normal macOS process/GPU access before changing production rendering code.

## Architecture Boundaries

- `Sources/ImageBench/Tools/*View.swift` owns presentation and user interaction.
- View models own observable state and task lifecycles, and are `@MainActor` isolated.
- Engines contain image-operation behavior and should remain usable from tests without UI.
- `ImageRenderer` owns Core Image/ImageIO rendering and export.
- `ProcessRunner` owns subprocess execution, output capture, and cancellation.
- `DependencyManager` owns bundled-tool discovery and development fallbacks.
- `CompressionInputScanner` owns recursive compressor discovery and output-folder exclusion.
- Tests generate their own fixtures; do not commit personal photos or large binary fixtures.

Do not move processing logic into SwiftUI views. Do not call `Process` directly from a tool view or view model; extend the process service instead.

Do not create catch-all `Utils.swift`, `Common.swift`, or `Models.swift` files. Put reusable behavior under the narrowest shared responsibility and keep feature-specific behavior with its tool. Extract stable concepts and invariants, not merely similar-looking syntax.

## Non-Negotiable Invariants

### Files and privacy

- Inputs are read-only.
- Outputs use collision-safe names; never overwrite an existing file silently.
- Single-image exports use the shared atomic writer and reject an output path that resolves to the selected input.
- Temporary files live in a uniquely named directory and are cleaned up.
- No telemetry, advertising, analytics, or implicit network requests.
- Do not log image contents or metadata values. Exact commands may be logged because users need operational transparency.

### Compressor

- `cjpeg` receives a binary PPM, not JPEG or ImageIO-generated BMP.
- Transparent source pixels are flattened onto white before JPEG encoding.
- `removeAllMetadata` skips metadata copying entirely.
- Metadata preservation and selective removal use ExifTool after encoding.
- Preset CLI arguments are API-like behavior; update their tests when intentionally changing them.
- A failed encoder must not leave a partial destination file.
- Supported discovery extensions are JPEG/JPG, PNG, HEIC/HEIF, TIFF, BMP, GIF, and WebP; format changes must update discovery, conversion, picker behavior where relevant, documentation, and battle tests together.
- A per-file decode, encoder, or metadata failure must not abort remaining batch inputs.
- Cancellation must distinguish completed, failed, and untouched/skipped inputs.
- Compression must pass executable, output-write, and disk-headroom preflight before work begins.

### Splitter, filler, and watermarking

- Split parts collectively cover every source pixel once; remainder pixels must not be discarded.
- Part numbering is deterministic and top-to-bottom or left-to-right.
- Preserve the source format for splitter output.
- Reject slice counts that cannot produce non-empty images.
- Reject non-finite or dangerously large aspect-ratio canvases before rendering.
- Respect source orientation through the normalized-image path.
- Watermark placement and size are stored as normalized values, not source pixels.
- Preview and export must use the same `WatermarkLayout` geometry.
- A watermark preset is committed only after its corresponding export succeeds.
- Image watermark presets use app-managed copies in Application Support; do not depend on the original selected asset path.
- Replacing a preset must not delete the previous managed asset until the new manifest is durable.

### EXIF and RAW inspection

- EXIF viewing is read-only; never rewrite or normalize the selected source.
- Do not log metadata values, including location, serial number, owner, or maker-note content.
- RAW support is local and codec-dependent. Recognize documented common extensions, use installed ImageIO codecs, and report unsupported camera generations explicitly without network fallback.
- Generate preview thumbnails and histograms off the main actor with bounded dimensions and cancellation checks.

### Dependencies and packaging

- Release builds prefer bundled tools over Homebrew tools.
- Bundled `cjpeg` must not link to `/opt/homebrew` or `/usr/local` libraries.
- Dependency versions are pinned in `Scripts/fetch-dependencies.sh`.
- Bundled dependency license notices must be copied into the release app.
- End-user network access is not a runtime requirement.
- Changes to packaging, dependencies, `Info.plist`, or resource lookup require the bundle smoke test.

## Test Expectations

Add or update the smallest relevant test, then run broader verification proportional to the change:

| Changed area | Minimum test scope |
| --- | --- |
| Presets or compressor arguments | `CompressionOptionsTests` and `CompressorIntegrationTests` |
| Metadata behavior | All metadata integration tests with ExifTool |
| Process execution/cancellation | `ProcessRunnerTests`, including large output |
| File scanning | `CompressionInputScannerTests` |
| Split geometry or naming | `SplitterTests` |
| Fill composition/export | `AspectFillerTests` and `ImageRendererTests` |
| Watermark rendering or placement | `WatermarkEngineTests` and `ImageRendererTests` |
| Watermark preset persistence | `WatermarkPresetStoreTests` |
| EXIF grouping, histogram, or RAW recognition | `ExifViewerTests` and `FileSupportTests` when shared formats change |
| Dependency discovery/packaging | Full suite plus `Scripts/smoke-test-app.sh` |
| Batch resilience or preflight | `CompressionPreflightTests` and `CompressorIntegrationTests` |
| Large-batch performance | `CompressorScaleTests` and `Scripts/run-benchmarks.sh` |
| Supported formats or mixed folders | `CompressorBattleTests`, `CompressionInputScannerTests`, and `FileSupportTests` |
| Cross-cutting refactor | `Scripts/test-all.sh` |

Tests must not depend on image files in a developer's Pictures folder, existing app state, a specific username, or network access after dependencies are fetched.

## Agent Workflow

1. Inspect the relevant engine, UI, and tests before editing.
2. State assumptions when requirements are ambiguous.
3. Make focused changes that preserve the boundaries above.
4. Add a regression test first when fixing a reproducible bug.
5. Run the narrow test during iteration.
6. Run debug and release tests before declaring a functional change complete.
7. Rebuild and smoke-test the app for release-facing changes.
8. Update the changelog and owning documentation when the change meets the documentation matrix.
9. Report what changed, what was verified, and any remaining risk.

Agents may use AI-generated code, designs, or tests, but the submitted result must be reviewed, understandable, and owned by the contributor. Never weaken assertions or skip tests merely to make a build green.

## UI Work

UI evolution should begin with evidence and shared primitives:

- treat `Design/UI_DESIGN_SYSTEM.md` as the normative cross-screen UI contract;
- capture the current flows and audit usability/accessibility;
- extend semantic color, spacing, typography, material, radius, and motion tokens in `DesignSystem.swift`;
- support system, light, and dark appearances without duplicating screens;
- keep controls native and keyboard/VoiceOver accessible;
- preserve all engines and their tests while iterating on presentation;
- update the text record in `design-qa.md` for meaningful visual changes; keep generated screenshots outside the repository unless the repository owner explicitly approves a durable reference;
- add snapshot or focused UI tests as the visual system matures.

For agentic UI work, use an audit → visual exploration → implementation → visual QA loop. Do not replace native SwiftUI/AppKit with Electron or a web view for styling convenience.

## Definition of Done

A change is complete when behavior is implemented, errors are understandable, cancellation and cleanup are preserved, tests cover the new behavior, required verification passes, qualifying work is recorded under `CHANGELOG.md` **Unreleased**, owning documentation is updated when contracts change, and the release remains offline-capable.
