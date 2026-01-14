return {
  'akinsho/git-conflict.nvim',
  version = '*',
  event = 'VeryLazy',
  config = function()
    require('git-conflict').setup {
      default_mappings = {
				-- TODO:  change this so doesnt conflict with color plugin
        ours = '<leader>6o',
        theirs = '<leader>6t',
        none = '<leader>60',
        both = '<leader>6b',
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
    vim.keymap.set('n', '<leader>6q', '<cmd>GitConflictListQf<cr>', { desc = '[C]onflict list [Q]uickfix' })
    vim.keymap.set('n', '<leader>6r', '<cmd>GitConflictRefresh<cr>', { desc = '[C]onflict [R]efresh' })
  end,
}
