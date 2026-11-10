# ADR 015: Single Clipboard Writer (`set-clipboard off`)

## Status

Accepted

## Context

Copying in copy mode intermittently **appended** to the macOS clipboard instead of
replacing it. A mouse drag would copy correctly, then a later keyboard yank would
produce a clipboard entry containing the previous contents *plus* the new text.

The config had two independent clipboard writers:

1. **`pbcopy`** — every yank binding in `bindings.conf` pipes the selection to
   `pbcopy`, which opens the pasteboard, clears it, and writes.
2. **OSC 52** — `set-clipboard on` made tmux *also* emit the xterm clipboard
   escape sequence on every buffer creation, which Ghostty
   (`clipboard-write = allow`) turned into a second pasteboard write.

A clipboard-history manager captured one yank producing **two** entries:

```
older:   "ROW-07-zzzzzzzz\nROW-08-zzzzzzzz"    32 chars,  2 lines
correct: "My leading suspect now is..."       388 chars,  4 lines
append:  ROW-07/08 + newline + the paragraph  421 chars,  7 lines
```

`32 + 388 + 1 = 421` and `2 + 4 + 1 = 7` — exact. The appended entry is precisely
*previous clipboard + newline + new content*.

`pbcopy` cannot produce that; it always clears first. OSC 52 can: because OSC
carries an arbitrary-length string, the terminal accumulates bytes into a buffer
until it sees the terminator, then decodes and resets. If that reset is missed on
some path, the stale payload is still buffered when the next sequence arrives and
the new bytes append to it.

Diagnosis was slow for two reasons worth recording:

- `pbpaste`-based checks sample the pasteboard *after* both writes land, so they
  only ever see whichever won. They cannot detect that there were two writes.
- Automated reproductions ran in a **detached** tmux session. tmux emits OSC 52
  only to an **attached client**, so those runs never exercised the OSC 52 path
  and could not have produced a positive result.

## Decision

Set `set-clipboard off` in `tmux.conf`, leaving `pbcopy` as the sole clipboard
writer.

`external` was considered and rejected. Per `man tmux`, `external` still
"attempt[s] to set the terminal clipboard" and only stops tmux accepting inbound
sequences from applications — it does not remove the duplicate write, so it does
not fix this bug.

## Consequences

- One writer, so a yank replaces the clipboard rather than appending to it.
- Local copy-mode yanks are unaffected: they were always going through `pbcopy`.
- Applications that emit OSC 52 themselves — for example a remote Neovim with
  `clipboard=osc52` reached over SSH from inside a local pane — no longer reach
  the macOS clipboard through tmux. Local Neovim is unaffected because it uses
  the `+` register through the macOS provider, not OSC 52.
- On a machine without `pbcopy` (a Linux host, a remote server), this setting
  would need revisiting: OSC 52 is the mechanism that works when no local
  clipboard binary exists.

## Related

- [ADR 005](005-delegate-yank-to-tmux-yank.md) — delegating yank to tmux-yank
- [ADR 010](010-clean-prose-copy.md) — clean prose copy bindings
- `tmux.conf` line 28 (`set-clipboard`), `bindings.conf` yank bindings
