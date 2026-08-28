# ImageBench Release-Candidate Design QA

Baseline audit: 2026-08-24

Last updated: 2026-08-28

## Scope and evidence

The packaged native app was inspected at its minimum supported workspace size in Light appearance. The current run captured:

- `Design/Audit/ReleaseCandidate/01-compressor-empty.jpg`
- `Design/Audit/ReleaseCandidate/02-watermark-empty.jpg`
- `Design/Audit/ReleaseCandidate/03-splitter-empty.jpg`
- `Design/Audit/ReleaseCandidate/04-filler-empty.jpg`
- `Design/Audit/ReleaseCandidate/05-settings.jpg`
- `Design/Audit/ReleaseCandidate/06-about.jpg`
- `Design/Audit/ReleaseCandidate/07-packaged-compressor-final.jpg`
- `Design/Audit/Consistency/After/01-compressor.jpg`
- `Design/Audit/Consistency/After/02-watermark.jpg`
- `Design/Audit/Consistency/After/03-splitter.jpg`
- `Design/Audit/Consistency/After/04-filler.jpg`
- `Design/Audit/Consistency/After/05-settings-dark.jpg`
- `Design/Audit/Consistency/After/06-filler-dark.jpg`
- `Design/Audit/Dropdowns/01-before.jpg`
- `Design/Audit/Dropdowns/02-after.jpg`
- `Design/Audit/DropdownHitArea/02-field-click-no-open.jpg`
- `Design/Audit/DropdownHitArea/04-fixed-field.jpg`
- `Design/Audit/SidebarFooter/01-current.png`
- `Design/Audit/SidebarFooter/02-simplified.jpg`
- `Design/Audit/AccessibilityPolish/01-compressor.jpg`
- `Design/Audit/AccessibilityPolish/02-watermark.jpg`
- `Design/Audit/AccessibilityPolish/03-splitter.jpg`
- `Design/Audit/AccessibilityPolish/04-filler.jpg`
- `Design/Audit/AccessibilityPolish/05-settings.jpg`
- `Design/Audit/AccessibilityPolish/06-about.jpg`
- `Design/Audit/AccessibilityPolish/07-filler-dark.jpg`
- `Design/Audit/WatermarkSelection/02-persistent-outline.jpg`
- `Design/Audit/CompressorLargeBatch/02-responsive-after.jpg`
- `Design/Audit/Section1Surface/After/01-compressor-light.jpg`
- `Design/Audit/Section1Surface/After/02-watermark-light.jpg`
- `Design/Audit/Section1Surface/After/03-splitter-light.jpg`
- `Design/Audit/Section1Surface/After/04-filler-light.jpg`
- `Design/Audit/Section1Surface/After/05-compressor-dark.jpg`
- `Design/Audit/Section1Surface/After/06-watermark-dark.jpg`
- `Design/Audit/Section1Surface/After/07-splitter-dark.jpg`
- `Design/Audit/Section1Surface/After/08-filler-dark.jpg`
- `Design/Audit/ProductionLaunch/01-compressor-empty-light.jpg`
- `Design/Audit/ProductionLaunch/02-watermark-empty-light.jpg`
- `Design/Audit/ProductionLaunch/03-splitter-empty-light.jpg`
- `Design/Audit/ProductionLaunch/04-filler-empty-light.jpg`
- `Design/Audit/ProductionLaunch/05-settings-light.jpg`
- `Design/Audit/ProductionLaunch/06-about-light.jpg`
- `Design/Audit/ProductionLaunch/07-filler-empty-dark.jpg`
- `Design/Audit/HeaderTypographyResults/01-compressor-light.jpg`
- `Design/Audit/HeaderTypographyResults/02-watermark-dark.jpg`
- `Design/Audit/HeaderTypographyResults/03-compressor-dark.jpg`
- `Design/Audit/InteractionAffordances/01-sidebar-hover.jpg`
- `Design/Audit/InteractionAffordances/02-whitespace-click-selected.jpg`
- `Audit/AttentionToDetail/01-command-details-expanded.jpg`
- `Audit/AttentionToDetail/02-about-unified-mark.jpg`
- `Audit/AttentionToDetail/03-settings-padded-close.jpg`
- `Audit/HeaderIconRemoval/01-compressor.jpg`
- `Audit/HeaderIconRemoval/02-watermark.jpg`
- `Audit/HeaderIconRemoval/03-splitter.jpg`
- `Audit/HeaderIconRemoval/04-filler.jpg`
- `Audit/ExifViewer/01-empty-light.png`
- `Audit/ExifViewer/02-generated-metadata-light.png`
- `Audit/ExifViewer/03-settings.png`
- `Audit/ExifViewer/04-watermark-reset-controls.png`
- `Audit/WatermarkTextField/01-focus-ring-and-copyright-default.png`
- `Audit/BrandWordmark/00-selected-option.png`
- `Audit/BrandWordmark/01-archivo-narrow-implementation.png`
- `Audit/BrandWordmark/02-reference-comparison.png`

