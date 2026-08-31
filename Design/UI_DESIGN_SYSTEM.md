# ImageBench UI Design System

Status: normative

Visual direction: Gallery Workbench (option 3)

Last reviewed: 2026-09-01

This document is the shared UI contract for ImageBench. It exists so contributors and coding agents can extend the app without inventing a new visual language on each screen.

Use it together with `Sources/ImageBench/Shared/DesignSystem.swift` and `WorkspaceComponents.swift`. Those Swift files are the source of truth for executable tokens and reusable components; this document defines why they exist, when to use them, and how new UI should behave.

## Source-of-Truth Order

When references disagree, resolve them in this order:

1. Native macOS behavior, accessibility, and user safety.
2. Tested product behavior and privacy invariants in [AGENTS.md](../AGENTS.md).
3. Semantic tokens and components in `Shared/DesignSystem.swift`.
4. Rules and patterns in this document.
5. The shipped Gallery Workbench screens and current user-provided screenshots.
6. The selected visual reference in `Design/Concepts/option-3-gallery-workbench.png`.
7. Older screenshots and exploratory concepts.

The visual reference establishes direction, not permission to replace native controls with imitations.

## Product Character

ImageBench should feel like a quiet photographic workbench: capable, warm, local, and trustworthy. It is a craft utility, not a marketing site and not an AI dashboard.

The interface should communicate:

- **Local confidence:** processing, dependencies, destinations, and outcomes are explicit.
- **Calm capability:** powerful operations are arranged as understandable steps.
- **Photographic warmth:** coral identity accents add character without tinting the whole workspace.
- **Mac familiarity:** system typography, SF Symbols, native controls, materials, focus behavior, and sheets remain recognizable.
- **Operational honesty:** failures, skipped files, exact commands, and recovery actions are visible.

Avoid excessive glass, ornamental gradients, neon effects, floating chat metaphors, oversized empty hero areas, and decorative controls that obscure the task.

## Design Principles

### Workflow before decoration

Every tool follows the same narrative: choose input, configure, choose or confirm output, run, then review the result. Number major steps when sequence helps comprehension.

### Native before bespoke

Prefer SwiftUI or AppKit controls for buttons, menus, pickers, toggles, disclosure groups, progress, file panels, sheets, focus, and keyboard behavior. Custom presentation may wrap a native control but must not weaken its semantics.

### Identity and action are different

Coral identifies ImageBench, selected navigation, step numbers, drop targets, and preview guides. The macOS blue action color identifies the primary operation. Do not turn every important element coral.

### Human result first, technical detail second

Show succeeded, needs-attention, skipped, saved-size, and recovery actions before the command console. Keep exact commands selectable and available through a disclosure surface.

### State must be unmistakable

Empty, drop-targeted, ready, running, succeeded, partial failure, cancelled, disabled, and dependency-missing states need distinct copy and appropriate iconography. Never rely on color alone.

### Originals remain visually and operationally protected

Copy should reinforce that originals stay untouched when relevant, without repeating the promise in every control.

## Color Tokens

Never use literal colors in tool views when a semantic token fits. Add or revise tokens in `PFTheme` first.

| Role | Swift token | Reference value | Use |
| --- | --- | --- | --- |
| Brand coral | `PFTheme.coral` | `#F05929` | Tool identity, selected navigation, step numbers, drop focus, preview guides |
| Primary action | `PFTheme.action` | `#0D63E6` | App tint and primary bordered-prominent actions |
| Success | `PFTheme.success` | `#29A64D` | Completed/ready states and positive metrics |
| Warning | `PFTheme.warning` | `#ED8A14` | Recoverable attention and partial failure |
| Danger | `PFTheme.danger` | `#D6332E` | Destructive actions and failed items |
| Hover surface | `PFTheme.hoverSurface` | Coral at 7.5% | Hover fill for neutral interactive surfaces |
| Hover border | `PFTheme.hoverBorder` | Coral at 55% | Hover outline for neutral interactive surfaces |
| Canvas | `PFTheme.canvas` | Dynamic system color | Main window background |
| Surface | `PFTheme.surface` | Dynamic system color | Cards and grouped work areas |
| Secondary surface | `PFTheme.secondarySurface` | Dynamic control background at low opacity | Quiet inset controls only |
| Media stage | `PFTheme.mediaStageSurface` | Dynamic primary color at 5% | Empty upload wells and populated image-preview mattes |
| Border | `PFTheme.border` | Dynamic separator at 42% | Card and control boundaries |
| Selected sidebar | `PFTheme.sidebarSelection` | Coral at 14% | Current tool row only |

