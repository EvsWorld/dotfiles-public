# ADR 012: Track SessionX Session Recency in a Fork

## Status

Superseded by [ADR 017](017-retire-sessionx-for-sesh.md) (2026-08-19).
Originally accepted (2026-07-28).

## Context

SessionX listed project sessions alphabetically except for a single
`client_last_session` special case. The desired picker order is based on when a
session was entered: least recently seen at the top, most recently seen at the
bottom, and the visible current session last. Pane output must not reorder the
list, and the order may reset with the tmux server.

The installed TPM checkout had a local commented experiment using
`session_activity`, but plugin checkouts are ignored by the bare dotfiles
repository and may be overwritten by TPM. Upstream pull request 216 also mixes
`session_last_attached` and `session_activity` across refresh paths, so it does
not implement one consistent definition of session recency.

## Decision

Use the public
`EvsWorld/tmux-sessionx#feature/session-recency-order` fork, based on current
upstream SessionX commit `c9aaa1d`. The completed fork change is commit
`54f8e56`. A shared plugin helper orders sessions by `session_last_attached`
for initial display, rename reloads, kill reloads, and optional Git-branch mode.

Because SessionX combines fzf's default bottom-up layout with `--tac`, the
helper emits oldest-first input so the interactive picker is
oldest-to-newest. Never-entered sessions have the oldest effective timestamp,
equal timestamps are alphabetical, and fuzzy relevance takes over after the
user types a query.
`floax-floating-window-session-name` is filtered out because opening Floax
would otherwise repeatedly make its utility session recent.

The bare dotfiles repository tracks only the TPM declaration and configuration.
The plugin remains a separate Git checkout under the ignored `plugins/`
directory; it is not vendored or added as a submodule.

## Implementation

The fork adds `scripts/session-list.sh` as the single session-ordering path. It:

1. Reads `session_last_attached` and `session_name` from `tmux list-sessions`.
2. Treats an empty timestamp as zero, so never-entered sessions are oldest.
3. Removes names from `@sessionx-_filtered-sessions`.
4. Sorts timestamps ascending and equal timestamps alphabetically.
5. Emits names only, ready for SessionX's existing fzf pipeline.

The initial picker in `scripts/sessionx.sh`, kill reloads in
`scripts/reload_sessions.sh`, rename reloads in `sessionx.tmux`, and optional
Git-branch display in `scripts/sessions_with_branches.sh` all call that helper.
Keeping these paths together prevents the initial list and in-picker refreshes
from using different definitions of recency.

The first implementation emitted newest-first input because a non-interactive
`fzf --filter` check appeared to reverse `--tac`. The real popup also uses fzf's
default bottom-up layout, so that version displayed newest sessions at the top.
Commit `54f8e56` corrected the helper to emit oldest-first input; the interactive
popup was then confirmed to display oldest at the top and current/newest at the
bottom.

In `tmux.conf`:

```tmux
set -g @plugin 'EvsWorld/tmux-sessionx#feature/session-recency-order'
set -g @sessionx-filtered-sessions 'floax-floating-window-session-name'
```

TPM continues to install the plugin at
`~/.config/tmux/plugins/tmux-sessionx`. The installed checkout uses the fork as
`origin`, Omer's repository as fetch-only `upstream`, and disables pushes to
`upstream`:

```text
origin    https://github.com/EvsWorld/tmux-sessionx.git
upstream  https://github.com/omerxx/tmux-sessionx.git (fetch)
upstream  no_push (push)
```

The previously edited checkout was moved rather than overwritten. The preserved
rollback directories are:

- `plugins/tmux-sessionx.backup-20260728-1356` — original checkout at
  `42c1838` with the commented activity-sort experiment.
- `plugins/tmux-sessionx.pre-final-sync-20260728-1427` — locally corrected
  checkout retained before the clean `54f8e56` clone was installed.

They remain ignored by the bare dotfiles repository and may be removed after
the fork has been trusted for long enough.

## Future Upstream Updates

The fork does not update itself automatically. To incorporate future Omer
changes, fetch `upstream`, merge `upstream/main` into
`feature/session-recency-order`, test the SessionX interactions, and push the
feature branch to `origin`. A pull request to Omer should also originate from
that fork branch; never push directly to `upstream`.

TPM reinstalling the branch recreates `origin` from the declaration but does
not recreate the local `upstream` remote. Add the fetch-only remote again if a
fresh checkout will be used for upstream maintenance.

## Rationale / Alternatives Considered

- **Patch the installed plugin.** Rejected because the change would be ignored,
  machine-local, and vulnerable to TPM updates.
- **Copy a custom launcher into the dotfiles repository.** Rejected because it
  would duplicate upstream SessionX internals and drift over time.
- **Pin upstream pull request 216.** Rejected because its refresh paths use
  inconsistent recency signals.
- **Persist recency across tmux server restarts.** Deferred; native
  `session_last_attached` provides the desired first version without a separate
  history file.

## Verification

The implementation was checked with:

- `bash -n` across every changed SessionX shell file.
- A mocked timestamp list covering never-entered sessions, alphabetical ties,
  newer sessions, and Floax filtering.
- An isolated tmux control client that switched Alpha → Beta → Gamma and
  confirmed `session_last_attached` advanced only when each session was entered.
- An isolated full-config load that confirmed `Prefix+f` resolved to the fork's
  `sessionx.sh` with no configuration errors.
- Live `tmux source-file`, option, binding, reload-list, and checkout checks.
- Interactive confirmation that the corrected popup placed oldest sessions at
  the top and the current/newest session at the bottom.

After future changes, repeat the live interaction: revisit an older session and
confirm it moves to the bottom; rename and kill sessions and confirm the refresh
keeps the same order; type a query and confirm fuzzy relevance takes over; use
`Ctrl+y` and confirm zoxide paths still load; confirm the Floax utility session
remains absent.
