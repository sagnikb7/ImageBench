# ImageBench UI QA

This file records current visual and interaction verification without storing generated screenshots in the repository. Temporary captures belong outside the worktree; Git history is sufficient for superseded evidence. Long-lived visual sources are limited to intentionally selected design concepts and product artwork under `Design/`.

## Current pass — 2026-09-01

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