Rules:

- Use dynamic system foreground colors (`.primary`, `.secondary`, `.tertiary`) for text.
- Apply `PFTheme.mediaStageSurface` only to the inner upload or preview canvas, never to the enclosing `SurfaceCard` or the image itself.
- Selected sidebar rows use primary text and icon colors over the coral-tinted surface; coral text does not provide sufficient contrast at body size in Light appearance.
- Neutral interactive surfaces use the shared coral hover fill and border. macOS blue remains reserved for primary actions, native focus indication, and active system controls.
- Use semantic success, warning, and danger colors only with an icon and text label.
- Maintain readable contrast in System, Light, Dark, and Increase Contrast modes.
- Reserve the existing coral gradient for the shared sidebar/app icon mark. Do not add decorative gradients elsewhere without a reviewed design decision.
- Do not place important text directly on photo content without a tested contrast treatment.

## Typography

Use San Francisco through SwiftUI semantic styles for task and control typography. The explicitly approved sidebar product wordmark is the one display-font exception: it uses the bundled Archivo Narrow variable font at bold weight, compact tracking, and a short coral underscore while retaining “ImageBench” as one accessibility label. The font is registered from the app bundle and must never require a network request or a system installation.

| Purpose | Style |
| --- | --- |
| About/product identity | `.largeTitle.bold()` |
| Tool title and prominent values | `.title2` with bold or semibold weight |
| Numbered section title | `.headline` |
| Standard control/body copy | `.body` |
| Status and supporting hierarchy | `.subheadline` |
| Help and consequence text | `.caption` |
| Tertiary labels and paths | `.caption2` |
| Commands, versions, numeric diagnostics | Monospaced design or `.monospacedDigit()` |

Rules:

- Build hierarchy with semantic style and weight, not arbitrary point sizes.
- Keep tool subtitles to one concise sentence.
- Use sentence case for headings and buttons. Avoid decorative uppercase navigation labels.
- Let paths and filenames truncate before primary actions do.
- Use monospaced digits for values that change during interaction.

## Spacing and Shape

The canonical spacing rhythm is based on 4-point increments:

| Token concept | Value | Typical use |
| --- | ---: | --- |
| Micro | 4 | Closely related label/detail pairs |
| Compact | 8 | Controls within one group |
| Control | 12 | Icon/text separation and compact insets |
| Section | 16 | Major groups and column gap |
| Card inset | 18 | `SurfaceCard` padding |
| Screen gutter | 24 | Tool header, content, and action-bar horizontal padding |
| Spacious | 32 | Exceptional separation, not routine stacking |

Intermediate values already present in shared components—6, 10, 13, 14, and 20—are component details, not a second spacing scale. Reuse the component rather than copying those numbers.

Shape rules:

- Standard inset control: 8-point continuous radius.
- Drop well and compact console surface: 10-point continuous radius.
- Primary surface card: 12-point continuous radius.
- Large branded About tile: 20-point continuous radius.
- Pills use `Capsule`.
- Use a one-point semantic border for grouped surfaces. Avoid stacking heavy shadows and borders.

## Window and Layout

- Minimum content size: 1080 × 720 points.
- Default content size: 1440 × 900 points.
- Sidebar: fixed at 230 points. A toolbar toggle and Control-Command-S hide or restore it without changing module state.
- Main content gutter: 24 points.
- First content surface begins 18 points below the shared header region. Whitespace, rather than a decorative divider, separates the module identity from its task content.
- Standard major-region gap: 16 points.
- Persistent action bar stays at the bottom of each tool and must remain visible while content scrolls.

Use one of two established tool layouts:

### Workbench grid

Use for tasks where source and configuration have comparable importance, currently Bulk Compressor.

- Two equal flexible columns.
- Cards top-align, even when their heights differ.
- Results and technical disclosure span the full width below the grid.
- The scroll view owns variable-height content; the action bar remains outside it.

### Preview and inspector

Use for visual transformations, currently Watermark Studio, Splitter, and Aspect Ratio Filler.

