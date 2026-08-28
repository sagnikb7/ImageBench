# ImageBench Developer Guide

This guide explains how ImageBench is assembled, how its processing pipelines behave, and how to develop it safely. It complements the concise setup in `README.md` and the contribution rules in `CONTRIBUTING.md`.

## Technology

- Swift Package Manager project, openable directly in Xcode
- SwiftUI application shell and tool interfaces
- AppKit for `NSOpenPanel` and `NSSavePanel`
- Core Image for orientation-aware composition, scaling, and blur
- ImageIO for decoding, format inspection, and export
- Foundation `Process` for bundled mozjpeg and ExifTool execution
- XCTest for unit, integration, cancellation, pixel, metadata, and geometry coverage

The deployment target is macOS 14. The package uses Swift tools 6.1 while compiling the app target in Swift 5 language mode to keep concurrency migration controlled and explicit.

## Repository Layout

```text
Package.swift
Sources/ImageBench/
  ImageBenchApp.swift
  ContentView.swift
  Resources/
  Services/
    DependencyManager.swift
    ImageRenderer.swift
    ProcessRunner.swift
  Shared/
    AppSurfaces.swift
    DesignSystem.swift
    Formatting.swift
    WorkspaceComponents.swift
    Files/
      FilePanels.swift
      ImageFileSupport.swift
      ImageSelectionValidator.swift
      CompressionInputScanner.swift
      WorkspaceFileActions.swift
  Tools/
    Compressor/
    Watermark/
    Splitter/
    Filler/
    Exif/
Tests/ImageBenchTests/
Scripts/
Packaging/Info.plist
.github/workflows/ci.yml
```

Views should be thin. View models coordinate tasks and state. Engines implement operations. Services own platform integration shared across tools.

`CODE_STYLE.md` is the normative guide for dependency direction, module placement, naming, extraction decisions, comments, and source-quality automation.

## Application Structure

`ImageBenchApp` creates a single `DependencyManager` and injects it into the view hierarchy. `ContentView` uses the native Gallery Workbench shell to select one of five tools.

`ContentView` also owns the five tool view models. Sidebar navigation swaps only the visible view, so tool state, decoded previews, and active cancellable work survive module changes. Do not move those models back into conditional child views: doing so recreates the tool on every selection and makes navigation feel slow.

Each long-running tool follows the same shape:

```text
SwiftUI view
  → @MainActor view model
    → cancellable task
      → engine/service running outside UI work
        → file or Process output
      → MainActor progress updates
```

Keep new tools consistent with that ownership model. It makes cancellation, testing, and UI redesign possible without entangling processing behavior.

Interactive preview work must stay off the main actor. Aspect Filler keeps a decoded source in its preview renderer, watermark text changes are briefly debounced, compressor thumbnails and EXIF histograms use bounded asynchronous ImageIO decoding, and the command log buffers exact output while coalescing visible updates. These are responsiveness contracts, not optional micro-optimizations.

## Compressor Pipeline

The compressor intentionally separates pixel encoding from metadata policy:

```text
JPEG / JPG / PNG / HEIC / HEIF / TIFF / BMP / GIF / WebP
  → Core Image decode + orientation normalization
  → opaque RGB binary PPM temporary file
  → bundled mozjpeg cjpeg
  → JPEG output
  → optional ExifTool metadata copy/removal
```

Why PPM? `cjpeg` is an encoder and does not accept JPEG as a decoded source. ImageIO-generated BMP files can also use variants that mozjpeg's BMP reader interprets incorrectly. Binary PPM is simple and deterministic. Transparent PNG pixels are composited over white while producing the opaque PPM.

Metadata behavior is:

| Selection | Encode behavior | ExifTool behavior |
| --- | --- | --- |
| Keep metadata | Fresh JPEG | Copy all supported tags from source |
| Remove GPS | Fresh JPEG | Copy tags, then remove GPS group |
| Remove EXIF | Fresh JPEG | Copy tags, then remove EXIF group |
| Remove all | Fresh JPEG | Skip metadata copy |

The UI log shows the actual executable and arguments. The app does not execute a shell command string, so filenames containing spaces or quotes remain safe.

When the user has not chosen a destination, the compressor derives a `Compressed Output` folder inside the current input folder. This is only a planned URL while selecting and scanning; changing the input moves the automatic destination, while an explicitly chosen destination is preserved. Before encoding, `CompressionPreflight` verifies the selected binaries, creates and write-probes the output folder, and checks conservative output and temporary-disk estimates. During a run, a per-file decode, encoder, or metadata failure is recorded and processing continues. Cancellation returns a partial `CompressionBatchResult`: completed files remain, the active partial output is removed, and untouched inputs are reported as skipped.

## Process Execution

