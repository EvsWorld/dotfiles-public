# ADR 010: Add a Clean-Prose Copy Path

## Status

Accepted

## Context

Terminal applications render text onto a fixed-width character grid. Copying an
ordinary multi-row selection can therefore retain width-dependent padding and row
breaks even when the selected content is prose. The resulting clipboard text looks
different depending on pane width.

The existing `y` and `Y` bindings must remain lossless because code, tables, and
intentional line breaks depend on their exact layout. tmux cannot reliably infer
which selections are prose.

tmux-yank also installs `!` as an internal "copy without newline" helper using
`tr -d '\n'`. That removes row breaks but retains their padding, which can create
large runs of spaces; it is not suitable as the clean-prose implementation.

## Decision

Keep `y`, `Y`, mouse copying, and tmux-yank's internal `!` helper unchanged. Bind
`c` after TPM loads as an explicit clean-prose copy action. The binding pipes the
selection through `scripts/normalize-prose.sh`, then into `pbcopy`, and exits copy
mode.

The normalizer:

- converts CRLF input to LF;
- collapses horizontal spaces and tabs to one space;
- joins adjacent selected rows with one space;
- preserves one blank line between paragraphs; and
- trims whitespace at the beginning and end of the selection.

This intentionally changes layout and is only appropriate for prose. Exact copying
continues to use `y` or `Y`.

## Verification

Pipe representative wrapped prose into the normalizer and confirm that padding is
removed, adjacent rows are joined, and blank lines remain. After reloading tmux,
inspect the live `copy-mode-vi` table and confirm that `c` invokes the normalizer,
while `y`, `Y`, and tmux-yank's `!` helper retain their intended behavior.
