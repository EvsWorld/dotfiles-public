# ADR 002: Pane Border Visibility

## Status

Accepted.
The red active border recorded below was superseded on 2026-10-09; see "Active Border" for the current setting and `~/.config/docs/adrs/031-theme-aware-focus-indication-across-the-stack.md` for the theme-portability rule that forced the change.

## Context

The tmux setup uses project-oriented sessions with multiple panes for code, shells, and AI assistants. Pane boundaries should be easy to see at a glance, especially when panes are dense or when Neovim and terminal panes sit side by side.

`Prefix+P` was previously bound in `tmux.reset.conf` to `set pane-border-status`, but `tmux-floax` also uses uppercase `P` for `@floax-bind-menu`. Because TPM loads floax after `tmux.reset.conf`, floax owns the live `Prefix+P` binding. That behavior is desirable because `Prefix+P` opens the floax contextual menu.

The pane border controls should therefore be regular tmux options rather than another `Prefix+P` binding.

## Decision

Keep `Prefix+P` for floax and configure pane border visibility directly in `tmux.conf` after plugin loading, where Catppuccin overrides can be safely replaced.

Current settings:

```tmux
set -gF pane-active-border-style 'fg=#{?#{==:#{@catppuccin_flavor},latte},#c000a0,#ff00ff},bg=#{?#{==:#{@catppuccin_flavor},latte},#f5c6ec,#6b0f5e}'
set -gF pane-border-style 'fg=#{@thm_overlay_0}'
set -g pane-border-lines single
set -g pane-border-status off
```

Pane labels are off because a top status row for a lower pane overwrites the bottom border of the pane above it. The shared horizontal separator is drawn in the lower pane's inactive style, hiding the active upper pane's accent color. Disabling pane status rows lets that separator retain the active border style.

`pane-border-lines single` draws the available separators without the heavier blocky look of `heavy`.
Tmux 3.6a does not accept `rounded` for `pane-border-lines`; valid values include `single`, `double`, `heavy`, `simple`, `number`, and `spaces`.

### Why there is no complete outline

Native tmux pane borders occupy cells between panes, not a four-sided frame around every pane.
In the 2026-10-10 screenshot, the focused upper-left pane has visible right and bottom separators because other panes sit beside and below it.
Its left edge starts at column zero and its top edge starts at row zero, so there are no border cells outside those edges for `pane-active-border-style` to color.
The top tmux status bar is separate from pane borders; the same missing-frame issue applies at the other outer window edges.
This is how tmux 3.6a draws native pane borders, not a Ghostty or Neovim rendering fault.
See tmux's [pane-border drawing code](https://github.com/tmux/tmux/blob/3.6a/screen-redraw.c#L2389-L2549).

Ghostty's `window-padding-x = 8` and `window-padding-y = 8` in `~/.config/ghostty/config` add space outside the entire terminal grid.
Changing that padding does not create or reveal an outer tmux pane border.
`pane-active-border-style`, `pane-border-lines`, and Catppuccin can restyle existing separator cells, but cannot make native tmux borders into complete boxes.
A custom rendering approach might imitate a full frame; it has not been designed or implemented here.

## Active Border

A tmux pane border is always exactly one cell.
There is no width option, so "make the focused pane more obvious" has only two levers: a heavier glyph, or a background fill on the border cell.

The glyph lever is weaker than it looks.
`pane-border-lines` is resolved once per window, not per pane - in tmux 3.6a, `screen-redraw.c:628` reads it into the redraw context and line 781 applies it to every border cell - so setting `heavy` or `double` thickens *all* borders and does not single out the focused pane.

The fill lever is therefore the one that works, and it is what the original `fg=#ff0000,bg=#ff0000` was really doing: both `fg` and `bg` red produced a solid red cell, not a thick red line.

That setting was removed for being hardcoded and for dominating the screen.
A full `fg=#{@thm_crust},bg=#{@thm_lavender}` fill was then tried and reproduced the same complaint at lower saturation.
On 2026-10-09, the accepted value dimmed the fill to `@thm_surface_2` with `@thm_fg` in the foreground.
On 2026-10-10, the foreground changed to `@thm_red` while retaining the subdued fill.
This makes the active border more visible and red without returning to a solid accent-colored block.
On 2026-10-11, the foreground changed to `@thm_pink` in Mocha and `@thm_mauve` in Latte while retaining the same `@thm_surface_2` fill.
Mocha pink is the brighter magenta accent; Latte pink is too close to its surface fill, so Latte uses the darker mauve accent for visibility.
On 2026-10-20, Mocha pink still proved too pastel to spot at a glance, since every catppuccin accent is a pastel.
The border became pure fuchsia `#ff00ff` on a dark magenta fill `#6b0f5e` in Mocha, and `#c000a0` on `#f5c6ec` in Latte.
The tinted fill makes the whole cell read as fuchsia without returning to a solid accent block.
Verified visually the same day in both appearances: the active border is easy to locate in Mocha and in Latte, and the Latte fill stays distinct from the light pane background.
The fill is tinted, not transparent: tmux styles the border cell's background color.

Foreground choice matters more than it appears, because tmux styles the border *label* with `pane-active-border-style` for the active pane when labels are enabled (`screen-redraw.c:464-467`).
The flavor-specific fuchsia colors the border glyph while the darker tint carries the cell background.

The colors are a per-flavor hex pair rather than palette variables, because the palette has no saturated fuchsia.
Each appearance gets its own value, which preserves the ADR 031 constraint: a single raw hex encodes one appearance and is what previously broke light mode.

One deliberate loss: pane labels are hidden to keep the shared horizontal separator in the active pane's accent style.
Focus is carried by the `window-style` background contrast and active border color.

## Consequences

- `Prefix+P` remains reserved for the floax menu.
- Pane labels are disabled so an inactive lower pane cannot overwrite the active pane's bottom border.
- Active pane identity is shown by the fuchsia accent on a magenta-tinted border fill and the dimmed inactive pane background.
- Inactive pane borders are explicitly `@thm_overlay_0` rather than Catppuccin's default, so they recede against the filled active border in both flavors.
- Border styling is theme-derived, so it survives a flavor toggle (`prefix T`) and a light/dark switch.
- "Lavender = focused" no longer holds at the tmux border; the active border uses saturated fuchsia on a magenta-tinted fill.
- Re-enabling `pane-border-status top` can obscure the active color at horizontal separators; `bottom` has the corresponding issue on upper panes.

## Useful Commands

Check current values:

```tmux
show -g pane-border-status
show -g pane-border-lines
show -g pane-active-border-style
show -g pane-border-style
```

If you want to restore pane labels, try these alternatives from `Prefix + :`:

```tmux
set -g pane-border-status top
set -g pane-border-status bottom
set -g pane-border-status off
```

If pane labels are enabled, simplify their format with:

```tmux
set -g pane-border-format '#{pane_index}: #{pane_current_command}'
```