`ProcessRunner` redirects stdout and stderr to unique temporary files rather than bounded pipes. This prevents subprocess deadlocks when a tool emits more data than a pipe buffer can hold. `CancellableProcessRunner` tracks its active process behind a lock and terminates it when the Swift task is cancelled.

When changing this code, preserve these cases:

- large stdout and stderr are fully captured;
- non-zero exit status and both streams are reported;
- an executable that cannot launch throws;
- cancellation terminates promptly;
- the runner can be reused after cancellation;
- output-capture temporary directories are removed.

## Dependency Resolution

Release behavior prefers deterministic app-owned tools:

1. repaired tools in Application Support;
2. binaries bundled in `ImageBench.app`;
3. Homebrew's keg-specific paths for development;
4. limited PATH-style fallbacks where applicable.

`Scripts/fetch-dependencies.sh` builds a static mozjpeg executable for the current architecture and copies the pinned ExifTool script plus Perl modules. `Scripts/package-app.sh` embeds them in the app and signs the bundle.

The release smoke test rejects a `cjpeg` linked to Homebrew paths. Do not package `/opt/homebrew/opt/mozjpeg/bin/cjpeg` directly; its dependent libraries will not exist on another Mac.

## Image Scanner

`CompressionInputScanner` recursively finds JPEG/JPG, PNG, HEIC/HEIF, TIFF, BMP, GIF, and WebP files. It skips hidden files, package descendants, and the selected output directory. Excluding the output directory prevents a later scan from recompressing earlier results.

The scanner is cancellation-aware and returns naturally sorted paths. If new formats are added, update `ImageFileSupport`, picker types, engine behavior, and scanner tests together.

## Splitter

The splitter normalizes source orientation, calculates integer boundaries, and allocates remainder pixels across parts. For a 101-pixel image split into three columns, the widths are 33, 34, and 34; no source pixel is dropped.

Horizontal parts are named from top to bottom. Vertical parts are named from left to right. The engine accepts 2–12 slices and also rejects a count above the number of pixels on the split axis. Keeping the product limit in `SplitterEngine`, rather than only in the Stepper, protects programmatic callers and future interfaces.

## Aspect-Ratio Filler

The filler expands one canvas dimension while leaving the original image uncropped and centered. Solid backgrounds are generated as opaque Core Image canvases. Blur mode aspect-fills a scaled source behind the original, clamps its extent, applies Gaussian blur, and crops to the target. The inspector reports the selected image's dimensions, simplified aspect ratio, and decimal ratio.

The 16:10 and 12:5 presets are preparation canvases for seamless Instagram sets. Splitting 16:10 into two equal columns yields two 4:5 images; splitting 12:5 into three yields three 4:5 images. This is arithmetic, not an Instagram upload API dependency, and processing remains offline.

Custom ratios are normalized to a finite supported range. The engine also rejects canvases over 32,768 pixels on either axis or 150 million total pixels, preventing accidental multi-gigabyte allocations.

Filler export uses `ImageRenderer.writeAtomically`: it renders to a sibling temporary file, checks cancellation, and only then moves or replaces the selected destination. The shared writer rejects an output URL that resolves to the input URL, so choosing the original filename cannot modify the source. Watermark Studio uses the same path. Preview generations prevent an older cancelled render from clearing or replacing a newer preview.

## Watermark Studio

Watermark Studio separates editor state, rendering, and durable presets:

```text
selected JPEG / PNG / HEIC
  + text rendered with Core Text, or decoded watermark image
  + normalized size, opacity, and top-left-origin center position
  → Core Image composition at source resolution
  → temporary high-quality output
  → atomic destination replacement or move
  → selected preset slot saved after export succeeds
```

`WatermarkLayout` is shared by preview and export. It stores the watermark center and width as fractions of the source canvas rather than pixels, keeping a preset visually consistent across different image sizes. It also clamps the overlay inside the canvas and scales unusually tall assets to a safe height.

The four-slot `WatermarkPresetStore` writes a versioned JSON manifest under `~/Library/Application Support/ImageBench/Watermarks`. Image-watermark files are copied into its `Assets` directory before the manifest is committed. Application Support is intentionally used instead of the system cache directory because macOS may purge cache data; a user-authored preset must be durable. Replacing or deleting a preset commits the new manifest before removing its superseded managed asset. Reset All commits an empty manifest before best-effort asset cleanup.

Watermark assets are decoded and previewed off the main actor through the same Core Image path used by export. Exports also run away from the main actor, observe cancellation before composition and final placement, and use the shared atomic image writer. The writer refuses source/destination path collisions and removes its sibling temporary file on failure or cancellation. A preset is updated only after the output file succeeds, so failed or cancelled exports never silently replace a known-good preset. Asset loading and preset loading cancel stale requests before applying state.

