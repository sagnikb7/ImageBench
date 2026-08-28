# Sidebar Visual-System Consistency Audit

Audit date: 2026-08-27

Scope: packaged `ImageBench.app`, Light appearance, Bulk Compressor and Watermark Studio

## Verdict

The sidebar is functionally clear, but it does read as a different depth system from the workspace. The mismatch is produced by three stacked cues: the native split-view sidebar treatment, a custom semi-transparent surface over it, and a baked raised shadow in the app-icon artwork. The workspace uses opaque cards with hairline borders and almost no resting elevation.

## Step 1 — Bulk Compressor

Evidence: `01-compressor-sidebar.png`

Health: needs visual-system alignment

- Navigation hierarchy and selected state are clear.
- The sidebar brand icon looks like a raised white tile because its source artwork contains a large shadow and light plate.
- The sidebar applies `PFTheme.surface.opacity(0.72)` over the system split-view sidebar, creating a milky/material quality beside the flatter main canvas.
- The main workspace establishes grouping with opaque `SurfaceCard` backgrounds and one-point borders, so the sidebar's depth cues feel unrelated.

## Step 2 — Watermark Studio

Evidence: `02-watermark-sidebar.png`

Health: consistent behavior, same visual mismatch

- The same sidebar treatment persists across modules, confirming this is an app-shell issue rather than a compressor-specific problem.
- The coral selected row belongs to the existing design language and should remain; it does not need a shadow.

## Recommended correction

1. Replace the sidebar's full app-icon artwork with a flat compact brand mark that uses the same coral tile language as module headers. Keep the dimensional app icon for the Dock and About screen.
2. Replace the 72%-opaque sidebar overlay with an opaque semantic sidebar surface, only slightly different from the main canvas. Let the split-view divider provide separation.
3. Keep selected and hover rows flat, with tint and border/contrast changes only. Avoid resting shadows in navigation.
4. Verify the revised rail in Light, Dark, and Increase Contrast appearances. An opaque rail will make text and icon contrast more predictable than wallpaper-dependent material.

## Evidence limits

The screenshots confirm hierarchy, surface treatment, and cross-module consistency. They do not establish full keyboard, VoiceOver, Increase Contrast, Reduce Transparency, or hover-state accessibility behavior.

## Resolution — 2026-08-28

The system-owned navigation split column continued to draw visible elevation after its custom background became opaque. It has been replaced with a fixed 230-point flat rail and one semantic divider. `04-flat-divider-no-shadow.png` confirms the shadow-free packaged result. The toolbar toggle, Control-Command-S shortcut, accessibility label, full-row navigation targets, and persistent module models remain available.
