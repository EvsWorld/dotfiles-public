return {
  'akinsho/git-conflict.nvim',
  version = '*',
  event = 'VeryLazy',
  config = function()
    require('git-conflict').setup {
      default_mappings = {
        ours = '<leader>gxo',
        theirs = '<leader>gxt',
        none = '<leader>gxn',
        both = '<leader>gxa',
        next = ']x',
        prev = '[x',
      },

      default_commands = true, -- Enable commands like GitConflictChooseOurs

      disable_diagnostics = true, -- Disable LSP diagnostics during conflicts

      list_opener = 'copen', -- Command to open quickfix list

      highlights = {
        incoming = 'DiffAdd',
        current = 'DiffText',
      },
    }

    -- Additional keybindings
    vim.keymap.set('n', '<leader>gxq', '<cmd>GitConflictListQf<cr>', { desc = '[G]it confli[X]t [Q]uickfix' })
    vim.keymap.set('n', '<leader>gxr', '<cmd>GitConflictRefresh<cr>', { desc = '[G]it confli[X]t [R]efresh' })
  end,
}
