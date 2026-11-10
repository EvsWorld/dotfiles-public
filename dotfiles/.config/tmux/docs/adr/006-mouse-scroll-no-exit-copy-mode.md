# ADR 006: Mouse Scroll Enters Copy Mode Without `-e` (No Exit at Bottom)

## Status

Accepted

## Context

Scrolling up with the mouse wheel / two-finger trackpad enters copy mode. tmux's
built-in `root` table binds this as:

```tmux
bind -T root WheelUpPane if-shell -F "#{||:#{alternate_on},#{pane_in_mode},#{mouse_any_flag}}" \
  { send-keys -M } { copy-mode -e }
```

The `-e` flag means "scrolling to the bottom of the history exits copy mode" (intended
for fast flick-scrolling). In practice this caused a surprise: scrolling down to the
bottom silently dropped out of copy mode, with no clear signal that the bottom had been
reached, defeating "scroll to the bottom, then decide when/what to copy."

Two findings from investigation:

- The copy-mode-vi wheel bindings in `bindings.conf`
  (`WheelUpPane`/`WheelDownPane → scroll-up/scroll-down`) were **not** the cause — they
  only scroll the view while already in copy mode and never exit.
- `unbind-key -a` does **not** remove this binding. Verified empirically on a bare
  server (`tmux -L test new-session -d; tmux -L test unbind-key -a`): `root
  WheelUpPane` with `copy-mode -e` is still present. It is a tmux built-in that
  survives the reset, so it must be overridden explicitly, not merely left unbound.

## Decision

Override `root WheelUpPane` in `bindings.conf` to enter copy mode **without** `-e`:

```tmux
bind -T root WheelUpPane if-shell -F "#{||:#{alternate_on},#{pane_in_mode},#{mouse_any_flag}}" \
  { send-keys -M } { copy-mode }
```

Because `bindings.conf` is sourced last (see [ADR 004](004-single-bindings-file.md)),
this wins over the built-in. Scrolling to the bottom now stays in copy mode.

## Rationale / Alternatives Considered

- **Keep `-e`.** Rejected: the auto-exit at the bottom is the reported surprise.
- **Rebind the copy-mode-vi wheel keys instead.** Rejected: those aren't the cause;
  the exit comes from the `-e` flag applied at copy-mode *entry* in the `root` table.

Tradeoff: fast flick-scrolling no longer bails out of copy mode automatically; exit
copy mode explicitly (`q`, `Escape`, or `Ctrl+c` to clear selection).

## Files Touched

- `bindings.conf` — added the `root WheelUpPane` override; corrected the neighboring
  comment (the copy-mode-vi wheel lines scroll in place, they do not prevent the exit).

## Consequences

- Mouse-wheel / two-finger scroll can reach the bottom of history and stay in copy mode.
- Note the distinct gesture: **click-and-drag** is a selection (`MouseDrag1Pane` →
  `MouseDragEnd1Pane` copies on release via tmux-yank), so dragging top-to-bottom
  selects and copies everything. That is by design and unaffected by this change — use
  the wheel / two-finger scroll (or `Ctrl+u`/`Ctrl+d`, `k`/`j`) to move without
  selecting.
- Documents that `unbind-key -a` leaves some tmux built-in mouse bindings in place; such
  defaults must be overridden explicitly in `bindings.conf`.

## Useful Commands

```bash
tmux -L vtest -f ~/.config/tmux/tmux.conf new-session -d
tmux -L vtest list-keys -T root | grep WheelUpPane   # should end in copy-mode, not copy-mode -e
tmux -L vtest kill-server
```
