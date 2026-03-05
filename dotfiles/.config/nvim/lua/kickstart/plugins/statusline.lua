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
      }
    end,
  },
}
