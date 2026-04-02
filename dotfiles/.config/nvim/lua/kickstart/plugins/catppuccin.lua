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
        vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = p.overlay0, bg = p.mantle })
        -- Darken active split (crust) against lighter inactive splits (base).
        vim.api.nvim_set_hl(0, 'NormalActive', { bg = p.crust })
        vim.api.nvim_set_hl(0, 'NormalUnfocused', { bg = p.mantle })
      end
      apply_focus_highlights()
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = 'catppuccin*',
        callback = apply_focus_highlights,
      })
      local win_focus_group = vim.api.nvim_create_augroup('WinFocusActive', { clear = true })
      vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
        group = win_focus_group,
        callback = function()
          vim.opt_local.winhighlight = 'Normal:NormalActive'
        end,
      })
      vim.api.nvim_create_autocmd('WinLeave', {
        group = win_focus_group,
        callback = function()
          vim.opt_local.winhighlight = ''
        end,
      })

      -- Slightly dim entire nvim instance when tmux focus moves to another pane.
      -- Requires tmux `focus-events on`.
      local focus_group = vim.api.nvim_create_augroup('FocusDim', { clear = true })
      vim.api.nvim_create_autocmd('FocusLost', {
        group = focus_group,
        callback = function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:NormalUnfocused')
          end
        end,
      })
      vim.api.nvim_create_autocmd('FocusGained', {
        group = focus_group,
        callback = function()
          local cur = vim.api.nvim_get_current_win()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if win == cur then
              vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:NormalActive')
            else
              vim.api.nvim_win_set_option(win, 'winhighlight', '')
            end
          end
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
