-- https://github.com/shortcuts/no-neck-pain.nvim
--
-- Caps reading measure for prose without touching the file's bytes.
-- Markdown soft wraps to the window width (see the WrapControl augroup in
-- lua/options.lua), so narrowing the window is enough to reflow long
-- paragraphs to a comfortable width. `textwidth` stays 0 throughout.
--
-- Rationale and tradeoffs: docs/2026-09-04-centered-markdown-reading-measure.md
return {
  'shortcuts/no-neck-pain.nvim',
  -- opts reads the catppuccin palette, so the colorscheme must load first.
  dependencies = { 'catppuccin/nvim' },
  cmd = { 'NoNeckPain', 'NoNeckPainResize' },
  keys = {
    {
      '<leader>\\tt',
      '<cmd>NoNeckPain<CR>',
      mode = 'n',
      desc = 'Toggle centered reading measure',
    },
  },
  opts = function()
    -- Palette-derived so padding follows the automatic light/dark switch,
    -- matching how apply_focus_highlights() works in catppuccin.lua.
    local crust = require('catppuccin.palettes').get_palette().crust

    return {
      -- Gentle margins, not a narrow column: ~20 columns of padding per side on
      -- a full-width (~240 column) pane. `width` is absolute, so centering does
      -- nothing on panes narrower than this. Tune live with :NoNeckPainResize.
      width = 200,
      autocmds = {
        -- Tab-scoped and filetype-blind, so centering stays a manual toggle.
        enableOnVimEnter = false,
        enableOnTabEnter = false,
        reloadOnColorSchemeChange = true,
        -- Padding is decoration; window navigation should pass through it.
        skipEnteringNoNeckPainBuffer = true,
      },
      -- Keymap lives in the <leader>\t toggle namespace instead.
      mappings = { enabled = false },
      buffers = {
        -- Without an explicit background the side buffers render at `base`,
        -- which is *lighter* than the active window's `crust`. Matching crust
        -- makes padding and text one continuous field.
        colors = { background = crust },
        wo = { fillchars = 'eob: ' },
      },
    }
  end,
}
