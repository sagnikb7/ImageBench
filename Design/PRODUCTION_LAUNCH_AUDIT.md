# ImageBench Production Launch Audit

Audit date: 2026-08-28

Target: current source tree and freshly packaged `dist/ImageBench.app` on Apple Silicon

Decision: **source release preparation is healthy; hold unsigned public binaries**

## Executive outcome

The image-processing core, offline bundle, and inspected Gallery Workbench UI are healthy. The latest debug/release/package/smoke pipeline passed, all 107 tests passed in both configurations with the two opt-in diagnostics skipped as designed, and the explicit scale benchmark passed.

The reviewed 0.2.0 baseline is committed and pushed to the requested GitHub origin, push/PR CI is configured to produce correctly named dual-architecture ImageBench artifacts, and pinned dependency downloads are checksum-verified. Public binary distribution is not ready because the first remote CI result still needs confirmation and the package has not received a Developer ID signature or notarization ticket. These are release-engineering blockers rather than known image-processing correctness defects.

## Launch blockers

| Priority | Finding | Evidence | Required outcome |
| --- | --- | --- | --- |
| P1 | Public signing is incomplete | The fresh app is valid on disk with hardened runtime but uses an ad-hoc signature, has no Team Identifier, and is not notarized/stapled. | Package with the release owner's Developer ID, notarize, staple, and pass Gatekeeper assessment. |

## Follow-up validation

| Priority | Finding | Required outcome |
| --- | --- | --- |
| P2 | Current local package is arm64 only. | Produce and smoke-test the Intel artifact on the configured Intel runner or representative hardware. |
| P2 | The first GitHub Actions matrix result has not been confirmed from this host. | Confirm both versioned artifacts complete and download correctly from the pushed baseline. |
| P2 | Accessibility evidence is structural, not a complete assistive-technology certification. | Complete hands-on keyboard, VoiceOver, Increase Contrast, and Reduce Motion passes on representative Apple Silicon and Intel Macs. |
| P2 | RAW coverage still uses generated fixtures and extension contracts. | Profile very large real camera files and representative RAW camera generations without committing private images. |
| P2 | Native UI behavior has no automated UI regression suite. | Add focused coverage for navigation, sheets, drop targets, persistent actions, and critical accessibility state. |
| P3 | Two process helper types use `@unchecked Sendable`. | Keep the lock/lifecycle assumptions explicit and extend race/cancellation coverage when this service changes. |
| P3 | The release executable embeds the local SwiftPM build path as a resource-bundle fallback string. | Decide whether reproducible/public builds must strip this developer-path disclosure. Runtime resource lookup works from the packaged bundle. |
| P3 | UI maintenance is concentrated in a few files. | Treat `CompressorView.swift` (345 lines), `DesignSystem.swift` (337), and `WatermarkViewModel.swift` (301) as review hotspots; split only when responsibilities diverge. |

## Code-quality evidence

- Source size: 5,486 Swift lines across feature views, `@MainActor` view models, engines, and narrow shared services.
- Test inventory: 107 deterministic XCTest cases generated from local fixtures or skipped unless an explicit private-library path is supplied; no personal-photo path or asset is committed.
- Static scan: no `TODO`, `FIXME`, `HACK`, `XXX`, `fatalError`, `try!`, or forced-cast findings in `Sources` or `Tests`.
- Privacy scan: no runtime URLSession/network APIs, telemetry, analytics, source logging, or personal absolute paths in source, tests, or scripts.
- Architecture boundaries: all five observable view models are `@MainActor`; `Process` construction is confined to `ProcessRunner`; engines and services contain the processing work.
- Safety controls: typed localized errors, collision-safe naming, atomic single-image writes, source-path rejection, per-file batch recovery, temporary cleanup, and cancellation checks are implemented and covered.
- Dependency bundle: packaged `cjpeg` links only to `/usr/lib/libSystem.B.dylib`; ExifTool modules and both third-party license notices are present.

