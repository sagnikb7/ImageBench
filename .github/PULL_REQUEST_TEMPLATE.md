## Problem

What user or developer problem does this change solve?

## Approach

Describe the implementation and important tradeoffs.

## Verification

List the exact commands run and their results.

```text
swift test --disable-sandbox
```

## UI Evidence

For UI changes, attach before/after screenshots in light and dark appearance and describe keyboard, VoiceOver, contrast, and Reduce Motion checks. Remove this section for non-UI changes.

## Checklist

- [ ] I read `AGENTS.md`, `CONTRIBUTING.md`, and the relevant documentation map entries.
- [ ] Source images remain untouched and existing outputs are protected.
- [ ] Offline behavior is preserved.
- [ ] Long-running work remains asynchronous and cancellable.
- [ ] Tests cover the changed behavior.
- [ ] Debug tests pass.
- [ ] Release tests or bundle smoke tests were run when relevant.
- [ ] Documentation is updated.
- [ ] Qualifying changes are recorded under `CHANGELOG.md` **Unreleased**.
- [ ] Version or build changes follow `VERSIONING.md`.
- [ ] I reviewed and understand any AI-generated changes.
