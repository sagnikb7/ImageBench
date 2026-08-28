# ImageBench Cross-Module Consistency Audit

Audit date: 2026-08-24

Mode: combined product-design and accessibility review

Target: packaged macOS release candidate at 1,230 × 768 points

Status: historical consistency evidence. For current launch readiness, see `PRODUCTION_LAUNCH_AUDIT.md`.

## User goal and accessibility target

A user should be able to move between all four tools without relearning layout, hierarchy, selection controls, upload behavior, or run/cancel actions. Native controls must remain understandable through keyboard and assistive technology, and the interface must retain useful contrast in Light and Dark appearances.

## Numbered walkthrough

1. **Bulk Compressor — healthy.** In this historical capture, source and configuration cards begin on the same content baseline, 18 points below the then-present header divider. The current implementation preserves that spacing rhythm without the decorative divider. Full-width selection fields align their values with section headings and keep one trailing chevron. Evidence: `Audit/Consistency/After/01-compressor.jpg`.
2. **Watermark Studio — healthy.** Preview and Inspector top-align. The empty photo prompt uses the shared scale and spacing, and the primary action uses the standard minimum width. Evidence: `Audit/Consistency/After/02-watermark.jpg`.
3. **Image Splitter — healthy.** Step 1 and Step 2 align, direction/count/output retain a clear sequence, the upload region has one dashed boundary, and the action region remains stable. Evidence: `Audit/Consistency/After/03-splitter.jpg`.
4. **Aspect Ratio Filler — healthy.** Preview and Inspector align, Canvas Ratio is a full-width leading-aligned field, and Fill Style remains visually subordinate to the target ratio. Evidence: `Audit/Consistency/After/04-filler.jpg`.
5. **Settings in Dark appearance — healthy.** Sheet spacing uses the shared card rhythm, text remains legible, native appearance controls retain clear selection, and the visible close button remains discoverable. Evidence: `Audit/Consistency/After/05-settings-dark.jpg`.
6. **Filler in Dark appearance — healthy with a hardware follow-up.** Hierarchy, coral/blue role separation, borders, upload surface, and disabled action remain distinguishable. Evidence: `Audit/Consistency/After/06-filler-dark.jpg`.

## Confirmed strengths

- One persistent sidebar, tool header, content region, and action bar across all processing modules.
- Coral consistently identifies product/selection/step state; blue remains the action language.
- Section titles use the same semantic heading style and ordered numbering.
- Native segmented controls, radio groups, steppers, sliders, menus, and sheets preserve familiar macOS behavior.
- Settings and About are not duplicated in tool headers and both expose visible close controls.
- Empty, disabled, ready, running, success, partial failure, and dependency states have explicit text rather than color-only meaning.

## Drift fixed during this audit

- Preview cards were vertically centered while inspectors started at the top.
- Tool content touched the header boundary instead of following the documented screen rhythm.
- `SelectionField` rendered as a compact centered pill despite the documented full-width pattern.
- Empty Preview tools stacked an extra bordered canvas around the upload region.
- Three feature views independently defined nearly identical empty-image prompts.
- Primary actions used inconsistent minimum widths.
- Filler cancellation used a different visual role and the Cancel shortcuts were inconsistent.
- Settings used one-off outer and Appearance-group spacing values.

## Accessibility evidence and limits

The current accessibility trees expose tool navigation, ordered headings, native menu buttons, segmented/radio values, steppers, sliders, upload buttons, status text, disabled primary actions, and sheet close buttons. Decorative prompt icons are hidden. The custom selection-field overlay is non-interactive and hidden, leaving the native Menu as the single accessible control.

Screenshots and accessibility-tree inspection cannot prove comfortable real-world VoiceOver narration, Increase Contrast rendering, keyboard order under every state, or Reduce Motion behavior. Those remain hands-on release checks on representative hardware; this audit does not claim full WCAG compliance.

## Release recommendation

The visual system is internally consistent and appropriate for a launch candidate. No P0, P1, or P2 consistency issue remains in the audited empty/default states. Public release still depends on the existing hardware-accessibility pass, Developer ID signing, and notarization checklist.
