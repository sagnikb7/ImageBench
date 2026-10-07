# Changelog

All notable user-facing changes to ImageBench are recorded here. This file follows the structure of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the release rules in [docs/VERSIONING.md](docs/VERSIONING.md).

Changes belong under **Unreleased** when they merge. A release moves those entries into a dated version section; do not rewrite previously published release history except to correct factual errors.

## Unreleased

### Changed

- Packaging now checks full Xcode setup before work begins and verifies a staged app before replacing the previous bundle. Bundle smoke tests support both SwiftPM resource layouts; build/setup instructions now appear near the top of the README.

- Bulk Compressor now creates a fresh `compressed_output`, `compressed_output_1`, etc. directory for each automatic export. Hidden ImageBench markers keep these directories out of future folder scans even after renaming; legacy `Compressed Output` folders remain excluded. Explicit destinations retain their current behavior.

## 0.3.1 - 2026-10-01

ImageBench 0.3.1 refines the native interface and organizes app information more clearly. Image processing and saved presets need no migration.

### Changed

- About now groups the GitHub repository, issue tracker, license, third-party notices, privacy details, and bundled-tool status. Settings contains only appearance, startup, and watermark-preset controls; both sheets scroll when needed.
- Reduced the coral sidebar ImageBench wordmark slightly for a calmer balance with its icon.
- Replaced the Custom compressor quantization stepper with a segmented choice for Default and tables 1–8.
- Made the Bulk Compressor size comparison a compact horizontal strip at regular widths, with a readable wrapped layout when space is limited.
- Refined the orange Fraunces wordmark and bundled Figtree interface typography. Watermark editing/export retains Arial. Removed the unused Archivo Narrow font and its license.

### Documentation

- Consolidated contributor, engineering, release, and roadmap guides under a linked `docs/` hub, paired UI rules with their QA record under `Design/`, and reduced root-level Markdown clutter.

## 0.3.0 - 2026-09-01

ImageBench 0.3.0 adds explicit photo-location map actions, live source-to-split aspect-ratio guidance, and clearer Custom compression quality control. Existing presets and source images require no migration.

### Added

- EXIF Viewer now validates embedded GPS coordinates, shows an explicitly opened native map preview, and can hand the location to Google Maps while keeping normal inspection local.
- Image Splitter now compares the selected image's dimensions and aspect ratio with the resulting per-row or per-column dimensions and ratio, including honest ranges when remainder pixels make parts differ.

### Changed

- Repository visual QA now keeps conclusions in a concise text record and leaves generated screenshots out of version control by default, removing obsolete duplicate audit trees and stale audit reports.
- Bulk Compressor's Custom quality control now uses a clear 0–100 scale in five-point steps while keeping the fixed preset recipes unchanged.
- EXIF map actions now render inside the Location metadata group directly beneath the coordinates they act on.
- New and reset text-watermark drafts now begin with an editable `©` symbol that users can keep or remove.
- Reworked the sidebar ImageBench wordmark with a condensed Archivo Narrow treatment and coral underscore, bundled locally under the SIL Open Font License.

### Fixed

- Added clearance around the Watermark Studio text editor so its native keyboard-focus ring is no longer clipped by the inspector scroll area.

## 0.2.0 - 2026-08-28

ImageBench 0.2.0 adds the offline EXIF/RAW inspection workflow and completes the current attention-to-detail, preset-management, branding, and launch-automation pass. Existing watermark presets remain compatible and no user migration is required.

### Added

- Added a read-only EXIF Viewer with local ImageIO metadata inspection, a bounded log-scale RGB/luminance histogram, filtering, logical metadata groups, and recognition for popular RAW camera extensions.
- Added a Startup preference for choosing the module ImageBench opens on the next launch and watermark-preset management in Settings.
- Added GitHub Actions builds for every push and pull request, producing versioned Apple Silicon and Intel ZIP artifacts after tests, packaging, and bundle smoke checks pass.

### Changed

