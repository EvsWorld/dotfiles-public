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
          enabled = true, -- dims the background color of inactive window
          shade = 'dark',
          percentage = 0.55, -- percentage of the shade to apply to the inactive window
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

      -- Override NormalNC for much stronger inactive split contrast.
      -- Active split bg = #1e1e2e; #0d0d18 is roughly half the brightness.
      vim.api.nvim_set_hl(0, 'NormalNC', { bg = '#0d0d18' })

      -- Slightly dim entire nvim instance when tmux focus moves to another pane.
      -- Requires tmux `focus-events on`. Adjust bg to taste — #141425 is noticeable but not harsh.
      vim.api.nvim_set_hl(0, 'NormalUnfocused', { bg = '#141425' })
      local focus_group = vim.api.nvim_create_augroup('FocusDim', { clear = true })
      vim.api.nvim_create_autocmd('FocusLost', {
        group = focus_group,
        callback = function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:NormalUnfocused,CursorLine:NormalUnfocused')
          end
        end,
      })
      vim.api.nvim_create_autocmd('FocusGained', {
        group = focus_group,
        callback = function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            vim.api.nvim_win_set_option(win, 'winhighlight', '')
          end
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