Text watermark preview and export share the same Core Text path and use Arial. Keeping the font name in the engine prevents the editor field, preview, and exported pixels from drifting.

## EXIF Viewer

The EXIF Viewer is a read-only inspection pipeline:

```text
selected standard image or recognized RAW container
  → ImageIO source and metadata dictionaries
  → transformed preview thumbnail capped at 1,400 pixels
  → histogram sample capped at 320 pixels on its longest edge
  → logical metadata sections on the main actor
```

`ExifFileSupport` recognizes common Canon, Nikon, Sony, Fujifilm, Olympus, Panasonic/Leica, Pentax, and DNG extensions. Recognition does not imply that every camera generation can be decoded: actual RAW preview and metadata support comes from the ImageIO codecs installed with the user's macOS version. Missing codec support is reported explicitly and never triggers a network lookup or external conversion.

`ExifViewerEngine` groups file, image, capture, camera/lens, exposure, location, rights/workflow, and RAW/maker-note fields. It does not mutate the selected file or log metadata values. Preview decoding and histogram calculation run outside the main actor, are cancellation-aware, and use bounded images so large camera originals do not become unbounded UI work. Selection generations prevent a late inspection from replacing a newer file.

## Concurrency and Cancellation

- Observable UI state belongs to `@MainActor` view models.
- Directory scans and image operations run in detached or asynchronous work.
- Engines call `Task.checkCancellation()` inside per-file or per-row loops.
- Process cancellation terminates the current subprocess.
- `ImageRenderer.writeAtomically` protects source paths and avoids partial replacement for single-image exports.
- Completed output files remain after a bulk cancellation; incomplete output is deleted on command failure.

When adding a long loop, add cancellation checks at a useful granularity. When adding a task wrapper, make sure cancellation reaches any detached child task.

## Tests

The suite creates images and metadata fixtures dynamically. It does not depend on private photos or committed binary assets.

Test groups:

- `CompressionOptionsTests`: preset-to-argument contracts
- `CompressionPreflightTests`: dependencies, permissions, disk estimates, and capacity errors
- `CompressionLogBufferTests`: exact ordering, empty updates, and buffer reuse
- `CompressorIntegrationTests`: real mozjpeg and ExifTool operations
- `CompressorScaleTests`: a 1,200-file scan and an opt-in 200-image encode benchmark
- `CompressorBattleTests`: mixed-format folders, unrelated files, corrupt inputs, nested output exclusion, Unicode/quoted paths, duplicate stems, and uppercase HEIC/HEIF
- `CompressorViewModelTests`: lazy output selection and explicit-destination preservation
- `ProcessRunnerTests`: output, errors, stress, cancellation, reuse
- `CompressionInputScannerTests`: recursion, sorting, exclusions, cancellation
- `SplitterTests`: geometry, order, naming, formats, HEIC
- `AspectFillerTests`: ratios, pixels, blur, exports, safety limits
- `WatermarkEngineTests`: normalized layout, text and image rendering, opacity, source protection, and export
- `WatermarkPresetStoreTests`: four-slot validation, manifest round-trips, durable copied assets, and replacement cleanup
- `WatermarkViewModelTests`: initial preset loading, empty-slot reset, confirmed preset deletion/reset behavior, and navigation-state preservation
- `ExifViewerTests`: metadata grouping, RAW-extension recognition, bounded normalized histograms, and unsupported formats
- `ImageRendererTests`: rendering, previews, exports, corrupt input
- `FileSupportTests`: extensions, sizes, collision names, command display quoting

Run a single class while iterating:

```sh
swift test --disable-sandbox --filter SplitterTests
```

Run formatting and lint checks:

```sh
Scripts/lint.sh
```

Run all debug tests:

```sh
swift test --disable-sandbox
```

Run the release-optimized suite:

```sh
swift test -c release --disable-sandbox
```

Run everything, including packaging:

```sh
Scripts/test-all.sh
```

Run scale benchmarks explicitly so routine test runs remain fast:

```sh
Scripts/run-benchmarks.sh
```

Core Image needs normal macOS rendering access for pixel assertions. A restrictive outer automation sandbox may return transparent black frames even though SwiftPM's own sandbox is disabled. Confirm failures in a normal Terminal or Xcode environment.

## UI Design and Visual QA

The Gallery Workbench direction is implemented through semantic components in `Shared/DesignSystem.swift` and `Shared/WorkspaceComponents.swift`; tool views consume those tokens and layouts instead of defining isolated colors, cards, or workspace chrome. Its existing information architecture is a product constraint: visual work should refine contrast, alignment, controls, and density without replacing the established layout. `Design/UI_DESIGN_SYSTEM.md` is the normative guide for applying and extending those primitives. `SettingsView` persists System, Light, or Dark appearance, the startup module, and exposes confirmed watermark-preset cleanup. `AboutView` reads version/build metadata and bundled dependency versions without network access.