- Flexible preview stage on the left.
- 340-point inspector on the right.
- Preview and inspector top-align.
- Step 1 and Step 2 headings share the same top baseline at every supported window size.
- Preview receives the majority of additional window space.
- Short inspectors size to their content instead of stretching an empty surface to preview height. Only content that genuinely needs the available height, such as Watermark's scrollable editor, should fill the column.
- If future content cannot remain usable at the minimum window size, introduce a deliberate compact layout rather than allowing controls to clip.

## Shared Components

### `ToolHeader`

Use once at the top of every tool. Supply a short noun-based title and a single outcome-oriented subtitle. Module identity icons live in the persistent sidebar navigation and are not repeated in the workspace header.

Do not place a divider beneath the header. Its title, subtitle, and bottom spacing provide sufficient hierarchy; the first task surface supplies the next meaningful boundary.

### `BrandWordmark`

Use only for the persistent ImageBench identity in the sidebar. It uses bold Archivo Narrow in the primary text color with one coral underscore, exposes the product name as one accessibility label, and keeps coral as an identity accent rather than an action color. If registration fails, SwiftUI may fall back to a system face without preventing the app from launching.

Pair it with the flat coral `SidebarBrandMark`. The same white photo-stack on coral artwork is used for the macOS app icon and About identity so the product has one recognizable mark at every scale. The sidebar uses an opaque `PFTheme.canvas` background and one semantic hairline divider; it must not use a material-backed split-view column, baked icon shadows, or resting elevation against the flat workspace.

### `SurfaceCard`

Use for a coherent task region, not every individual control. Cards must contain a clear heading or an immediately understandable result. Do not nest `SurfaceCard` inside another `SurfaceCard`.

### `SectionHeading`

Use for major groups. Add a number only when it communicates task order. Numbering restarts per tool and follows the visible workflow.

### `FileDropWell`

Use as both a button and drop destination. It must:

- work with click-to-browse as an equal path;
- show accepted-content guidance in the empty state;
- visibly respond to drag targeting;
- have an explicit accessibility label and hint;
- replace generic instructions with a useful selection summary after input is accepted.
- use the shared subtle gray upload surface so the full interactive boundary is immediately visible without recreating the older heavy-gray treatment.

When a `FileDropWell` is shown inside `PreviewStage`, the empty stage must not draw a second background or border. Use `PreviewStage(isCanvasVisible: false)` until a real image is present. The `SurfaceCard` plus one dashed upload region is the complete empty-state hierarchy.

Populated `PreviewStage` surfaces use the same adaptive media-stage matte with a solid border. The matte sits behind the rendered image so white canvas edges remain visible without altering image colors.

### `ImageDropPrompt`

Use the shared prompt inside Watermark Studio, Splitter, and Filler empty states. It owns the 40-point SF Symbol, compact vertical rhythm, headline, caption treatment, and centered alignment. Feature copy may say “Photo” or “Image,” but spacing and icon scale must not drift.

### `StatusPill`

Use for compact, persistent health or state labels. Do not use it for long errors, primary actions, or raw progress.

### `ResultMetric`

Use for numeric batch outcomes. Pair the icon/color with explicit text such as Succeeded, Needs Attention, or Skipped. Keep categories in the same order across screens.

### `SelectionField`

Use the shared compact native `Menu` for preset and policy choices that need explanatory copy. Keep the control leading-aligned at the shared 220-point width, inset its value and indicator by 12 points, and place the helper beneath it. The value, flexible middle space, and trailing indicator must live in one full-size native menu label so every point inside the visible 220 × 36 field opens the menu. Its subtle gray fill, hover border, keyboard focus, accessibility label, and accessibility value make the interaction clear without stretching the control across its container.

### `SelectableCardButton`

Use the shared native-button card for small finite option sets that benefit from remaining visible, currently Watermark preset slots and Filler fill styles. Cards use the same quiet surface, coral selected border/tint, visible checkmark, minimum height, and selected accessibility trait. The checkmark keeps selection understandable without relying on color alone. Keep sets to one compact row where labels remain readable; use a menu or another native control when the option count would force crowding.

### Persistent action bar

Every processing tool ends with one. The left side communicates readiness, progress, result, or error plus one line of supporting context. The right side contains the primary action and only the recovery actions necessary at that moment.

