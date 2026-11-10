return {
  { -- Catppuccin colorscheme
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      require('catppuccin').setup {
        flavour = 'auto', -- auto will respect the background setting
        background = { -- :h background
          light = 'latte',
          dark = 'mocha',
        },
        transparent_background = false, -- disables setting the background color.
        show_end_of_buffer = true, -- shows the '~' characters after the end of buffers
        term_colors = true, -- sets terminal colors (e.g. `g:terminal_color_0`)
        dim_inactive = {
          enabled = false, -- inactive splits stay at catppuccin default (active is darkened instead)
        },
        no_italic = false, -- Force no italic
        no_bold = false, -- Force no bold
        no_underline = false, -- Force no underline
        styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
          comments = { 'italic' }, -- Change the style of comments
          conditionals = { 'italic' },
          loops = {},
          functions = {},
          keywords = {},
          strings = {},
          variables = {},
          numbers = {},
          booleans = {},
          properties = {},
          types = {},
          operators = {},
        },
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          notify = false,
          mini = {
            enabled = true,
            indentscope_color = '',
          },
          telescope = {
            enabled = true,
          },
          which_key = true,
        },
      }

      -- Load the colorscheme here.
      vim.cmd.colorscheme 'catppuccin'

      -- Use palette-derived colors so highlights adapt to light/dark mode.
      -- Re-applied via ColorScheme autocmd when the theme switches (e.g. macOS appearance change).
      local function apply_focus_highlights()
        local p = require('catppuccin.palettes').get_palette()
        local is_light = vim.o.background == 'light'
        vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = p.overlay0, bg = p.mantle })
        -- Use a near-white working surface in light mode and a dark one in
        -- dark mode, with contrasting inactive backgrounds and lavender separators.
        vim.api.nvim_set_hl(0, 'NormalActive', { bg = is_light and p.base or p.crust })
        vim.api.nvim_set_hl(0, 'NormalInactive', { bg = is_light and p.surface1 or p.surface0 })
        vim.api.nvim_set_hl(0, 'WinSeparatorActive', { fg = p.lavender, bold = true })
        vim.api.nvim_set_hl(0, 'NormalUnfocused', { bg = p.mantle })
        -- Latte's CursorLine is a near-invisible tint of `base`, and our active
        -- light-mode split *is* `base`, so the current line disappears. Dark mode
        -- is fine because the active split sits at `crust`, well below the default.
        if is_light then
          vim.api.nvim_set_hl(0, 'CursorLine', { bg = p.surface0 })
        end
        vim.api.nvim_set_hl(0, 'TelescopeSelection', { bg = p.surface1, bold = true })
        vim.api.nvim_set_hl(0, 'TelescopeSelectionCaret', { fg = p.lavender, bold = true })
      end
      apply_focus_highlights()
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = 'catppuccin*',
        callback = apply_focus_highlights,
      })

      -- Decoration windows color themselves with nvim_win_set_hl_ns, a
      -- window-scoped highlight namespace. `winhighlight` outranks it, so
      -- setting it here would override their background. Skip them.
      local function is_decoration(win)
        local buf = vim.api.nvim_win_get_buf(win)
        return vim.bo[buf].filetype == 'no-neck-pain'
      end

      -- Floating windows (Telescope, LSP hover, etc.) theme themselves via
      -- their own highlight groups. Overwriting their `Normal`/`WinSeparator`
      -- with our split-focus colors collided with Telescope's own selection
      -- highlight in light mode (both resolved to `surface1`). Leave them alone.
      local function is_floating(win)
        return vim.api.nvim_win_get_config(win).relative ~= ''
      end

      local function skip_focus_styling(win)
        return is_decoration(win) or is_floating(win)
      end

      local function update_window_focus()
        local current_win = vim.api.nvim_get_current_win()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if not skip_focus_styling(win) then
            local winhighlight = win == current_win
                and 'Normal:NormalActive,WinSeparator:WinSeparatorActive'
              or 'Normal:NormalInactive'
            vim.api.nvim_set_option_value('winhighlight', winhighlight, { win = win })
            vim.api.nvim_set_option_value('cursorline', win == current_win, { win = win })
          end
        end
      end

      local win_focus_group = vim.api.nvim_create_augroup('WinFocusActive', { clear = true })
      vim.api.nvim_create_autocmd('WinEnter', {
        group = win_focus_group,
        callback = function()
          -- smart-splits temporarily visits both windows while swapping buffers.
          -- Reconcile highlights after the complete swap rather than during those visits.
          vim.schedule(update_window_focus)
        end,
      })
      vim.api.nvim_create_autocmd('WinLeave', {
        group = win_focus_group,
        callback = function()
          if not skip_focus_styling(vim.api.nvim_get_current_win()) then
            vim.opt_local.winhighlight = ''
          end
        end,
      })

      -- Slightly dim entire nvim instance when tmux focus moves to another pane.
      -- Requires tmux `focus-events on`.
      local focus_group = vim.api.nvim_create_augroup('FocusDim', { clear = true })
      vim.api.nvim_create_autocmd('FocusLost', {
        group = focus_group,
        callback = function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if not skip_focus_styling(win) then
              vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:NormalUnfocused')
              vim.api.nvim_set_option_value('cursorline', false, { win = win })
            end
          end
        end,
      })
      vim.api.nvim_create_autocmd('FocusGained', {
        group = focus_group,
        callback = update_window_focus,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
