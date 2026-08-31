# ImageBench Roadmap

This roadmap communicates product sequence, not fixed release dates. Correctness and offline trust come before visual expansion.

## Phase 1 — Functional Core and Reliability

Status: substantially complete.

- Native SwiftUI/AppKit app shell
- Bulk mozjpeg compression
- Metadata preservation and removal
- mixed-format compressor discovery plus JPEG, PNG, and HEIC format-preserving tools
- Image splitting with format preservation and live source/per-part aspect-ratio guidance
- Aspect-ratio filling with solid and blurred backgrounds
- Text and image watermarking with four durable reusable presets
- Read-only EXIF/RAW metadata inspection with a bounded luminance/RGB histogram and explicit GPS map actions
- Cancellation, progress, logs, and collision-safe output
- Bundled offline dependencies
- Debug, optimized, integration, and bundle smoke tests
- Agent and contributor documentation

Completed hardening additions:

- structured succeeded/failed/skipped batch results and continuation after per-file failures;
- retry-ready failed input data and cancellation summaries;
- dependency, output-permission, and disk-space preflight;
- 1,200-file scanner coverage and an opt-in 200-image compression benchmark;
- atomic, cancellable single-image export with explicit source-overwrite protection;
- MIT license, third-party notices, notarization automation, and a dual-architecture CI matrix;
- versioned ImageBench artifacts built automatically on every GitHub push and pull request;
- SHA-256 verification for both pinned dependency source archives;
- a traceable GitHub `main` baseline for the 0.3.0 source release.

Remaining hardening candidates:

- observe the first GitHub Actions run and confirm both versioned architecture artifacts can be downloaded and opened;
- test on a representative range of Intel and Apple Silicon Macs;
- benchmark very large real-world camera files on representative Macs;
- obtain Developer ID credentials and notarize the first public release artifact.

## Phase 2 — Native Visual Redesign

Status: substantially complete.

Goal: make ImageBench feel modern, expressive, and unmistakably Mac-native without weakening functional clarity.

### Design foundation

- semantic design tokens for color, typography, spacing, radius, materials, shadows, and motion;
- system, light, and dark appearance modes with persisted user preference;
- reusable tool header, selection card, settings group, status badge, progress surface, empty state, and output summary components;
- consistent focus, hover, pressed, disabled, success, warning, and error states;
- SF Symbols used intentionally alongside clear text labels.

### App shell

- refined translucent sidebar and toolbar hierarchy;
- stronger tool identity and navigation states;
- compact dependency-health indicator;
- About window with version, build, dependency versions, offline/privacy statement, acknowledgements, and project links;
- Settings surface for appearance, startup module, and watermark-preset management.

### Tool experiences

- drag-and-drop alongside file panels;
- image thumbnails and richer selection summaries;
- before/after size and savings summaries for compression;
- clearer metadata-policy descriptions;
- direct-manipulation slice overlay with accessible alternatives;
- polished aspect-ratio preview with canvas guides and export details;
- native animations that respect Reduce Motion;
- actionable error banners and completion states.

### Design process

1. Capture and audit every current flow, including errors and empty states.
2. Explore two or three coherent visual directions before choosing one.
3. Implement tokens and shared components before screen-specific polish.
4. Migrate one tool as a reference implementation.
5. Validate light, dark, high-contrast, keyboard, VoiceOver, and reduced-motion behavior.
6. Migrate remaining tools and add focused UI regression coverage.

Agentic design work should use a product-design audit and visual ideation workflow, followed by faithful SwiftUI implementation and screenshot-based QA. Generated mockups are references, not substitutes for native accessibility and interaction behavior.

Implemented in the Gallery Workbench release candidate:

- semantic SwiftUI design tokens and shared surfaces;
- native System, Light, and Dark appearance preferences;
- refined sidebar, headers, selection cards, presets, dependency status, and persistent action bars;
- drag-and-drop and thumbnail previews;
- succeeded/failed/skipped compression summary with retry, reveal, and command details;
- redesigned splitter and aspect-filler workspaces;
- Settings and About surfaces, including startup-module and watermark-preset controls;
- temporary screenshot-based visual QA against the selected concept, with conclusions retained as text.
- Watermark Studio with direct placement, persistent presets, and cached signature assets.
- EXIF Viewer with grouped searchable metadata, popular RAW-container recognition, and a log-scale histogram;
- release-candidate walkthroughs for all five tools plus Settings and About.

Remaining validation:

- full keyboard, VoiceOver, Increase Contrast, and Reduce Motion passes on representative hardware;
- focused native UI regression coverage for navigation, sheets, and persistent action bars.

## Phase 3 — Distribution and Community

Implemented foundations:

- connected README, agent, contributor, developer, design, changelog, versioning, and roadmap documentation;
- GitHub issue and pull-request templates;
- MIT license and bundled dependency notices;
- configured GitHub origin plus push/PR CI for Apple Silicon and Intel test artifacts.

Remaining distribution work:

- confirm Apple Silicon and Intel CI artifacts build, download, and smoke-test correctly;
- complete representative hardware accessibility and RAW-codec validation;
- publish signed and notarized releases;
- document maintainers and a private security contact;
- create a contribution-friendly backlog with scoped starter issues;
- test upgrade paths and release reproducibility.

## Future Ideas

Ideas below are intentionally uncommitted until the core experience is polished:

- reusable processing recipes;
- Finder Quick Actions or Services integration;
- drag-to-Dock and share-sheet workflows;
- richer batch failure recovery;
- optional image resize and format-conversion tools;
- histogram clipping warnings, channel toggles, and side-by-side metadata comparison for the EXIF Viewer;
- update checks that remain transparent, opt-in, and nonessential to offline use.