## Verification results

| Check | Result |
| --- | --- |
| `Scripts/lint.sh` | Passed |
| Debug suite | 107 executed, 2 opt-in diagnostics skipped, 0 failures |
| Release suite | 107 executed, 2 opt-in diagnostics skipped, 0 failures |
| `Scripts/package-app.sh` | Passed |
| `Scripts/smoke-test-app.sh` | Passed, including a real bundled mozjpeg encode |
| Pinned dependency fetch | Passed with SHA-256 verification before extraction |
| GitHub Actions workflow | YAML and shell syntax passed locally; baseline commit `1e80e89` is pushed and the first remote matrix result awaits confirmation |
| `Scripts/run-benchmarks.sh` | Passed: 200 images in 4.26 s; 1,200-file scan in 0.060 s on the audited Apple Silicon host |
| Opt-in real-folder compression | Passed: 337 recursively discovered screenshots (148.6 MB), metadata preservation enabled, 337 outputs, 0 failures, 0 skips in 383.5 s; input remained read-only and disposable output was removed |
| Bundle verification | 23 MB arm64 app; version 0.2.0 (2); signature structure valid; bundled tools and licenses present |
| CI-style archive | 6.5 MB `ImageBench-0.2.0-macos-arm64.zip`; complete app bundle structure verified |

Restricted automation initially produced transparent-black Core Image test output. Per `AGENTS.md`, the same complete verification was rerun with normal macOS graphics/process access and passed; production rendering code was not changed to accommodate the sandbox artifact.

## UI walkthrough

1. **Bulk Photo Compressor — healthy.** The Add Photos stage is visually primary, configuration hierarchy is calm, and the disabled action explains the missing input. Evidence: `Audit/ProductionLaunch/01-compressor-empty-light.jpg`.
2. **Watermark Studio — healthy.** Preview and Inspector align, preset slots remain compact, and text/image choice, placement, size, opacity, output, and Export read in task order. Evidence: `Audit/ProductionLaunch/02-watermark-empty-light.jpg`.
3. **Image Splitter — healthy.** The media stage, direction, discrete slice control, preparation guidance, output, and action bar preserve the shared hierarchy. Evidence: `Audit/ProductionLaunch/03-splitter-empty-light.jpg`.
4. **Aspect Ratio Filler — healthy.** Canvas ratio and fill style are clearly separated, the neutral stage makes the drop target legible, and Export is gated by image selection. Evidence: `Audit/ProductionLaunch/04-filler-empty-light.jpg`.
5. **Settings — healthy in the inspected scope.** Appearance and privacy have clear grouping, concise copy, native controls, and an explicit close action. Evidence: `Audit/ProductionLaunch/05-settings-light.jpg`.
6. **About — healthy.** Product identity, version/build metadata, offline dependency readiness, mozjpeg 4.1.5, ExifTool 13.25, notices, license, and close action follow a coherent reading order. The 0.2.0 (2) metadata is verified again during release packaging. Historical evidence: `Audit/ProductionLaunch/06-about-light.jpg`.
7. **Dark appearance — healthy in the inspected empty state.** Contrast, semantic coral/blue roles, borders, neutral media stage, and disabled action remain distinguishable. Evidence: `Audit/ProductionLaunch/07-filler-empty-dark.jpg`.

Accessibility-tree inspection exposed labelled navigation, ordered headings, upload actions, native controls, values, disabled primary actions, and close buttons. Screenshots and the tree do not prove comfortable VoiceOver narration or every keyboard path, so the hardware pass remains open.

## Documentation reconciliation

All first-party Markdown files were inventoried. Product names, version 0.2.0/build 2, dependency versions and checksums, supported formats, privacy claims, build commands, source-safety rules, repository links, and local links were checked against current code and packaging. README and contributor instructions point to the GitHub repository and explain automatic artifact builds; roadmap and release documents expose the remaining CI-result, representative-hardware, signing, and notarization gates.
