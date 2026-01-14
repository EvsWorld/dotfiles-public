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
          lualine_a = { 'mode' },
          -- TODO: make the branch compact or disappear if the window width is too short. prioritize visability of the file name
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = {
            { 'filename', path = 1 }, -- Show relative path
            { 'harpoon2', icon = '♆', indicators = { 'h', 'j', 'k', 'l' } },
          },
          lualine_x = {
            'encoding',
            'fileformat',
            'filetype',
            {
              require('interestingwords').lualine_get,
              cond = require('interestingwords').lualine_has,
              color = { fg = '#ff9e64' },
            },
          },
          lualine_y = { 'progress' },
          -- lualine_y = {
          --   {
          --     -- TODO: make this only show word count only for markdown files
          --     function()
          --       return vim.fn.wordcount().words
          --     end,
          --   },
          -- },
          lualine_z = { 'location' },
        },
      }
    end,
  },
}