When the primary action is disabled because a prerequisite is missing, the title names that next step—such as “Add an image to begin” or “Choose an output folder.” Reserve “Ready” for a state in which the primary action can actually run.

Primary buttons:

- Use `.borderedProminent` and `.controlSize(.large)`.
- Use a concise verb when the surrounding module makes the object unambiguous: “Export.” Keep a verb plus object when it communicates useful dynamic state, such as “Compress 8 Photos” or “Split into 3 Parts.”
- Disable until required input and output choices are valid.
- Replace with a clearly labeled Cancel action while work is running.
- Use the shared 160-point minimum action width so tool changes do not shift the primary-action region.

Running-state cancellation uses `ToolCancelButton` in every tool. It is large, destructive, and responds to the standard Escape shortcut. Do not create a feature-specific Cancel style.

## Interaction-State Contract

| State | Required presentation |
| --- | --- |
| Empty | Specific next action, accepted-input guidance, disabled primary action |
| Drop targeted | Coral border and subtle coral fill; no layout jump |
| Ready | Input summary, destination, configuration, dependency/validation status |
| Running | Determinate progress when measurable, current item, Cancel action |
| Success | Human-readable result, output/reveal action, saved-size when available |
| Partial failure | Succeeded/failed/skipped counts, retry and reveal-failed actions, healthy output retained |
| Cancelled | Completed and skipped work remain distinguishable; no success wording |
| Dependency missing | Explanation plus install action close to the affected workflow |
| Validation error | Plain-language remedy near the relevant region; technical detail may follow |

Avoid toast-only outcomes. Important batch results must remain visible until the next operation or explicit reset.

## Imagery and Icons

- Use actual decoded user images for previews and thumbnails.
- Preserve aspect ratio; use `scaledToFit` for full previews and `scaledToFill` only for intentionally cropped thumbnails.
- Use consistent continuous corner radii and clip thumbnail overflow.
- Large-batch thumbnail strips must adapt the number of visible previews to their available width; they must not widen the containing card or displace adjacent actions.
- Use SF Symbols for interface icons. Match symbol meaning, weight, and scale to nearby text.
- Do not use emoji, text glyphs, handcrafted SVGs, or placeholder artwork as interface icons.
- Hide purely decorative symbols from accessibility; label meaningful icon-only buttons.

## Motion and Feedback

ImageBench relies primarily on native state transitions. Motion explains change and must never mask avoidable processing or delay navigation.

- The full painted bounds of sidebar rows, upload wells, selection fields, selectable cards, and disclosure headers are their hit targets; never limit activation to text or icons.
- Enabled app action surfaces use the pointing-hand cursor. Disabled actions remain inert and retain the standard arrow cursor.
- Sidebar rows and neutral custom controls reveal the shared coral hover surface or border. Primary and Cancel actions retain their semantic action colors and use the shared brief brightness, lift, and shadow treatment; do not introduce feature-specific hover effects.
- Respect `accessibilityReduceMotion`.
- Use `PFMotion.quick` for selected controls and module crossfades; do not invent slower per-screen navigation timing.
- Keep module view models alive across sidebar navigation so switching preserves work and does not repeat setup.
- Update expensive previews off the main thread and crossfade only the finished image.
- Avoid looping ambient animation.
- Do not animate progress inaccurately.
- Keep drag highlighting, disclosures, and sheet presentation native unless a demonstrated usability need requires more.
- Preserve input and result state during non-destructive transitions.

## Accessibility

All new or changed UI must be reviewed for:

- full keyboard traversal and visible native focus;
- VoiceOver names, values, hints, headings, and status updates;
- meaning that survives color removal;
- Dynamic Type behavior available on macOS and text truncation at minimum window size;
- Light, Dark, System, and Increase Contrast appearances;
- Reduce Motion behavior;
- sufficiently large native click targets and spacing between adjacent actions;
- preview overlays that do not block interaction or become the only explanation of output.

Do not replace a native control solely to achieve a closer screenshot match.

## Content Design

Voice is calm, direct, and specific.

