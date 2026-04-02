return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup {
        options = {
          theme = 'auto',
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          globalstatus = false, -- Single statusline for all windows
        },
        sections = {
          lualine_a = {
            {
              'mode',
              fmt = function(str)
                return str:sub(1, 1)
              end,
              -- color = { bg = '#f38ba8', fg = '#1e1e2e', gui = 'bold' },
              -- ^ Override to make mode box always red (active-window focus indicator).
              -- Removed: lualine's catppuccin theme already colors by mode (blue=normal,
              -- green=insert, orange=visual), and the mode box only appears in the active
              -- window (inactive_sections has no lualine_a), so it still serves as a
              -- focus indicator without forcing a single color for all modes.
            },
          },
          lualine_b = {
            {
              'branch',
              cond = function()
                return vim.fn.winwidth(0) > 80
              end,
            },
            'diff',
            'diagnostics',
          },
          lualine_c = {
            { 'filename', path = 1 }, -- Show relative path
            { 'harpoon2', icon = '♆', indicators = { 'h', 'j', 'k', 'l' } },
          },
          lualine_x = {
            {
              'encoding',
              cond = function()
                return vim.fn.winwidth(0) > 100
              end,
            },
            {
              'fileformat',
              cond = function()
                return vim.fn.winwidth(0) > 100
              end,
            },
            {
              'filetype',
              cond = function()
                return vim.fn.winwidth(0) > 100
              end,
            },
            {
              require('interestingwords').lualine_get,
              cond = function()
                return require('interestingwords').lualine_has()
                  and vim.fn.winwidth(0) > 100
              end,
              color = { fg = '#ff9e64' },
            },
          },
          lualine_y = {
            {
              'progress',
              cond = function()
                return vim.fn.winwidth(0) > 100
              end,
            },
          },
          -- lualine_somewhere = {
          --   {
          --     -- TODO: make this only show word count only for markdown files
          --     function()
          --       return vim.fn.wordcount().words
          --     end,
          --   },
          -- },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = { 'location' },
        },
      }
    end,
  },
}