- Changed text watermark preview and export typography to Arial.
- Added confirmed reset actions for the selected Watermark Studio preset and all four saved presets, including cleanup of app-managed watermark images.
- Removed repeated module icons from workspace headers while retaining them in the persistent sidebar navigation.
- Unified the sidebar brand mark, About artwork, and macOS app icon around the same coral photo-stack identity.
- Increased the padded close controls in Settings and About for a clearer circular target.
- Added consistent hover feedback and pointing cursors to enabled primary actions, sidebar navigation, upload wells, menus, and selectable option cards.
- Unified neutral hover feedback around the ImageBench coral accent instead of mixing gray sidebar states with blue menu and card outlines.
- Flattened the sidebar with an opaque canvas and compact coral brand mark, removing the translucent, raised-icon treatment that conflicted with the workspace cards.
- Removed the decorative divider beneath every module header while preserving the shared spacing hierarchy.
- Gave the sidebar ImageBench wordmark a more distinctive native rounded treatment with a coral “Bench” accent.
- Expanded Bulk Compressor results with explicit Before and After sizes plus the saved amount and percentage for successful files.
- Gave every Section 1 upload and preview canvas a shared adaptive neutral matte, improving visual hierarchy and white-image edge visibility without tinting source previews.
- Refined empty-state guidance, inspector sizing, navigation contrast, selected-card cues, Settings readability, and About accessibility across the Gallery Workbench interface.
- Simplified the sidebar privacy footer so the permanent offline guarantee no longer looks like a changing connection status.
- When no destination is chosen, Bulk Compressor now targets a lazy `Compressed Output` folder beside the selected inputs and creates it only after compression starts.
- Shortened the Watermark Studio and Aspect Ratio Filler primary actions to “Export,” while retaining descriptive accessibility labels.

### Fixed

- Made the full Bulk Compressor Command Details header toggle its technical log instead of limiting expansion to the chevron.
- Made the entire visible sidebar row—including whitespace beside its label—activate its module or app action.
- Restored reliable clicking for preset, metadata, and canvas-ratio dropdowns and replaced stretched full-width fields with compact native menu controls.
- Corrected the Image Splitter slider label overlap and replaced misleading ready states beside disabled actions with the actual next prerequisite.
- Kept the Watermark Studio selection outline visibly anchored around text and image watermarks when the pointer is no longer moving them.
- Prevented large Bulk Compressor selections from widening the Add Photos card or pushing its Change action outside the visible workspace.
- Made Watermark Studio load a saved Preset 1 on initial entry and reset empty preset slots to a clean editor instead of carrying forward the previous preset.
- Prevented a delayed clean-slate preview refresh from clearing the restored signature image after selecting a saved Watermark Studio preset.
- Removed the remaining system-drawn sidebar shadow by replacing the material-backed navigation split column with a flat rail and hairline divider, while preserving sidebar toggling and its keyboard shortcut.

### Documentation

- Established a connected documentation map, changelog policy, Semantic Versioning/build-number policy, and release synchronization checklist for contributors and coding agents.
- Reconciled the documentation with the 104-test suite and current UI behavior, marked earlier design audits as historical evidence, and added a production-launch audit with explicit release blockers.
- Added repository, automated-build, artifact-download, and 0.2.0 release guidance for GitHub contributors.

## 0.1 - 2026-08-24

Initial open-source development milestone. This is a buildable offline release candidate, not yet a Developer ID-signed and notarized public binary.

### Added

- Native SwiftUI/AppKit application shell with Bulk Compressor, Watermark Studio, Image Splitter, and Aspect Ratio Filler modules.
- Offline release packaging with bundled mozjpeg `cjpeg`, ExifTool, licenses, architecture checks, signing verification, and smoke encoding.
- Recursive mixed-format compression for JPEG/JPG, PNG, HEIC/HEIF, TIFF, BMP, GIF, and WebP inputs.
- Compression presets, metadata policies, exact command logging, cancellation, preflight validation, collision-safe outputs, partial-failure reporting, and saved-size percentages.
- Equal row/column splitting for 2–12 slices with deterministic names, format preservation, remainder-pixel coverage, preview guides, and Instagram layout hints.
- High-quality aspect-ratio filling with white, black, or Gaussian-blurred backgrounds and uncropped centered originals.
- Text and image watermarking with direct placement, size and opacity controls, four persistent presets, and app-managed watermark assets.
- Gallery Workbench design system with native light/dark appearance, shared workspace components, Settings, About, drag and drop, keyboard support, and accessibility semantics.
- Debug, optimized, integration, mixed-folder battle, cancellation, pixel, persistence, packaging, and scale coverage.

### Fixed

- Replaced the unreliable BMP bridge with opaque binary PPM input for mozjpeg, eliminating `Empty BMP image` failures.
- Protected originals and existing destinations with atomic writes, source-path rejection, cleanup, and collision-safe naming.
- Prevented stale asynchronous preview and preset tasks from replacing newer user selections.
- Kept batch compression running after individual corrupt or unsupported-image failures.

### Performance

- Preserved tool view models across sidebar navigation so switching modules keeps state and avoids repeated setup.
- Added bounded asynchronous thumbnail decoding, cached Aspect Filler preview sources, debounced watermark text rendering, and coalesced compressor log publication.
- Added short Reduce Motion-aware selection and module transitions.

### Documentation

- Added contributor, developer, coding-agent, code-style, design-system, roadmap, QA, licensing, and third-party dependency documentation.