- State what will happen: “Split into 3 Parts.”
- State what happened: “Saved 3 parts to Exports.”
- State the remedy: “Choose a writable output folder.”
- Prefer “Needs Attention” for a recoverable batch category and “Failed” for a specific failed file.
- Avoid hype, jokes during errors, vague “Something went wrong” messages, and AI-centric language.
- Use ellipses only when an action opens a panel or requires another decision, except for the deliberately compact primary “Export” action.
- Keep offline/privacy statements factual: no uploads, no analytics, originals untouched.
- Present the permanent privacy guarantee as one quiet secondary sidebar footer, not a green live-status indicator. Reserve success color for state that can actually change.

## Tool-Specific Consistency

### Bulk Compressor

- Workbench grid with source on the left and output/configuration on the right.
- If the user does not choose a destination, show the planned `Compressed Output` folder beside the selected inputs; do not create it until compression starts.
- Results precede command details.
- Completed results compare the combined size of successful inputs with their output size using explicit Before and After labels, followed by the saved amount and percentage. Failed and skipped files are excluded so the comparison remains honest.
- Metadata is a single policy picker, not overlapping checkboxes.
- Custom quality uses a 0–100 native slider in five-point steps with visible endpoints; fixed presets keep their exact recipe values until the user chooses Custom.
- Exact commands remain selectable and collapsed by default.
- The full Command Details header row toggles the technical disclosure; activation is not limited to its chevron.

### Image Splitter

- Preview/inspector layout.
- Slice guides use coral dashed lines over the exact fitted-image bounds.
- Direction, count, and output appear in workflow order.
- Slice count uses a discrete native slider from 2–12, with a persistent numeric value, visible endpoints, and decrement/increment buttons for precise adjustment.
- Slice count is limited to 12 in both the UI and engine; one slice is excluded because it performs no split.
- Explain that remainder pixels are preserved.
- Within Number of Slices, show the source dimensions, simplified ratio, and decimal ratio beside the resulting per-row or per-column geometry. If remainder pixels produce different part sizes, show an honest range instead of one misleading value.
- Show the 16:10/two-part and 12:5/three-part preparation hints only when those slice counts are selected.

### Aspect Ratio Filler

- Preview/inspector layout.
- Preview updates after ratio/fill changes without blocking the main thread.
- Report the current image dimensions and aspect ratio after selection.
- Call the output choice “Canvas Ratio” so it is not confused with the source ratio.
- Present the three fill styles as one row of `SelectableCardButton` choices, matching Watermark preset selection while retaining native button semantics.
- Explain fill consequences in one short sentence.
- Reinforce that the original remains centered and uncropped.

### Watermark Studio

- Use Preview and Inspector with the source photo receiving most of the workspace.
- Keep direct drag placement on the preview as the primary spatial control; provide clear text guidance and a keyboard-friendly Center action.
- Keep a persistent, high-contrast coral dashed selection outline around the editable watermark while a preview is present; draw it inside the watermark bounds and never include it in exports.
- Show exactly four compact preset slots with distinct selected and saved/empty states.
- On the first Watermark Studio load, select slot 1 and apply it when saved. Selecting an empty slot resets the editor to a text watermark prefilled with an editable `©` symbol plus the default size, opacity, color, and placement.
- When a saved image preset is selected, its managed asset load owns the preview until it finishes. Cancel or invalidate older editor-reset preview work so a late clean-slate refresh cannot clear the restored signature.
- Explain that export updates the selected preset so persistence is predictable.
- Text and image watermark modes share size, opacity, and placement controls.
- The editor-only dashed selection outline must never appear in exported pixels.
- Use relative percentage sizing and placement so saved presets remain meaningful across different source dimensions.
- Use Arial for text-watermark editing, preview, and export so the visible editor and rendered output remain consistent.
- Keep enough inset around the text field for the native keyboard-focus halo to render without clipping inside the scrollable inspector.
- Place destructive preset reset actions below the preset choices, require confirmation, and distinguish resetting the selected slot from resetting all four slots.

### EXIF Viewer

- Use the established Preview/Inspector layout: preview and histogram on the left, searchable metadata on the right.
- Keep the empty preview to one dashed upload boundary. A populated preview may use the shared media-stage surface and solid semantic border.
- Present luminance, red, green, and blue together in a bounded log-scale histogram with a text legend so interpretation never relies on color alone.
- Group metadata by user intent—File, Image, Capture, Camera & Lens, Exposure, Location, Rights & Workflow, and RAW & Maker Notes—instead of exposing ImageIO dictionary structure.
- Keep values selectable, searchable by label or value, and read-only. Never imply that RAW recognition guarantees a preview when the installed macOS codec cannot decode that camera generation.
- When valid GPS coordinates exist, keep their map actions within the Location metadata group beside the coordinate they act on. Keep the coordinate selectable, disclose that map services may connect to the internet, and never load a map until the user explicitly requests it.

