return {
  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        -- styles = {
        --   comments = { italic = false }, -- Disable italics in comments
        -- },
        dim_inactive = true, -- dims inactive windows
        lualine_bold = true, -- When `true`, section headers in the lualine theme will be bold
        -- Increase contrast and brightness
        -- style = 'night', -- The theme comes in three styles, storm, moon, or night.
        transparent = true, -- Enable this to disable setting the background color
        terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
        -- on_highlights = function(hl, c)
        -- -- Make comments more visible
        -- hl.Comment = { fg = c.comment, bold = true }
        -- -- Improve line numbers visibility
        -- hl.LineNr = { fg = c.fg_gutter }
        -- hl.CursorLineNr = { fg = c.orange, bold = true }
        -- -- WINDOW/SPLIT VISIBILITY IMPROVEMENTS
        -- -- All window separators (including bottom border)
        -- hl.WinSeparator = { fg = c.blue, bg = 'NONE', bold = true }
        -- hl.VertSplit = { fg = c.blue, bold = true }
        -- -- hl.WinSeparator = { fg = '#7aa2f7', bg = 'NONE', bold = true }
        -- -- hl.VertSplit = { fg = '#7aa2f7', bold = true }
        --
        -- -- ACTIVE WINDOW INDICATOR - Add a colored background to active window
        -- hl.Normal = { bg = c.bg, fg = c.fg }
        -- -- hl.NormalNC = { bg = '#16161e', fg = c.fg_dark } -- Slightly darker bg for inactive
        --
        -- -- Make floating windows more visible
        -- hl.NormalFloat = { bg = c.bg_popup, fg = c.fg }
        -- hl.FloatBorder = { fg = c.blue, bold = true }
        -- -- Active window indicator
        -- hl.WinBar = { bg = c.bg_highlight, fg = c.fg, bold = true }
        -- hl.WinBarNC = { bg = c.bg, fg = c.fg_gutter }
        -- -- Status line improvements
        -- hl.StatusLine = { bg = c.bg_statusline, fg = c.fg }
        -- hl.StatusLineNC = { bg = c.bg, fg = c.fg_gutter }
        -- -- Make Telescope search matches much more visible
        -- hl.TelescopeMatching = { fg = c.yellow, bg = c.bg_highlight, bold = true }
        -- hl.TelescopeSelection = { fg = c.fg, bg = c.bg_highlight, bold = true }
        -- hl.TelescopeSelectionCaret = { fg = c.red, bg = c.bg_highlight }
        -- -- Highlight search matches in preview pane
        -- hl.TelescopePreviewMatch = { fg = c.black, bg = c.orange, bold = true }
        -- end,
      }

      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme 'tokyonight'
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