The reference comparison used `Design/QA/implementation-familiar-affordances-filler.jpg` and `Design/UI_DESIGN_SYSTEM.md`. Reference and release-candidate Filler captures were reviewed together at the same 1,230 × 768 viewport. The only structural change is the expected Watermark Studio navigation item; layout density, surfaces, typography, colors, and control placement remain aligned.

## Findings

- P0: none.
- P1: none after the source-overwrite fix described below.
- P2: none after cancellation and stale-task fixes.
- P3: representative-hardware VoiceOver, Increase Contrast, and Reduce Motion passes remain release follow-ups.

The app retains the established Gallery Workbench language rather than introducing a new visual direction. Coral is limited to identity, selection, and step cues; native blue identifies primary action state. Upload regions have a low-intensity neutral fill and dashed boundary. Sidebar selection is a uniform coral-tinted capsule without a left accent stripe. Dropdowns combine a readable value field, visible chevron, and native menu behavior.

All five tools preserve the shared header, workspace, inspector, and action-bar hierarchy. Settings and About provide visible close buttons as well as standard Escape dismissal. Settings and About are present once in the persistent lower sidebar and are not duplicated in the tool header.

## Interaction and accessibility evidence

1. Navigation exposed all five tools plus Settings and About through the native accessibility tree.
2. Empty upload states named their accepted formats, exposed browse actions, and kept unavailable export actions disabled.
3. Watermark Studio exposed four preset slots, text/image selection, direct-placement guidance, size, opacity, Center, and export state.
4. Splitter exposed Rows/Columns, the enforced 2–12 slice range, Instagram preparation guidance, and destination selection.
5. Filler exposed source-ratio guidance, canvas presets, selectable fill-style cards, and high-quality export state.
6. Settings and About exposed labelled content and visible close controls. About reported the packaged mozjpeg and ExifTool versions.

Native control semantics, labels, focusability, disabled states, and contrast were inspected. This is not a substitute for a hands-on VoiceOver pass on representative hardware, which remains documented in `ROADMAP.md`.

## Functional fixes discovered during QA

- Bulk Compressor plans a `Compressed Output` destination beside the current inputs when no folder is chosen, follows later input changes, and defers directory creation until compression preflight.
- Added shared atomic single-image export through `ImageRenderer.writeAtomically`.
- Filler and Watermark now refuse an output path that resolves to the selected source.
- Filler export now propagates cancellation and exposes a Cancel action while active.
- Filler preview generations prevent a cancelled older render from clearing a newer result.
- Watermark preset loading cancels and guards stale slot requests.
- Watermark image selection and cached preset assets are validated through the production Core Image decode path.
- Watermark text and image overlays retain a visible editor-only selection outline after pointer movement ends.
- Watermark Studio applies a saved Preset 1 on its initial load, while selecting an empty slot clears the prior text/image, color, size, opacity, and placement state.
- Bulk Compressor keeps its selection summary and Change action inside the Add Photos card while the thumbnail strip reduces its visible previews to fit the available column width.

## Cross-module consistency pass

- All processing content begins on the shared 18-point rhythm below the header region; decorative header dividers have been removed.
- Preview and Inspector cards top-align; Step 1 and Step 2 share a baseline.
- Empty preview stages use one dashed upload boundary instead of a nested bordered canvas.
- Preset and ratio selection fields are compact, leading-aligned, and expose one trailing chevron.
- Watermark, Splitter, and Filler empty prompts share `ImageDropPrompt`.
- Primary actions use a shared minimum width; active operations use the same large destructive `ToolCancelButton` and Escape shortcut.
- Light and Dark captures preserve hierarchy and the intended coral identity versus blue action split.

## Responsiveness pass

- Sidebar navigation retains all five tool view models, so returning to a module preserves input, preview, settings, and active task state instead of recreating its model.
- Packaged-app switching was exercised Compressor → Watermark → Filler → Splitter → Watermark; every destination exposed its complete accessibility tree without an intermediate loading state.
- Module and selection transitions use the shared 140 ms ease-out timing and disable themselves when Reduce Motion is active.
- Compressor thumbnails use bounded asynchronous ImageIO decoding rather than full-resolution decoding during body updates.
- Compressor command output remains exact while hidden and visible log publishing is coalesced to avoid high-frequency SwiftUI redraws.
- Aspect Filler caches the decoded interactive-preview source and coalesces custom-ratio typing; export continues to use the independent full-resolution path.
- Watermark text and color previews render off the main actor after an 80 ms input debounce.

## Dropdown interaction follow-up — 2026-08-27