## Do and Do Not

Do:

- reuse `ToolHeader`, `SurfaceCard`, `SectionHeading`, `FileDropWell`, `StatusPill`, and `ResultMetric`;
- add semantic tokens before adding visual literals;
- keep the primary task visible and the technical log secondary;
- capture realistic empty, running, success, and partial-failure states;
- compare visible changes against the selected reference and existing screens.

Do not:

- create a second accent palette for a new tool;
- use coral as both brand and primary-action color;
- add a card around every row;
- hide errors in a console;
- silently overwrite output or imply sources are modified;
- introduce web UI, Electron, or custom control replicas for visual convenience;
- copy one-off spacing/radius values when a shared component already owns them.

## UI Change Workflow

1. Read this document, [AGENTS.md](../AGENTS.md), and the relevant existing view.
2. Identify the existing layout and shared components that fit the task.
3. If the change requires a new visual rule, propose and document the semantic rule before proliferating it.
4. Implement with native controls and shared tokens.
5. Exercise empty, ready, running, success, failure, cancellation, and disabled states as applicable.
6. Verify Light and Dark appearances plus keyboard and VoiceOver semantics.
7. Capture the changed screen temporarily at the standard window size.
8. Compare it with the selected concept and adjacent tools; fix P0/P1/P2 drift.
9. Update the text record in [UI_QA.md](UI_QA.md) when a visible contract materially changes. Do not commit generated screenshots unless the repository owner explicitly approves a durable reference.

## Pull-Request Checklist

- [ ] Reuses the established layout family.
- [ ] Uses semantic colors and system typography.
- [ ] Uses shared components or explains why a new one is required.
- [ ] Primary action remains persistent and correctly enabled/disabled.
- [ ] All relevant interaction states are understandable without color alone.
- [ ] Keyboard, VoiceOver, Light/Dark, contrast, and reduced-motion behavior were considered.
- [ ] Copy follows the product voice and uses ellipses correctly.
- [ ] Screenshots show realistic content rather than placeholder blocks.
- [ ] Visual comparison evidence is updated for material changes.
- [ ] Processing behavior and offline/privacy guarantees remain unchanged.

## Decision Record

