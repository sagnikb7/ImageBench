# Compressor Results Summary Audit

Audit date: 2026-08-27

Scope: completed or partially completed compression summary

## Decision

Show the size transformation explicitly. The most understandable outcome is:

- **Before** — original bytes for successfully compressed files;
- **After** — output bytes for those same successful files;
- **Saved** — absolute difference and percentage reduction.

For example: `100 MB → 80 MB`, followed by `20 MB saved · 20% smaller`.

## Current-state finding

The current summary is understandable but visually flat. Three operational counts and one green savings badge share a single horizontal row without a result heading. The large gap separates the savings from the files it describes, while action buttons added after the savings badge have limited room at minimum window sizes.

Evidence: `01-current.jpg`.

The view model already exposes the required data. `inputBytesForLastRun` totals the original sizes of successful inputs, `batchResult.bytes` totals their outputs, and `savedBytes`/`savedPercentage` calculate the difference. No new engine behavior is required.

## Recommended hierarchy

1. Add a semantic result heading: **Compression complete** when there are no failures, or **Compression finished with issues** when attention is required.
2. Keep Succeeded, Need Attention, and Skipped together as operational outcome metrics.
3. Present size reduction as one compact comparison group with visible **Before** and **After** labels.
4. Put `Saved 20 MB · 20% smaller` below the comparison as the emphasized positive outcome.
5. Place Retry, Show Issues, and Reveal Output in a separate action row so they cannot squeeze or displace the metrics.

## Accuracy and accessibility

Savings must be labelled as applying to successful files when a batch is partial. Otherwise a user could read the comparison as representing all selected photos, including failures and skipped inputs.

Use labels in addition to the arrow and green color. A suitable accessibility value is: “Successful files were 100 megabytes before compression and 80 megabytes after compression, saving 20 megabytes or 20 percent.”

Do not use strikethrough for the original size; it resembles retail pricing and is less explicit than Before/After labels.
