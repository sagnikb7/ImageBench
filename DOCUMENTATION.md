# ImageBench Documentation Map

ImageBench uses a small connected documentation system. Each document has one primary responsibility so contributors and coding agents can find the source of truth without duplicating policy across files.

## Entry Points

| Audience or question | Start here | Then read |
| --- | --- | --- |
| What is ImageBench and how do I run it? | `README.md` | `DEVELOPMENT.md` for implementation details |
| How do I contribute? | `CONTRIBUTING.md` | `AGENTS.md`, `CODE_STYLE.md` |
| How should an agent operate in this repository? | `AGENTS.md` | The task-specific documents below |
| How is the app structured and packaged? | `DEVELOPMENT.md` | `CODE_STYLE.md`, `VERSIONING.md` |
| What has changed? | `CHANGELOG.md` | `VERSIONING.md` for release rules |
| What version should a change receive? | `VERSIONING.md` | `CHANGELOG.md`, `ROADMAP.md` |
| What comes next? | `ROADMAP.md` | `CHANGELOG.md` for completed work |
| How should the UI look and behave? | `Design/UI_DESIGN_SYSTEM.md` | `design-qa.md` for the current verification record |
| Is the current build ready to ship? | `ROADMAP.md` | `DEVELOPMENT.md` and `VERSIONING.md` for release procedure |

## Document Ownership

- `README.md` — product overview, user trust model, features, setup, build entry points, and links to deeper documentation.
- `DOCUMENTATION.md` — map of the documentation ecosystem and rules for keeping it coherent.
- `AGENTS.md` — repository-wide operating constraints, invariants, verification expectations, and agent workflow.
- `CONTRIBUTING.md` — human contribution process, pull-request evidence, privacy, and AI-assisted contribution expectations.
- `DEVELOPMENT.md` — architecture, data flows, debugging, testing, packaging, and release mechanics.
- `CODE_STYLE.md` — source organization, naming, abstraction, concurrency, comments, formatting, and code-review standards.
- `CHANGELOG.md` — chronological, user-visible and contributor-visible product history.
- `VERSIONING.md` — version selection, build numbers, tags, artifacts, and release synchronization.
- `ROADMAP.md` — future sequence and explicitly uncommitted ideas; completed work should move into the changelog or be marked complete.
- `Design/UI_DESIGN_SYSTEM.md` — normative design, interaction, content, motion, and accessibility contract.
- `design-qa.md` — concise current visual and interaction verification record for the Gallery Workbench interface; generated screenshots are temporary by default.
- `THIRD_PARTY_NOTICES.md` — bundled dependency versions, attribution, and license references.
- `LICENSE` — repository license; it is authoritative over summaries elsewhere.

## Update Matrix

| Change type | Required documentation review |
| --- | --- |
| User-visible feature or fix | `CHANGELOG.md`, `README.md`, relevant tool docs/tests |
| Version or distributed build | `VERSIONING.md`, `Packaging/Info.plist`, `CHANGELOG.md`, release notes |
| Architecture or data-flow contract | `DEVELOPMENT.md`, `AGENTS.md`, `CODE_STYLE.md` when boundaries change |
| UI component or interaction rule | `Design/UI_DESIGN_SYSTEM.md`, `design-qa.md` |
| Supported format or dependency | `README.md`, `DEVELOPMENT.md`, `AGENTS.md`, `THIRD_PARTY_NOTICES.md`, changelog |
| Privacy, offline, source-safety, or overwrite behavior | `README.md`, `AGENTS.md`, `DEVELOPMENT.md`, changelog |
| Planned work or sequencing | `ROADMAP.md`; do not present it as shipped until it reaches `CHANGELOG.md` |
| Contributor workflow or automation | `CONTRIBUTING.md`, `AGENTS.md`, `.github` templates/workflows |
| Production-readiness finding | `ROADMAP.md`, then the owning release or design document |

## Consistency Rules

1. Link to the authoritative document instead of copying long policy sections.
2. Update claims such as test counts, supported formats, versions, and release status everywhere they are intentionally surfaced.
3. Keep roadmap intent separate from changelog fact.
4. Keep generated visual evidence outside the repository by default; record conclusions in `design-qa.md` and lasting rules in `Design/UI_DESIGN_SYSTEM.md`.
5. Keep implementation explanations in `DEVELOPMENT.md`, not in view code comments or the README.
6. Preserve historical changelog entries; current work belongs under **Unreleased**.
7. When adding a new long-lived Markdown document, add it to this map and the README documentation list.

Documentation-only changes still run `Scripts/lint.sh` and `git diff --check`. Changes to commands, packaging, metadata, or executable behavior require the corresponding tests and smoke checks described in `AGENTS.md`.