The flat coral photo-stack mark is shared by the sidebar, About surface, and packaged macOS icon. After changing that artwork, run `swift Scripts/generate-app-icon.swift` from the repository root to regenerate the SwiftPM resource and every asset-catalog size, then inspect both the 1,024-point source and the 16-point result before packaging.

The selected source mockup, implementation capture, combined comparison, and final report live under `Design/` and in `design-qa.md`. UI changes should repeat the audit → visual target → implementation → screenshot comparison loop and update the evidence when a visible contract changes.

For deterministic local screenshots, a development run can preload a photo folder and a synthetic mixed result state without modifying files:

```sh
IMAGEBENCH_DEMO_FOLDER=/path/to/photos \
IMAGEBENCH_DEMO_RESULT=1 \
swift run
```

These environment variables only prepare UI state; they never start compression.

## Building and Packaging

Development:

```sh
swift run
```

Release app:

```sh
Scripts/package-app.sh
Scripts/smoke-test-app.sh
```

Developer ID signing:

```sh
SIGNING_IDENTITY="Developer ID Application: Your Company (TEAMID)" Scripts/package-app.sh
```

Notarization is intentionally left to the release owner because it requires Apple credentials. The generated app is otherwise complete and offline-capable.

After storing an App Store Connect credential profile with `xcrun notarytool store-credentials`, notarize and staple a Developer ID build with:

```sh
NOTARY_PROFILE=ImageBenchNotary Scripts/notarize-app.sh
```

GitHub Actions runs on every push and pull request using `macos-15` Apple Silicon and `macos-15-intel` runners. Each matrix job runs lint, debug and optimized tests, packaging, and the bundle smoke test. It then archives the app with `ditto` and uploads a versioned `ImageBench-<version>-macos-<architecture>.zip` artifact. The ZIP preserves the macOS bundle structure; CI artifacts remain ad-hoc signed until the release owner supplies signing and notarization credentials.

The push/PR workflow needs no repository secrets because it produces test artifacts with an ad-hoc signature. Once `.github/workflows/ci.yml` is pushed, GitHub discovers it automatically; progress and downloadable artifacts appear under the repository's Actions tab. The first remote run must pass on both runners before its output is treated as release evidence.

## Adding a New Tool

1. Create a folder under `Sources/ImageBench/Tools/`.
2. Define plain models for options and job snapshots.
3. Implement a UI-independent engine.
4. Add an `@MainActor` view model for selection, progress, and cancellation.
5. Build the SwiftUI screen with native semantics and keyboard accessibility.
6. Add the tool to `AppTool` and `ContentView`.
7. Add generated-fixture unit and integration tests.
8. Use the update matrix in `DOCUMENTATION.md`; record qualifying work under `CHANGELOG.md` **Unreleased**.

## Debugging Common Failures

### `Empty BMP image`

This indicates an obsolete build that still used BMP as the compressor bridge. Current builds use binary PPM. Rebuild `dist/ImageBench.app` and fully quit the older running process before relaunching.

### Dependencies appear ready but encoding differs by machine

Confirm the packaged app is selecting its bundled tools. Run `Scripts/smoke-test-app.sh` and inspect the executable path in the compressor console.

### Pixel tests are transparent black only in an agent sandbox

Rerun outside the outer sandbox with normal Core Image access. Do not weaken pixel assertions until the failure reproduces in Xcode or Terminal.

### Integration tests skip

Run `Scripts/fetch-dependencies.sh`, or use `Scripts/test-all.sh`, to install the pinned test tools under `Vendor/Tools`.

### Package works locally but not on another Mac

Check `otool -L` on bundled `cjpeg`; no Homebrew path should appear. Also verify ExifTool's `lib/Image` directory exists in the app resources.

## Release Checklist

- The release procedure and version choice follow `VERSIONING.md`.
- The release artifact is built from an identifiable reviewed commit, and the final tag points to that commit.
- Debug and release tests pass.
- The app is rebuilt after the final source change.
- Bundle smoke test passes.
- Version and build values in `Packaging/Info.plist` are correct.
- The matching `CHANGELOG.md` section is dated and **Unreleased** is reset for future work.
- Dependency pins and archive checksums are intentional, documented, and verified before extraction.
- The mixed-input compressor battle tests pass.
- Visible UI changes have current screenshot comparison evidence.
- Both Apple Silicon and Intel CI jobs upload correctly named ImageBench artifacts.
- Developer ID signature and notarization are complete for public binaries.
- MIT and bundled dependency notices are present in the repository and app bundle.
- Release notes are derived from the matching changelog section and describe migration concerns.
- The repository has an explicitly chosen open-source `LICENSE` before public launch.
