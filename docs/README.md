# ImageBench Documentation

This directory is the entry point for contributor, engineering, release, and product-planning documentation. The repository root stays intentionally small so the files visible on GitHub are the ones readers need first.

## Start here

| Question | Primary document | Related document |
| --- | --- | --- |
| What is ImageBench and how do I run it? | [Project README](../README.md) | [Developer guide](DEVELOPMENT.md) |
| How do I contribute? | [Contributing guide](CONTRIBUTING.md) | [Agent guide](../AGENTS.md), [code quality guide](CODE_STYLE.md) |
| How should an agent work in this repository? | [Agent guide](../AGENTS.md) | The task-specific guides below |
| How is the app structured and packaged? | [Developer guide](DEVELOPMENT.md) | [Code quality guide](CODE_STYLE.md), [versioning policy](VERSIONING.md) |
| What has changed? | [Changelog](../CHANGELOG.md) | [Versioning policy](VERSIONING.md) |
| What comes next? | [Roadmap](ROADMAP.md) | [Changelog](../CHANGELOG.md) for completed work |
| How should the UI look and behave? | [UI design system](../Design/UI_DESIGN_SYSTEM.md) | [UI QA record](../Design/UI_QA.md) |
| Is the current build ready to ship? | [Roadmap](ROADMAP.md) | [Developer guide](DEVELOPMENT.md), [versioning policy](VERSIONING.md) |

## Repository documentation structure

```text
README.md                    product overview and quick start
AGENTS.md                    repository-wide agent operating rules
CHANGELOG.md                 released and Unreleased product history
THIRD_PARTY_NOTICES.md       legal notices for bundled dependencies
docs/
  README.md                  this navigation and ownership map
  CONTRIBUTING.md            contribution workflow and evidence
  DEVELOPMENT.md             architecture, pipelines, testing, and packaging
  CODE_STYLE.md              source organization and quality standards
  VERSIONING.md              versions, builds, tags, and release procedure
  ROADMAP.md                 product sequence and uncommitted future work
Design/
  UI_DESIGN_SYSTEM.md        normative UI and accessibility contract
  UI_QA.md                   current visual and interaction verification record
```

New long-lived guides belong in `docs/` unless they are specifically about design. GitHub automatically discovers `docs/CONTRIBUTING.md`, preserving contributor guidance while keeping the repository root clean. Keep a Markdown file at the root only when it is a primary GitHub entry point, a repository-wide agent instruction file, release history, or a legal notice.

## Document ownership

- [README.md](../README.md) owns the product overview, trust model, features, setup, and build entry points.
- [AGENTS.md](../AGENTS.md) owns repository invariants, verification expectations, and the agent workflow.
- [CHANGELOG.md](../CHANGELOG.md) owns chronological user-visible and contributor-visible history.
- [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md) owns bundled dependency attribution and license references.
- [CONTRIBUTING.md](CONTRIBUTING.md) owns human contribution, pull-request, privacy, and AI-assistance expectations.
- [DEVELOPMENT.md](DEVELOPMENT.md) owns architecture, data flows, debugging, testing, packaging, and release mechanics.
- [CODE_STYLE.md](CODE_STYLE.md) owns module placement, naming, abstraction, concurrency, comments, formatting, and review standards.
- [VERSIONING.md](VERSIONING.md) owns version selection, build numbers, tags, artifacts, and release synchronization.
- [ROADMAP.md](ROADMAP.md) owns future sequence and explicitly uncommitted ideas.
- [UI_DESIGN_SYSTEM.md](../Design/UI_DESIGN_SYSTEM.md) owns lasting design, interaction, content, motion, and accessibility rules.
- [UI_QA.md](../Design/UI_QA.md) owns current visual and interaction verification conclusions; generated screenshots remain temporary by default.
- [LICENSE](../LICENSE) is authoritative for the repository license.

## Update matrix

| Change type | Required documentation review |
| --- | --- |
| User-visible feature or fix | [Changelog](../CHANGELOG.md), [project README](../README.md), relevant tool docs/tests |
| Version or distributed build | [Versioning policy](VERSIONING.md), `Packaging/Info.plist`, [changelog](../CHANGELOG.md), release notes |
| Architecture or data-flow contract | [Developer guide](DEVELOPMENT.md), [agent guide](../AGENTS.md), [code quality guide](CODE_STYLE.md) when boundaries change |
| UI component or interaction rule | [UI design system](../Design/UI_DESIGN_SYSTEM.md), [UI QA record](../Design/UI_QA.md) |
| Supported format or dependency | [Project README](../README.md), [developer guide](DEVELOPMENT.md), [agent guide](../AGENTS.md), [third-party notices](../THIRD_PARTY_NOTICES.md), changelog |
| Privacy, offline, source-safety, or overwrite behavior | [Project README](../README.md), [agent guide](../AGENTS.md), [developer guide](DEVELOPMENT.md), changelog |
| Planned work or sequencing | [Roadmap](ROADMAP.md); do not present it as shipped until it reaches the changelog |
| Contributor workflow or automation | [Contributing guide](CONTRIBUTING.md), [agent guide](../AGENTS.md), `.github` templates/workflows |
| Production-readiness finding | [Roadmap](ROADMAP.md), then the owning release or design document |

## Consistency rules

1. Link to the authoritative document instead of copying long policy sections.
2. Update test counts, supported formats, versions, and release status everywhere they are intentionally surfaced.
3. Keep roadmap intent separate from changelog fact.
4. Keep generated visual evidence outside the repository by default; record conclusions in the [UI QA record](../Design/UI_QA.md) and lasting rules in the [UI design system](../Design/UI_DESIGN_SYSTEM.md).
5. Keep implementation explanations in the [developer guide](DEVELOPMENT.md), not in view-code comments or the project README.
6. Preserve historical changelog entries; current work belongs under **Unreleased**.
7. Add every new long-lived guide to this map and link it from the project README when it is broadly relevant.

Documentation-only changes still run `Scripts/lint.sh` and `git diff --check`. Changes to commands, packaging, metadata, or executable behavior require the corresponding tests and smoke checks described in the [agent guide](../AGENTS.md).
