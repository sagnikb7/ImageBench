# ImageBench Code Quality Guide

This document is the repository contract for clean, maintainable code. It applies equally to human-written and AI-assisted changes.

The goal is not maximum abstraction. The goal is code whose responsibilities, invariants, and failure behavior are obvious to the next contributor.

## Core Principles

### Keep dependency direction simple

```text
SwiftUI view
  → @MainActor view model
    → engine or shared service
      → Foundation / AppKit / Core Image / ImageIO / Process
```

- Views render state and forward user intent.
- View models own observable state, task lifecycles, and orchestration.
- Engines own deterministic image-processing behavior.
- Services own reusable platform integration such as processes, rendering, panels, and Finder actions.
- Plain models carry data across boundaries.

Dependencies should point inward toward behavior. An engine must not import a tool view or mutate UI state.

### Prefer cohesive modules

Organize code by feature first and shared responsibility second:

- `Tools/<Tool>/`: tool-specific view, view model, engine, and models.
- `Services/`: cross-feature operational services.
- `Shared/Files/`: file capabilities, scanning, panels, and Finder integration.
- `Shared/`: design primitives, reusable workspace components, formatting, and app-wide models.

A file should have one reason to change. View models do not live in view files. Unrelated utilities do not accumulate in a generic `Utils.swift` or `Models.swift` file.

### Reuse stable concepts, not coincidental syntax

Extract shared code when at least one is true:

- the behavior expresses a repository invariant;
- two or more features use the same concept and should evolve together;
- duplication has already caused inconsistent behavior;
- the extraction gives a platform operation one testable owner.

Do not create a generic abstraction merely because two blocks currently look similar. A small amount of obvious feature-specific code is better than a configurable component with many flags.

Current examples:

- `ToolWorkspace`, `PreviewInspectorLayout`, and `ToolActionBar` own cross-tool layout contracts.
- `FolderPickerRow` and `SelectedImageRow` own repeated interaction surfaces.
- `ImageFileSupport` owns format capabilities instead of treating every decodable image as valid for every tool.
- `ImageRenderer.writeAtomically` owns source-path protection and transactional single-image export.
- `CompressionInputScanner` owns compressor discovery and output exclusion.
- `WatermarkPresetStore` owns the durable four-slot manifest and managed image assets.
- `WorkspaceFileActions` owns Finder/open behavior.

## Naming

- Name types after responsibilities: `CompressionInputScanner`, not `Helper`.
- Name capability checks explicitly: `supportsFormatPreservingOutput`, not `isValid`.
- Use verbs for actions and queries: `reveal(files:)`, `scan(folder:)`, `compose(...)`.
- Avoid vague containers such as `Common`, `Manager`, `Misc`, `Thing`, or `Utils` unless the responsibility is genuinely precise.
- Avoid abbreviations except established domain terms such as EXIF, GPS, JPEG, PPM, and CLI.
- Prefer product language in views and domain language in engines.

## Functions and Types

- Keep functions at one level of abstraction.
- Use early exits for invalid preconditions.
- Pass immutable snapshots into background tasks instead of reading mutable view-model state during work.
- Prefer value types for options, jobs, results, and errors.
- Keep mutable shared state isolated to `@MainActor` view models or a clearly synchronized service.
- Avoid boolean parameters whose call sites are unclear; prefer enums or named configurations.
- Do not expose a broader API than consumers require.

There is no arbitrary line-count limit. Split a type when its responsibilities diverge, not simply when a file becomes long.

## Error Handling

- Use typed `LocalizedError` values at engine and service boundaries.
- Preserve the original context needed to diagnose a failed file or command.
- Translate technical failures into actionable UI copy in the view model.
- Never use `try?` when failure changes user-visible correctness. It is acceptable for best-effort cleanup and optional metadata inspection.
- Never leave partial output after a failed operation.
- Batch operations isolate per-file failures unless a preflight or dependency failure invalidates the whole batch.

## Concurrency

- UI-observable state is `@MainActor` isolated.
- CPU, image, scan, and process work must not run on the main actor.
- Cancellation must propagate to detached work and subprocesses.
- Long loops check cancellation at useful boundaries.
- Capture immutable values before starting a task.
- Prevent stale asynchronous results from replacing newer user selections.
- Do not add `@unchecked Sendable` without documenting the synchronization that makes it safe.

## Files and Formats

- Treat “decodable,” “compressible,” and “format-preserving output” as separate capabilities.
- Never infer encoder behavior solely from a filename extension.
- Keep source files read-only.
- Route single-image replacement through `ImageRenderer.writeAtomically`; do not write directly to an input-derived destination.
- Use collision-safe output naming.
- Exclude output directories from recursive input discovery.
- Pass executable arguments directly to `Process`; shell-quoted text is display-only.

## SwiftUI

- Follow `Design/UI_DESIGN_SYSTEM.md`.
- Keep processing logic out of `body` and view helpers.
- Reuse shared workspace components for cross-tool structure.
- Keep feature-specific controls local when they do not represent a stable shared concept.
- Use native controls and semantic styles.
- Give icon-only controls, previews, drop targets, and dynamic statuses explicit accessibility semantics.
- Do not use type erasure (`AnyView`) to avoid modeling a clear view hierarchy.

## Comments and Documentation

Comments explain **why**, constraints, coordinate systems, concurrency assumptions, or non-obvious interoperability—not what the next line already says.

Good comment subjects:

- why mozjpeg receives PPM instead of BMP;
- why a temporary file is used instead of a pipe;
- why crop coordinates are inverted for user-facing top-to-bottom order;
- why a directory subtree must be excluded;
- why synchronization makes an unchecked conformance safe.

Avoid:

- narrating assignments or obvious loops;
- stale TODOs without an issue or concrete next action;
- large prose blocks that duplicate developer documentation;
- comments that apologize for generated code.

Use `///` documentation for reusable types or APIs whose contract is not obvious from the signature.

## Formatting and Automated Guardrails

Swift source is formatted and linted by the toolchain's `swift-format` using `.swift-format`.

```sh
Scripts/lint.sh
```

To format source intentionally:

```sh
xcrun swift-format format --in-place --parallel --recursive \
  --configuration .swift-format Package.swift Sources Tests
```

Formatting is enforced in `Scripts/test-all.sh` and CI. `.editorconfig` keeps compatible editors aligned with the repository defaults.

## Tests

- Add the smallest regression test that proves a behavioral change.
- Use generated fixtures rather than personal images.
- Test public behavior and invariants, not private implementation details.
- Keep scenario names descriptive enough to explain the contract when a test fails.
- Do not weaken assertions, add arbitrary sleeps, or skip a test merely to make CI green.
- Cross-cutting refactors must pass debug and release suites plus bundle smoke testing.

## AI-Assisted Change Checklist

Before accepting generated or agent-authored code:

- [ ] Can each new type's responsibility be described in one sentence?
- [ ] Is shared code truly shared or invariant-bearing?
- [ ] Were vague names and catch-all files avoided?
- [ ] Did the change preserve dependency direction?
- [ ] Are errors, cancellation, cleanup, and partial failures explicit?
- [ ] Do comments explain non-obvious reasons rather than narrate syntax?
- [ ] Is dead code, placeholder copy, and speculative extensibility absent?
- [ ] Does `Scripts/lint.sh` pass?
- [ ] Do focused and full tests pass?
- [ ] Were developer documents updated when a contract changed?

Readable, boring code is a feature. Prefer the smallest design that makes the invariant clear and leaves a safe path for the next change.
