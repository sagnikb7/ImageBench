# ImageBench UI QA

This file records current visual and interaction verification without storing generated screenshots in the repository. Temporary captures belong outside the worktree; Git history is sufficient for superseded evidence. Long-lived visual sources are limited to intentionally selected design concepts and product artwork under `Design/`.

## 0.3.1 local build — 2026-10-01

- Version 0.3.1 (build 4) passed Swift lint, 113 debug and 113 optimized tests (2 opt-in diagnostics skipped in each run), release packaging, and offline bundle smoke testing.
- The app installed at `/Applications/ImageBench.app` matches the packaged bundle contents, reports 0.3.1 (4), and passes strict signature verification and the bundle smoke test. The previous app contents were saved temporarily for recovery.
- Native screen capture, keyboard, VoiceOver, and appearance passes remain open for representative hardware validation.

## Sidebar wordmark size — 2026-10-01

- Reduced the coral Fraunces wordmark from 23 to 21 points while keeping its font, tracking, icon, and sidebar spacing. The existing width check uses the configured size.
- Swift lint, focused wordmark tests, debug and optimized suites, release packaging, and bundle smoke test passed. Native visual verification remains pending.

## Compressor quantization control — 2026-10-01

- Replaced the Custom quantization stepper with a native segmented picker showing Default and 1–8. Its label moves above the picker when the inline row is too wide. The selection still binds to the same encoding option.
- Swift lint, focused compressor-option tests, debug and optimized suites, release packaging, and bundle smoke test passed. Native visual and keyboard checks remain pending.

## Compressor size summary — 2026-10-01

- Replaced the tall stacked size callout with a horizontal readout for total size, Before → After, and the signed size change. A wrapped layout remains available when the row cannot fit.
- Swift lint, debug and optimized tests (113 tests each, 2 optional diagnostics skipped), release packaging, and bundle smoke test passed. Native visual and keyboard checks remain pending because this desktop session did not expose an ImageBench window for capture.

## About and Settings organization — 2026-10-01

- Settings contains only appearance, startup, and watermark-preset controls. About groups product identity, local privacy, open-source links, legal notices, and bundled-tool status. Both sheets keep a bounded scroll area for smaller displays.
- Swift lint, debug and optimized test suites (113 tests each, 2 optional diagnostics skipped), release packaging, and bundle smoke test passed. Visual and keyboard accessibility verification remains pending because the app window was not available to capture in this desktop session.

## Typography preview — 2026-09-30

- Option-3 orange Fraunces branding is retained only in the sidebar wordmark. Following user review, decorative serif module/step/sheet headings were replaced with restrained Figtree headings.
- App-owned text uses three families: Fraunces (wordmark), Figtree (interface and technical details), Arial (watermark editing/export). Native macOS dialogs and symbols retain platform typography.
- Removed unused Archivo Narrow font/license and obsolete resource README. Remaining resources are two UI fonts with their licenses and the runtime app icon; packaging icon variants and offline tool dependencies remain required.
- Final Watermark Studio capture at 1298 × 900 points shows unclipped branding, readable sans-serif headings, and intact inspector controls. Initial compressor trial was also checked at 1080 points wide; final dark appearance and Settings screenshot were not reverified in this pass.
- Verification: focused typography tests passed in debug and release; clean release packaging, signing, exact two-font bundle check, offline smoke test, and whitespace checks passed. Processing engines and saved presets were not changed.
- Temporary visual evidence: `/tmp/imagebench-type-final.png`. No generated screenshot is committed. Trial remains uncommitted for user review.

## Previous pass — 2026-09-01

Scope: packaged native app at its standard workspace size using generated, non-personal image fixtures.

- **Image Splitter:** source dimensions, simplified ratio, and decimal ratio appear with the live per-row or per-column result. Remainder-pixel splits expose exact dimension ranges and an approximate rounded ratio when necessary. The inspector scrolls natively instead of compressing content.
- **Bulk Compressor:** Custom quality uses a labelled 0–100 slider in five-point steps. Fixed presets retain their exact tested recipes until Custom is selected.
- **EXIF Viewer:** valid GPS coordinates, Show Map, and Open in Google Maps are one Location group. Neither map service is contacted during ordinary metadata inspection.
- **Accessibility:** changed controls expose native roles, labels, values, and enabled states through the macOS accessibility tree. The Splitter ratio summary updates when direction or count changes.
- **Privacy:** QA used generated fixtures only. No personal photo, metadata, or precise location is retained in the repository.

Verification completed: Swift formatting and lint passed; all 111 debug and optimized tests passed with the two expected opt-in diagnostics skipped; release packaging, signing checks, and the offline bundle smoke test passed.

## Required UI checks

For a meaningful visual change:

1. Inspect the existing screen and the normative rules in [UI_DESIGN_SYSTEM.md](UI_DESIGN_SYSTEM.md).
2. Exercise relevant empty, ready, running, success, failure, cancellation, and disabled states.
3. Check the standard and minimum supported window sizes.
4. Inspect System, Light, and Dark appearances plus Increase Contrast and Reduce Motion where relevant.
5. Verify keyboard order, native control roles, readable accessibility labels/values, and non-color state cues.
6. Use generated fixtures for visual QA and keep captures temporary unless the repository owner explicitly approves a durable design reference.
7. Record outcomes and remaining risks here; put lasting product rules in the design system.

## Open hardware validation

- Complete hands-on VoiceOver and full-keyboard passes on representative Apple Silicon and Intel Macs.
- Validate representative real RAW camera generations without committing private images.
- Add focused native UI regression coverage for navigation, sheets, drop targets, and persistent action bars.