The compressor preset, metadata policy, and Aspect Filler canvas-ratio controls were re-audited after reports that their visible fields did not respond reliably and felt stretched. The prior shared component painted a full-width field over a transparent native menu label, allowing the presentation and actual control to drift apart.

The shared `SelectionField` now uses one full-size native button-backed menu label containing its value, flexible space, and trailing chevron. The entire 220 × 36 field is the click target, its content uses the shared 12-point horizontal inset, and the visual hover boundary matches the interactive boundary. The final packaged app opened the compressor preset menu from the formerly inactive center area, changed its selected value, retained its accessibility label and value, and preserved the compact field appearance.

## Accessibility and hierarchy polish — 2026-08-27

- Selected sidebar rows retain the coral-tinted identity surface but use primary text and icon colors for readable Light-appearance contrast.
- Empty action bars name the actual missing prerequisite instead of displaying a ready state beside a disabled primary action.
- The Splitter slider keeps its visible count and endpoints without rendering a label over the track; its accessibility name and value remain exposed.
- Short Splitter and Filler inspectors end after their content instead of stretching empty card surfaces to preview height.
- Watermark preset slots and Filler styles add a visible checkmark while retaining selected accessibility traits.
- Settings removes the duplicate visible picker label, gives the segmented control the distinct accessibility name “Theme,” wraps its explanatory copy, and sizes to its content.
- About presents product identity, release dependencies, readiness, and license information in a coherent reading order while keeping its actions separate.
- The sidebar replaces its static green “Offline Studio” treatment with one quiet lock-labelled “Private & offline” footer, preserving reassurance without implying a changing connection state.

## Section 1 media-stage surfaces — 2026-08-27

The four empty Section 1 states were compared before and after in the packaged app at the same window size. Upload wells now use one shared adaptive neutral matte derived from the primary semantic color at 5% opacity. The treatment provides a visible interactive region in Light and Dark appearances without turning the entire card gray or changing ordinary control fields.

Populated Watermark, Splitter, and Filler previews use the same token behind the rendered image with a solid semantic border. The image itself remains untinted, so the matte can reveal white canvas edges without affecting color judgment. Empty preview stages continue to show one dashed upload boundary rather than stacking a second bordered canvas around it.

## Header, wordmark, and compression-result refinement — 2026-08-27

The shared line beneath module titles was removed across all five tools. The existing header inset and content spacing still establish the transition into task cards, while eliminating an edge-to-edge boundary that duplicated the cards’ own structure. The divider above the persistent action bar remains because it separates fixed controls from scrolling content.

This 2026-08-27 pass introduced the first dedicated native `BrandWordmark` with rounded San Francisco lettering and a coral italic “Bench” accent. The approved 2026-08-28 option-2 refinement below supersedes its display treatment while retaining the same component boundary and accessibility label.

Bulk Compressor result cards now show successful-input total Before, written-output total After, and the saved byte and percentage change. Failed and skipped files are excluded from both sides of the comparison. The layout adapts from a single row to a stacked result at narrower widths and exposes the complete comparison as one accessibility label.

## Interaction affordances and hit areas — 2026-08-27

Sidebar navigation and the Settings/About rows now use their entire painted rectangles as hit targets rather than inheriting text-only hit testing from plain buttons. Packaged-app QA selected a different module by clicking the trailing whitespace beside its label, and the accessibility tree reported the expected selected destination.

Enabled sidebar rows, upload wells, compact menus, selectable cards, primary actions, and Cancel actions now expose pointing-hand cursors. Unselected sidebar rows and custom controls show a quiet semantic hover surface or border; primary and Cancel actions use one shared brief lift, brightness, and shadow response. Disabled actions intentionally receive neither the hover treatment nor the pointing cursor. The motion component disables its scale response when Reduce Motion is active.

Neutral hover feedback now uses the shared ImageBench coral accent across sidebar rows, upload wells, compact menus, and selectable cards. Blue remains reserved for primary actions and native focus/active-control semantics, avoiding a competing interaction accent without weakening the action hierarchy. Packaged-app captures in `Audit/HoverColor/` confirm the coral menu outline/surface and stronger coral selected-row hover while retaining the blue primary action treatment.

The app shell now uses the same flat depth language as the workspace: an opaque semantic canvas behind the sidebar, one hairline divider for separation, and a compact flat coral brand mark. The material-backed navigation split column was removed because macOS continued drawing elevation at its edge even after the custom surface became opaque. The replacement rail retains a labelled toolbar toggle and Control-Command-S shortcut, and hiding/restoring it preserves module state. `Audit/SidebarConsistency/04-flat-divider-no-shadow.png` records the final packaged boundary; `Audit/HoverColor/03-flat-sidebar-coral-hover.png` records the coral selected-row hover.

