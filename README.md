# ImageBench

[![ImageBench CI](https://github.com/sagnikb7/ImageBench/actions/workflows/ci.yml/badge.svg)](https://github.com/sagnikb7/ImageBench/actions/workflows/ci.yml)

ImageBench is a native, offline-first image utility for macOS. It combines bulk mozjpeg compression, reusable text and image watermarks, equal image splitting, aspect-ratio canvas filling, and local EXIF/RAW inspection in one SwiftUI application.

The project is designed around a simple trust model: source images are never modified, outputs are never silently overwritten, processing remains available offline, and the exact external commands are visible to the user.

ImageBench now includes the Gallery Workbench interface: a modern native workspace with semantic light/dark styling, drag-and-drop, richer previews, durable result summaries, Settings, and About surfaces. The processing core, offline packaging, and 111-test suite remain the source of truth for behavior.

Current source release: **0.3.0 (build 3)**.

## Features

### Bulk Photo Compressor

- Recursively scans JPEG/JPG, PNG, HEIC/HEIF, TIFF, BMP, GIF, and WebP files
- Uses pinned mozjpeg `cjpeg` for JPEG output
- Includes archive, web, maximum-compression, and custom presets
- Offers Custom JPEG quality from 0–100 in clear five-point steps
- Preserves metadata or removes GPS, EXIF, or all metadata
- Handles transparent PNG conversion by flattening onto white
- Shows exact commands, current file, progress, and completion size
- Continues after individual file failures and reports succeeded, failed, and skipped files
- Supports cancellation, retry-ready failed-file data, and failed partial-output cleanup
- Preflights executable availability, output permissions, and disk headroom
- Protects existing files with collision-safe output names

### Image Splitter

- Splits into 2–12 horizontal rows or vertical columns
- Preserves JPEG, PNG, and HEIC formats
- Distributes remainder pixels without dropping source content
- Names parts deterministically from top-to-bottom or left-to-right
- Provides a visual slice overlay and cancellable processing
- Compares the source dimensions and aspect ratio with each resulting row or column, including remainder-pixel ranges
- Shows preparation hints for two- and three-panel Instagram layouts

### Watermark Studio

- Adds either editable text or an image watermark to a photo
- Supports direct drag placement plus relative size and opacity controls
- Uses normalized placement so the same preset adapts to different image dimensions
- Provides four persistent preset slots that update after a successful export
- Lets users reset the selected preset or all presets with confirmation
- Starts new text watermarks with an editable `©` symbol that can be kept or removed
- Renders text watermarks in Arial for consistent preview and export typography
- Copies image-watermark assets into app-managed Application Support storage
- Keeps presets working if the originally selected signature file is moved or deleted
- Preserves JPEG, PNG, and HEIC output formats and never modifies the source
- Provides cancellable, high-quality, collision-conscious export

### EXIF Viewer

- Reads standard image metadata and popular camera RAW containers entirely on the Mac
- Recognizes DNG, CR2/CR3, NEF/NRW, ARW/SR2/SRF, RAF, ORF/ORI, RW2/RWL, and PEF/PTX files
- Organizes file, image, capture, camera/lens, exposure, location, rights, RAW, and maker-note data into readable groups
- Shows a bounded log-scale luminance and RGB histogram without modifying the selected file
- Validates embedded GPS coordinates and offers an explicit native map preview or Google Maps handoff
- Filters metadata by field name or value and reports an explicit codec error when macOS cannot decode a particular camera format

### Aspect-Ratio Filler

- Shows the selected image's dimensions and current aspect ratio
- Supports 1:1, 4:5, 9:16, 16:9, two-panel 16:10, three-panel 12:5, and custom ratios
- Uses white, black, or Gaussian-blurred fill
- Leaves the original image uncropped and centered
- Provides a live preview and high-quality export
- Provides cancellable, atomic export and refuses to overwrite the selected source
- Rejects unsafe canvas dimensions before allocating large images

## Why Native Swift

ImageBench uses SwiftUI, AppKit, Core Image, and ImageIO instead of shipping a browser runtime. This provides native file panels, accessibility semantics, color-managed rendering, familiar Mac interactions, and a compact application bundle.

AppKit is used where SwiftUI intentionally delegates to macOS, including `NSOpenPanel` and `NSSavePanel`. External tools are limited to the compressor's bundled mozjpeg and ExifTool executables.

## Privacy and Offline Operation

- No telemetry, analytics, advertising, or implicit background network calls
- No image uploads
- No modification of source images
- No manual dependency installation for users of the packaged app
- Bundled tools run locally and continue working without internet access
- EXIF map tiles and the Google Maps website are contacted only after the user explicitly opens them; metadata inspection itself stays local

Development and release packaging may use the network once to fetch pinned dependency source archives. The resulting `.app` is self-contained.

## Requirements

- macOS 14 or newer
- Xcode 16.3 or a newer compatible Swift 6.1 toolchain
- Xcode Command Line Tools
- CMake only when building the bundled mozjpeg dependency

## Quick Start

Clone the repository:

```sh
git clone git@github.com:sagnikb7/ImageBench.git
cd ImageBench
```

Open `Package.swift` in Xcode, select the **ImageBench** executable scheme and **My Mac**, then run.

From Terminal:

```sh
swift test --disable-sandbox
swift run
```

A development run can discover Homebrew's keg-specific mozjpeg and ExifTool paths. For deterministic integration tests and release packaging, fetch the pinned tools:

```sh
Scripts/fetch-dependencies.sh
```

## Testing

ImageBench currently has 111 XCTest cases covering:

- preset-to-CLI contracts;
- real mozjpeg JPEG encoding;
- ExifTool preservation and selective removal;
- JPEG/JPG, PNG, HEIC/HEIF, TIFF, BMP, GIF, WebP, and transparent-input pipelines;
- filenames containing spaces and quotes;
- collision-safe output and partial-failure cleanup;
- partial-batch recovery, cancellation summaries, write/disk preflight, and 1,200-file scanning;
- subprocess output stress, exit failures, cancellation, and reuse;
- recursive scanning, natural sorting, exclusions, and cancellation;
- splitter geometry, source/per-part ratio descriptions, formats, part ordering, and the enforced 12-slice limit;
- aspect-ratio geometry, solid and blurred pixels, exports, and allocation limits;
- watermark layout, text rendering, image composition, opacity, source protection, export, four-slot persistence, cached-asset replacement, and race-safe image-preset restoration;
- EXIF grouping, GPS validation/map-link generation, popular RAW-extension recognition, histogram normalization, unsupported files, and watermark preset reset behavior;
- corrupt files, atomic destination replacement, and source-overwrite protection;
- mixed six-format folders, non-image clutter, corrupt supported files, Unicode and quoted names, duplicate stems, nested output exclusion, and uppercase HEIC/HEIF.
- bundled Archivo Narrow registration and an opt-in disposable real-folder compression diagnostic.

Run debug tests:

```sh
swift test --disable-sandbox
```

Run optimized tests:

```sh
swift test -c release --disable-sandbox
```

Run the complete verification pipeline:

```sh
Scripts/test-all.sh
```

Run the opt-in 200-image subprocess benchmark separately:

```sh
Scripts/run-benchmarks.sh
```

`Scripts/test-all.sh` fetches missing pinned integration tools, runs debug and optimized tests, packages the app, verifies its signature and dependency linkage, and performs an actual encode using the bundled mozjpeg binary.

## Build the Offline App

```sh
Scripts/package-app.sh
Scripts/smoke-test-app.sh
open dist/ImageBench.app
```

The packager:

1. builds static mozjpeg for the current architecture;
2. bundles ExifTool and its Perl modules;
3. builds the optimized ImageBench executable;
4. assembles a native `.app` bundle;
5. signs it with an ad-hoc or supplied Developer ID identity.

For Developer ID signing:

```sh
SIGNING_IDENTITY="Developer ID Application: Your Company (TEAMID)" Scripts/package-app.sh
```

Public binary distribution also requires notarization using the release owner's Apple credentials:

```sh
xcrun notarytool store-credentials ImageBenchNotary
NOTARY_PROFILE=ImageBenchNotary Scripts/notarize-app.sh
```

## Automatic GitHub Builds

Every push and pull request runs the complete GitHub Actions pipeline on Apple Silicon and Intel macOS 15 runners. Each job checks formatting, runs debug and optimized tests, packages the offline app, performs the real bundle smoke test, and uploads a ZIP named like `ImageBench-0.3.0-macos-arm64.zip` or `ImageBench-0.3.0-macos-x86_64.zip`.

To download a successful build:

1. Open the repository's [Actions page](https://github.com/sagnikb7/ImageBench/actions).
2. Select the latest successful **ImageBench CI** run.
3. Download the required architecture from its **Artifacts** section.

CI artifacts are ad-hoc signed test builds. A public release download still requires the release owner's Developer ID signature and Apple notarization.

## Compressor Implementation Notes

`cjpeg` is an encoder and does not decode source images. ImageBench normalizes every supported compressor input through Core Image, writes a lossless opaque binary PPM temporary file, and passes that PPM to mozjpeg.

Metadata is handled separately:

- Keep metadata: copy supported source tags to the new JPEG with ExifTool.
- Remove GPS: copy metadata, then remove the GPS group.
- Remove EXIF: copy metadata, then remove the EXIF group.
- Remove all: skip metadata copying entirely.

The app passes executable paths and argument arrays directly to `Process`; the displayed shell-quoted command is for human-readable logging only.

## Project Structure

```text
Package.swift
Sources/ImageBench/
  ImageBenchApp.swift
  ContentView.swift
  Services/             dependency, process, and rendering services
  Shared/               design system, workspace components, formatting, and app surfaces
    Files/              format capabilities, scanning, panels, and Finder actions
  Tools/Compressor/     compression models, engine, view model, and view
  Tools/Watermark/      watermark models, preset store, engine, view model, and editor
  Tools/Splitter/       split engine, view model, and view
  Tools/Filler/         aspect composition, view model, and view
  Tools/Exif/           read-only metadata, RAW recognition, histogram, view model, and view
Tests/ImageBenchTests/  generated-fixture unit and integration tests
Scripts/                dependency, test, packaging, and smoke-test scripts
Packaging/Info.plist
.github/workflows/ci.yml
```

## Developer and Agent Documentation

- [DOCUMENTATION.md](DOCUMENTATION.md): map of the documentation ecosystem, ownership, and update triggers
- [AGENTS.md](AGENTS.md): repository rules and invariants for coding agents
- [CODE_STYLE.md](CODE_STYLE.md): module boundaries, reuse rules, naming, comments, and automated code-quality checks
- [DEVELOPMENT.md](DEVELOPMENT.md): architecture, pipelines, debugging, and releases
- [CONTRIBUTING.md](CONTRIBUTING.md): contribution and AI-assisted-development guidance
- [CHANGELOG.md](CHANGELOG.md): user-visible history and current Unreleased work
- [VERSIONING.md](VERSIONING.md): product versions, build numbers, tags, artifacts, and release procedure
- [Design/UI_DESIGN_SYSTEM.md](Design/UI_DESIGN_SYSTEM.md): normative visual, interaction, accessibility, and content rules
- [ROADMAP.md](ROADMAP.md): completed phases, distribution work, and future ideas
- [design-qa.md](design-qa.md): current text-only visual and interaction verification record
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md): bundled dependency versions and license notices

The project explicitly welcomes responsible AI-assisted development. Contributors remain responsible for reviewing generated work, understanding it, protecting private data, and providing real verification evidence.

The Instagram preparation hints are derived mathematically: a 16:10 canvas split into two equal columns produces two 4:5 images, while a 12:5 canvas split into three produces three 4:5 images. Platform upload rules can change, so verify current requirements before publishing.

## Contributing

Bug reports, tests, accessibility improvements, performance work, documentation, and focused features are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md) before starting substantial work.

GitHub Actions runs the debug suite, optimized suite, packaging process, and offline bundle smoke test for every push and pull request, then publishes versioned Apple Silicon and Intel test artifacts.

## Roadmap

The native Gallery Workbench redesign is implemented. The next release work is to clear the CI, accessibility, hardware-validation, and signing/notarization gates recorded in [ROADMAP.md](ROADMAP.md).

## License

ImageBench is open source under the [MIT License](LICENSE). Bundled Archivo Narrow, mozjpeg, and ExifTool components retain their own licenses; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