- **2026-08-21 — Gallery Workbench selected:** option 3 established the warm coral identity, compact sidebar, two-column compressor workspace, persistent results/actions, and progressive technical disclosure.
- **2026-08-21 — Native semantics retained:** SF Symbols and native SwiftUI/AppKit controls take precedence over pixel-level imitation.
- **2026-08-21 — Coral/blue separation:** coral is the product identity; macOS blue remains the action language.
- **2026-08-21 — Technical transparency is progressive:** exact commands remain available but no longer dominate human-readable results.
- **2026-08-21 — ImageBench selected:** the app, executable, bundle, documentation, and brand assets use ImageBench as the product name.
- **2026-08-21 — Polish without structural drift:** the shipped Gallery Workbench layout remains the visual source of truth. Refinements may lighten nested surfaces, align controls, reduce duplicate actions, and clarify results without replacing its information architecture.
- **2026-08-24 — Familiar affordances:** upload wells use a subtle neutral fill, selected sidebar rows use one uninterrupted coral-tinted surface, and menu fields combine modern spacing with a conventional macOS popup indicator.
- **2026-08-24 — Watermark Studio:** direct manipulation uses the existing Preview and Inspector layout; four fixed preset slots save only after export, and image watermark assets are copied into durable app-managed storage.
- **2026-08-24 — Release-candidate audit:** all four tools retain the Gallery Workbench hierarchy; visible sheet close controls, familiar dropdown affordances, subdued upload wells, and uniform sidebar selection remain cross-screen requirements.
- **2026-08-24 — Cross-module alignment pass:** processing content begins 18 points below the header, Preview and Inspector headings top-align, empty Preview stages avoid nested borders, selection fields are full-width and leading-aligned, empty-image prompts share one component, and primary/Cancel actions keep a stable footprint.
- **2026-08-24 — Split count control:** Image Splitter uses a discrete 2–12 native slider with a visible value, endpoints, and precise minus/plus actions; the one-slice no-op is not offered.
- **2026-08-24 — Shared selectable cards:** Watermark preset slots and Aspect Filler styles share one native selectable-card primitive with consistent selected, hover, keyboard, and accessibility semantics.
- **2026-08-24 — Responsive navigation and previews:** tool models persist across sidebar changes, navigation and selected cards use the 140 ms reduce-motion-aware transition, hidden compressor logs do not trigger redraws, thumbnails are bounded and asynchronous, and interactive previews render away from the main thread.
- **2026-08-27 — Compact functional menus:** preset and policy menus use one visible native label as both presentation and hit target, remain leading-aligned at 220 points, and expose separate accessibility labels and values.
- **2026-08-27 — Accessibility polish:** selected navigation uses primary foregrounds over the coral tint; selectable cards add a checkmark; disabled action bars name their missing prerequisite; short inspectors size to content; Settings copy wraps; and About exposes meaningful accessibility groups.
- **2026-08-27 — Quiet privacy footer:** the persistent offline guarantee uses one secondary lock-labelled footer; it does not impersonate a changing connection or dependency status.
- **2026-08-27 — Shared media stage:** Section 1 upload wells and populated previews use one adaptive neutral matte at low opacity; source pixels remain untinted, and empty previews retain a single dashed interaction boundary.
- **2026-08-27 — Quiet headers and expressive wordmark:** module headers rely on whitespace instead of a decorative divider, while the persistent sidebar identity uses a rounded native wordmark with a coral italic “Bench” accent.
- **2026-08-27 — Honest compression comparison:** completed compressor results show successful-input size Before and output size After, plus the signed size change and percentage; failed and skipped files never inflate the savings claim.
- **2026-08-27 — Whole-surface interaction affordance:** sidebar rows and custom action surfaces align their hover boundary, pointing cursor, and hit target; primary and Cancel actions share one Reduce Motion-aware hover treatment.
- **2026-08-27 — Coral neutral hover language:** sidebar rows, upload wells, compact menus, and selectable cards use shared coral hover surfaces and borders; blue remains the primary-action language.
- **2026-08-28 — Flat sidebar shell:** the sidebar uses an opaque canvas and a flat coral brand mark rather than a raised in-workspace icon treatment.
- **2026-08-28 — Shadow-free sidebar boundary:** a fixed flat rail and one semantic divider replace the material-backed navigation split column while retaining the toolbar toggle, Control-Command-S shortcut, accessibility label, and persistent module state.
- **2026-08-28 — Unified product mark and generous utility targets:** the flat coral photo-stack mark now identifies the sidebar, Dock, and About surface; sheet close buttons use a padded circular target, and the compressor technical disclosure toggles from its full header row.
- **2026-08-28 — Single module-icon location:** module icons remain in sidebar navigation and are omitted from workspace headers, leaving titles and subtitles to establish each screen's hierarchy without repetition.
- **2026-08-28 — EXIF information architecture:** the read-only EXIF Viewer uses the shared Preview/Inspector workspace, bounds histogram work, groups metadata by photographic intent, and treats installed macOS RAW codecs as the explicit capability boundary.
- **2026-08-28 — Condensed editorial wordmark:** the approved option-2 identity replaces the rounded coral-split lettering with bundled bold Archivo Narrow, primary-color lettering, compact tracking, and one coral underscore. All module and control typography remains native San Francisco.
- **2026-08-28 — Preference and preset ownership:** Settings owns durable startup preferences and global preset cleanup; Watermark Studio retains selected-slot reset beside the preset editor. Both destructive paths require confirmation.
- **2026-09-01 — Explicit EXIF maps:** validated GPS coordinates may open a native MapKit sheet or Google Maps only through named user actions; ordinary metadata inspection remains local and does not preload map services.
- **2026-09-01 — Legible image preparation controls:** Image Splitter compares source and per-part geometry from the export's exact slice boundaries, while Bulk Compressor's Custom quality uses a 0–100 scale in five-point steps without changing fixed preset recipes.

Future design decisions should be appended here when they change a cross-screen rule. Screen-specific implementation notes belong beside the relevant view, not in this system document.