## Watermark image-preset restoration — 2026-08-27

Selecting a saved image preset now cancels and invalidates any delayed preview refresh produced by the editor reset that precedes preset application. A generation check also prevents a late preset decode from replacing a newer explicit watermark choice. A slot-2 regression test recreates the SwiftUI text-reset callback and confirms that the managed signature image remains visible after the delayed work settles.

## Verification

### Condensed editorial wordmark — 2026-08-28

- The selected option-2 reference was translated into the native sidebar with locally bundled Archivo Narrow at a compact 23-point bold treatment, tight tracking, primary-color lettering, and one coral underscore.
- The full product name remains one accessibility label; task, control, and module typography remains semantic San Francisco.
- The font and its SIL Open Font License are present in the packaged app, register without a system installation, and require no runtime network access.
- `Audit/BrandWordmark/02-reference-comparison.png` places the selected visual and the packaged implementation together. The shared condensed silhouette, adaptive primary-color wordmark, coral mark, and trailing coral accent pass the approved direction at the real sidebar scale in Dark appearance; no P0, P1, or P2 visual issues remain.

### Watermark text-field focus and default — 2026-08-28

- The scrollable inspector now reserves four points around its contents so the native blue keyboard-focus halo remains fully visible instead of being clipped at the text field boundary.
- Selecting an empty preset in the packaged app preloads only `© `, leaves the insertion point after the symbol, and keeps the value fully editable and removable.
- `Audit/WatermarkTextField/01-focus-ring-and-copyright-default.png` records the focused field and empty-preset default without changing or deleting the saved preset in slot 1.

### Attention-to-detail interaction pass — 2026-08-28

- The sidebar's flat coral photo-stack mark is now the single product identity used by the packaged macOS icon and About surface.
- Settings and About share a 32-point circular close control with visible padding around the X, while retaining the Close accessibility label and Escape shortcut.
- The full-width Bulk Compressor Command Details header now toggles the log, exposes Expanded/Collapsed state, and keeps exact output selectable when open.

### Module-header icon removal — 2026-08-28

- All five workspace headers now begin directly with their title and subtitle; module icons remain available in the persistent sidebar where they aid navigation.
- Removing the duplicate icon tiles preserves the shared header padding, content rhythm, and accessible title hierarchy.

### Settings, watermark presets, and EXIF Viewer — 2026-08-28

- The packaged EXIF Viewer exposes an empty image/RAW drop target, searchable Metadata inspector, histogram legend, read-only status copy, and disabled-state guidance through the native accessibility tree.
- A generated JPEG fixture confirmed the Preview, log-scale luminance/RGB histogram, and File, Image, Capture, Camera & Lens, Exposure, Location, and Rights & Workflow groups at the minimum workspace size. No personal image or metadata was retained as QA evidence.
- Settings presents Appearance, Startup, Watermark Presets, and Privacy as four distinct cards. The startup menu lists the five modules, and global preset cleanup remains disabled when no slots are saved.
- Watermark Studio exposes separate Reset Selected and Reset All actions beneath its four slots. Both are disabled for an empty store and use destructive confirmation before durable deletion when enabled.
- The EXIF fixture and extension tests cover the local metadata pipeline; representative real RAW files and camera-generation codec coverage remain a hardware validation follow-up.

- Swift formatting and strict lint: passed.
- Focused render/filler/watermark regression suite: 22 tests, zero failures.
- Focused EXIF/watermark regression suite: 24 tests, zero failures.
- Full debug suite: 107 tests executed, two opt-in diagnostics skipped, zero failures.
- Full optimized suite: 107 tests executed with normal macOS graphics access, two opt-in diagnostics skipped, zero failures.
- Opt-in scale run: 200 images compressed successfully; 1,200 files scanned successfully.
- Opt-in private-folder run: 337 recursively discovered screenshots (148.6 MB) compressed with metadata preservation, zero failures, zero skips, and disposable output cleanup in 383.5 seconds.
- Mixed-folder battle tests: six image formats, non-image clutter, corrupt supported files, nested folders, Unicode/quoted names, duplicate stems, and uppercase HEIC/HEIF passed.
- Final release app packaged successfully with bundled offline dependencies; signature/linkage checks and the real bundle smoke encode passed.
- The four original tool empty-state captures passed visual comparison in both Light and Dark appearances. The new EXIF Viewer empty and generated-metadata states passed in Light without changing the user's saved appearance preference.

The 2026-08-27 production launch walkthrough reconfirmed the four tool empty states, Settings, About, and Dark appearance in the current packaged app. Product UI health is green in the inspected scope; repository, CI, dependency-integrity, signing, hardware-accessibility, and real-camera validation gates are tracked separately in `Design/PRODUCTION_LAUNCH_AUDIT.md`.

final result: passed
