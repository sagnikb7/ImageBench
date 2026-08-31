# ImageBench Versioning and Release Policy

This document defines how ImageBench versions, build numbers, changelog entries, Git tags, and release artifacts stay synchronized.

## Current Version

| Field | Current value | Source of truth |
| --- | --- | --- |
| Product version | `0.3.0` | `CFBundleShortVersionString` in [Packaging/Info.plist](../Packaging/Info.plist) |
| SemVer equivalent | `0.3.0` | This policy and release tags |
| Build number | `3` | `CFBundleVersion` in [Packaging/Info.plist](../Packaging/Info.plist) |
| Bundle identifier | `com.imagebench.imagetools` | [Packaging/Info.plist](../Packaging/Info.plist) |
| Release status | Source release prepared; public binary signing pending | [CHANGELOG.md](../CHANGELOG.md) and [ROADMAP.md](ROADMAP.md) |

Version `0.2.0` is the first ImageBench release to use the complete `MAJOR.MINOR.PATCH` form consistently in bundle metadata, changelog headings, artifacts, and future Git tags.

## Version Scheme

ImageBench follows Semantic Versioning:

- **MAJOR**: incompatible user workflows, file/preset migrations that cannot be handled automatically, or a deliberately incompatible public API after 1.0.
- **MINOR**: a backward-compatible tool, capability, format, or substantial workflow addition.
- **PATCH**: backward-compatible fixes, performance work, accessibility improvements, and small UI refinements.

Before 1.0, minor versions may include necessary product evolution, but any migration or compatibility risk must be explicit in the changelog. Security-only rebuilds still receive a new patch version.

Examples:

- `0.1.1`: fixes or performance improvements to the current milestone.
- `0.2.0`: a new user-facing capability while the product remains pre-1.0.
- `1.0.0`: the first stable, signed, notarized public release whose compatibility guarantees are intentional.

Pre-release builds use SemVer suffixes such as `1.0.0-beta.1` in release notes and tags. Confirm macOS bundle-version compatibility before putting a suffix into `CFBundleShortVersionString`; distribution builds may use the numeric base version with the pre-release identity in the artifact name and release notes.

## Build Numbers

`CFBundleVersion` is a monotonically increasing positive integer for distributed builds.

- Increment it for every uploaded, shared, notarized, or otherwise distributed rebuild, even when the product version is unchanged.
- Local development rebuilds do not require a committed build-number change.
- Never reuse a build number for a different distributed binary.
- Build numbers do not replace product versions and do not appear in Git tags.

The About surface must display both values as `Version <product> (<build>)`.

## Git Tags and Artifacts

- Release tags use `vMAJOR.MINOR.PATCH`, for example `v0.2.0`.
- Do not create or push a release tag until the release owner explicitly approves the release.
- Architecture-specific artifacts use clear names such as `ImageBench-0.3.0-macos-arm64.zip` and `ImageBench-0.3.0-macos-x86_64.zip`.
- A universal artifact, when supported, uses `ImageBench-0.3.0-macos-universal.zip`.
- Published artifacts must come from the tagged commit and pass the release checklist in the [developer guide](DEVELOPMENT.md).

## Changelog Policy

[CHANGELOG.md](../CHANGELOG.md) records user-visible history; commit messages and pull-request descriptions do not replace it.

Add an **Unreleased** entry for:

- new or removed user-facing behavior;
- bug fixes and recovery changes;
- performance or accessibility changes users can notice;
- supported-format, dependency, privacy, offline, packaging, or compatibility changes;
- developer-facing contracts that materially affect contributors or agents.

Do not add entries for formatting-only edits, test-only refactors with no contract change, or internal renames invisible to users and contributors.

Use the headings `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`, `Performance`, and `Documentation` as needed. Write entries in plain product language and group related implementation work into one outcome-focused bullet.

## Release Procedure

1. Choose the version from the actual change set; do not infer it from elapsed time.
2. Update `CFBundleShortVersionString` and increment `CFBundleVersion` in [Packaging/Info.plist](../Packaging/Info.plist).
3. Move relevant [CHANGELOG.md](../CHANGELOG.md) entries from **Unreleased** into `## MAJOR.MINOR.PATCH - YYYY-MM-DD`.
4. Leave a fresh **Unreleased** section at the top.
5. Update version references in README, release notes, issue templates, and migration documentation when relevant.
6. Run the complete debug and optimized suites, package the app, and run the bundle smoke test.
7. Verify the About surface, bundle metadata, architecture, bundled dependency linkage, licenses, signature, and offline behavior.
8. For public binaries, complete Developer ID signing, notarization, stapling, and representative-Mac validation.
9. Commit the release preparation. Create and push `vMAJOR.MINOR.PATCH` only after explicit release-owner approval.
10. Publish artifacts and release notes derived from the matching changelog section.

Useful metadata checks:

```sh
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' dist/ImageBench.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' dist/ImageBench.app/Contents/Info.plist
codesign --verify --deep --strict --verbose=2 dist/ImageBench.app
```

## Agent and Contributor Rules

- A feature or fix does not authorize an agent to bump a version, create a tag, or publish a release unless the user explicitly requests it.
- Agents update **Unreleased** when their change meets the changelog policy.
- Release preparation must reconcile [Packaging/Info.plist](../Packaging/Info.plist), [CHANGELOG.md](../CHANGELOG.md), release notes, artifact names, and the About surface.
- Never rewrite a released version to make current work look complete; add a new entry or correction.
- If version intent is ambiguous, keep the work under **Unreleased** and ask the release owner before changing bundle metadata.
