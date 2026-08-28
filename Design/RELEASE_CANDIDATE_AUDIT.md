# ImageBench Release-Candidate Audit

Audit date: 2026-08-24

Status: historical release-candidate evidence. For current launch readiness, see `PRODUCTION_LAUNCH_AUDIT.md`.

## Outcome

The four-tool release candidate is visually coherent and functionally green after the final hardening pass. No known P0, P1, or P2 defect remains in the audited scope. Three reliability gaps found during review were fixed rather than deferred: source-path overwrite protection, explicit Filler export cancellation, and stale asynchronous result protection.

## Visual walkthrough

1. **Bulk Compressor** — The empty state keeps image selection primary, dependency readiness visible, and advanced command details collapsed. Preset and metadata menus retain familiar dropdown affordances. See `Audit/ReleaseCandidate/01-compressor-empty.jpg`.
2. **Watermark Studio** — The source preview dominates the workspace; four preset slots and watermark controls remain in a compact inspector. See `Audit/ReleaseCandidate/02-watermark-empty.jpg`.
3. **Image Splitter** — Direction, the 2–12 slice control, preparation guidance, and output destination read in task order without nested gray surfaces. See `Audit/ReleaseCandidate/03-splitter-empty.jpg`.
4. **Aspect Ratio Filler** — Source-ratio guidance, target canvas, and fill style remain distinct while preserving the same Preview/Inspector layout. See `Audit/ReleaseCandidate/04-filler-empty.jpg`.
5. **Settings** — Appearance and privacy are grouped clearly; the visible close button complements Escape dismissal. See `Audit/ReleaseCandidate/05-settings.jpg`.
6. **About** — Version, offline readiness, bundled dependency versions, notices, license, and close action are discoverable in one compact surface. See `Audit/ReleaseCandidate/06-about.jpg`.
7. **Final package** — The rebuilt distributable relaunched with bundled tools ready and the expected accessibility hierarchy. See `Audit/ReleaseCandidate/07-packaged-compressor-final.jpg`.

## Functional QA matrix

| Area | Scenarios | Result |
| --- | --- | --- |
| Compressor discovery | Six image formats; mixed documents/media; corrupt supported files; nested output; hidden/package exclusion | Passed |
| Compressor execution | All presets; metadata keep/GPS/EXIF/all; transparent PNG; HEIC; failure continuation; cancellation | Passed |
| Naming and safety | Existing output collision; Unicode/quotes; duplicate stems; no partial encoder output | Passed |
| Scale | 1,200-file scan; 200-image real mozjpeg subprocess benchmark | Passed |
| Splitter | Rows/columns; remainder pixels; 12-slice limit; JPEG/PNG/HEIC; collision safety | Passed |
| Filler | All ratios and fill styles; bounds guard; pixels/dimensions; atomic export; source protection | Passed |
| Watermark | Text/image render; opacity; normalized placement; source protection; preset persistence/assets | Passed |
| Process layer | stdout/stderr stress; launch errors; cancellation; runner reuse | Passed |
| Offline bundle | Bundled dependency discovery, signature/linkage checks, real smoke encode | Passed after final packaging |

## Remaining release risks

- Public distribution still needs the maintainer's Developer ID signature and notarization credentials.
- Keyboard and accessibility semantics were inspected, but a dedicated VoiceOver, Increase Contrast, and Reduce Motion pass should be performed on representative Intel and Apple Silicon Macs.
- The benchmark uses generated fixtures; very large real camera files should still be profiled on representative hardware.

These are release-validation or distribution tasks, not known correctness defects in the current codebase.
