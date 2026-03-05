return {
  {
    'nvim-zh/colorful-winsep.nvim',
    event = { 'WinNew', 'WinEnter' },
    config = function()
      require('colorful-winsep').setup {
        -- highlight = {
        --   fg = '#f38ba8', -- Catppuccin mocha red
        -- },
        interval = 30,
        no_exec_files = {
          'packer',
          'TelescopePrompt',
          'mason',
          'CompeDocumentation',
          'neo-tree',
        },
        symbols = { '─', '│', '┌', '┐', '└', '┘' },
      }
      -- Force the highlight group in case the colorscheme overrides it
      vim.api.nvim_set_hl(0, 'ColorfulWinSep', { fg = '#f38ba8', bold = true })
      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function()
          vim.api.nvim_set_hl(0, 'ColorfulWinSep', { fg = '#f38ba8', bold = true })
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
