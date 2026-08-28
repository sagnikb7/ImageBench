# ImageBench Typography Audit

Audit date: 2026-08-27

Scope: product wordmark, tool hierarchy, controls, supporting copy, and Settings typography

Decision: keep the native type system and introduce a restrained brand-only display treatment

## Product mood

ImageBench should feel like a calm, precise photo workbench with one warm creative accent. It is a production utility used around personal image libraries, so legibility, predictable control sizing, and native macOS behavior matter more than fashion. Personality should be concentrated in the product identity rather than spread across operational text.

## Current system

The interface uses San Francisco through SwiftUI semantic styles:

- product and tool names: `.title2.bold()`;
- numbered sections: `.headline`;
- navigation and controls: `.body`;
- supporting/status text: `.subheadline`;
- help and consequence text: `.caption`;
- tertiary labels and footer copy: `.caption2`;
- commands and changing numeric values: monospaced variants.

This is a strong, accessible foundation. Semantic sizing, native rendering, familiar control metrics, and broad language coverage should remain intact.

## Evidence walkthrough

1. **Bulk Compressor — healthy structure, weak tonal distinction.** `ImageBench` and the active tool title use nearly the same bold system voice. Section hierarchy is clear, but preset consequences, accepted formats, readiness details, and action-bar guidance are visually small and faint. Evidence: `01-compressor-current.png`.
2. **Watermark Studio — healthy and appropriately quiet.** The type does not compete with the photo stage. Preset numbers, controls, and section headings scan well. The repeated small gray instructions are the main legibility risk. Evidence: `02-watermark-current.png`.
3. **Settings — healthy.** The title, card headings, control labels, and privacy statement form a clear reading order. The explanatory paragraph can remain secondary, but should not become lighter or smaller. Evidence: `03-settings-current.png`.
4. **Snapseed comparison — useful for branding, not for wholesale imitation.** The refreshed product uses a distinctive rounded/geometric wordmark and bold expressive promotional headings, while operational editor labels remain restrained. Evidence: `04-snapseed-home-reference.webp` and `05-snapseed-editor-reference.webp`.

## Recommendation

### Keep native typography for 95% of the app

Keep San Francisco for navigation, tool titles, section headings, controls, status, filenames, settings, and every task-critical instruction. Do not apply a display font to menus, buttons, metadata choices, file paths, or result summaries.

### Give the sidebar wordmark a brand-only voice

Change only the top-left `ImageBench` lockup to SF Rounded Bold or Heavy at roughly the existing title size. Use slightly tighter tracking and retain one accessible text label. The app icon already supplies coral; keep the wordmark in the primary foreground color rather than introducing multicolor letters.

A subtle two-weight lockup—`Image` medium and `Bench` bold—is acceptable if it remains one word and reads cleanly at the 210-point sidebar minimum. Avoid script, retro display, stencil, condensed, or exaggerated novelty faces.

### Improve supporting-copy hierarchy

- Promote instructions that affect a decision or explain a consequence from `.caption` to `.subheadline` where space permits.
- Keep `.caption` for accepted-format lists, paths, timestamps, and genuinely tertiary details.
- Reserve `.caption2` for the privacy footer and compact diagnostic metadata.
- Avoid lowering secondary-text opacity beyond the system semantic color.
- Keep monospaced typography limited to commands, versions, paths, and changing numeric diagnostics.

## Direction ranking

1. **SF Pro interface + SF Rounded wordmark — recommended.** Most native, no font asset or licensing overhead, and enough personality for the current brand.
2. **SF Pro interface + licensed geometric custom wordmark.** Consider only as part of a broader identity project with tested glyph coverage, localization, packaging, and a real wordmark asset.
3. **Custom font across the interface.** Not recommended. It would reduce native familiarity, create control-metric and accessibility risk, and add visual noise to a task-focused utility.

## Accessibility limits

Screenshots confirm hierarchy and visible size relationships, not legibility for every display scale or visual condition. Any wordmark adjustment and helper-text promotion should be checked in Light, Dark, Increase Contrast, and common macOS display scalings. The visual wordmark must remain exposed to assistive technology simply as “ImageBench.”
