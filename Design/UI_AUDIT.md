# ImageBench Native UI Audit

Date: 2026-08-21

Status: historical pre-redesign evidence. The current UI contract is `UI_DESIGN_SYSTEM.md`; current launch readiness is recorded in `PRODUCTION_LAUNCH_AUDIT.md`.

Evidence: [`Audit/current-compressor.png`](Audit/current-compressor.png), captured from the rebuilt native release app before visual redesign. Splitter and filler findings also reference their current SwiftUI view structure because macOS Accessibility control was unavailable for switching the captured window state.

## What already works

- The three-tool sidebar is immediately understandable and uses native selection behavior.
- Tool titles and one-line descriptions explain intent without onboarding.
- Standard SwiftUI controls preserve familiar keyboard and accessibility behavior.
- The compressor exposes dependency health, exact commands, progress, and cancellation.
- Splitter and filler already use a useful preview-plus-inspector mental model.
- The interface does not obscure the offline/local trust promise behind branding.

## Highest-impact problems

### 1. The task hierarchy is visually flat

Every compressor section uses nearly identical pale `GroupBox` treatment. Input selection, metadata policy, dependency diagnostics, the primary action, and the command console all compete at the same level. The most important journey—drop/select, configure, run, review—does not read as a strong sequence.

### 2. Space is not serving the task

The wide detail canvas has large unused regions while controls remain clustered into thin rows. The compressor requires vertical scrolling before its main action and console can be reviewed together. The sidebar is visually oversized for only three destinations and has no useful secondary content.

### 3. Empty and running states are too similar

The empty compressor shows a tiny blue progress sliver even when labeled “Ready,” which can look like stalled work. Disabled primary buttons are distant from the missing requirement. There is no prominent drop target, file-format guidance, or concise next step.

### 4. Results and recovery are buried

Command output is transparent but dominates the result area as an undifferentiated text editor. Succeeded, failed, skipped, space saved, and output location need a scannable summary above a collapsible technical log. Failed files need visible retry and reveal actions.

### 5. Metadata choices need clearer semantics

Three checkboxes imply independent choices even though “Remove all” disables the others and removing EXIF subsumes GPS. A single privacy policy picker with short consequences would be easier to understand and harder to configure inconsistently.

### 6. Cross-tool consistency is incomplete

Splitter and filler share a preview/control arrangement, but compressor uses a full-width form. Fixed preview and inspector widths can become cramped at smaller windows. Primary actions, statuses, empty states, and output feedback do not yet share reusable visual components.

### 7. Product identity and preferences are absent

The current experience is a functional utility shell rather than a memorable product. There is no About surface, visible version/build, appearance setting, privacy summary, dependency acknowledgement access, or consistent visual signature beyond the system accent color.

## Accessibility and native behavior priorities

- Preserve real SwiftUI/AppKit controls, focus rings, keyboard traversal, and semantic labels.
- Add explicit VoiceOver descriptions for drop zones, previews, slice overlays, result counts, and status changes.
- Treat color as reinforcement, never the only success/error signal.
- Verify system, light, dark, increased-contrast, and Reduce Motion settings.
- Keep exact command text selectable while making the console secondary to human-readable outcomes.
- Avoid custom control replicas when a native picker, menu, disclosure group, toolbar item, or status item provides the behavior.

## Redesign requirements

The selected direction should establish semantic tokens and reusable native components for:

- app shell, sidebar, toolbar, and compact dependency health;
- tool header and contextual help;
- drag-and-drop source well with file panels as an equal alternative;
- preview stage and inspector groups;
- preset cards or native segmented/menu selection where appropriate;
- sticky primary action and cancellable progress surface;
- succeeded/failed/skipped result summary with retry and reveal actions;
- collapsible command console;
- About and Settings surfaces with version/build, offline promise, appearance, and acknowledgements.
