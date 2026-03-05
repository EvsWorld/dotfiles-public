-- TODO: disable this plugin and revisit later
return {
  'samir-roy/code-bridge.nvim',
  enabled = false,
  config = function()
    require('code-bridge').setup()
    -- TODO: set up to work with tmux
    vim.keymap.set('n', '<leader>bt', ':CodeBridgeTmux<CR>', { desc = 'Send context to claude via tmux' })
    vim.keymap.set('v', '<leader>bt', ':CodeBridgeTmux<CR>', { desc = 'Send selection to claude via tmux' })
    vim.keymap.set('n', '<leader>bq', ':CodeBridgeQuery<CR>', { desc = 'Query claude with context' })
    vim.keymap.set('v', '<leader>bq', ':CodeBridgeQuery<CR>', { desc = 'Query claude with selection' })
    vim.keymap.set('n', '<leader>bc', ':CodeBridgeChat<CR>', { desc = 'Chat with claude' })
    vim.keymap.set('n', '<leader>bh', ':CodeBridgeHide<CR>', { desc = 'Hide chat window' })
    vim.keymap.set('n', '<leader>bs', ':CodeBridgeShow<CR>', { desc = 'Show chat window' })
    vim.keymap.set('n', '<leader>bx', ':CodeBridgeWipe<CR>', { desc = 'Wipe chat and clear history' })
    vim.keymap.set('n', '<leader>bk', ':CodeBridgeCancelQuery<CR>', { desc = 'Cancel running query' })
  end,
}
