-- https://github.com/mrjones2014/smart-splits.nvim?tab=readme-ov-file#key-mappings
return {
  'mrjones2014/smart-splits.nvim',
  config = function()
    require('smart-splits').setup {
      -- Disable resizing when terminal at edge
      at_edge = 'stop',
    }

    -- Smart splits resizing keymaps
    -- these keymaps will also accept a range,
    -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
    -- Map the escape sequences from Ghostty (Alt+Shift+hjkl sent as Meta+UpperCase)
    vim.keymap.set(
      'n',
      '<M-H>',
      require('smart-splits').resize_left,
      { desc = '[W]indow: Resize split left' }
    )
    vim.keymap.set(
      'n',
      '<M-L>',
      require('smart-splits').resize_right,
      { desc = '[W]indow: Resize split right' }
    )
    vim.keymap.set(
      'n',
      '<M-J>',
      require('smart-splits').resize_down,
      { desc = '[W]indow: Resize split down' }
    )
    vim.keymap.set(
      'n',
      '<M-K>',
      require('smart-splits').resize_up,
      { desc = '[W]indow: Resize split up' }
    )

    -- Disabled: conflicts with vim-tmux-navigator
    -- vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
    -- vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
    -- vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
    -- vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)
    -- vim.keymap.set('n', '<C-\\>', require('smart-splits').move_cursor_previous)

    -- -- Smart splits - swapping buffers between windows
    vim.keymap.set(
      'n',
      '<leader>wh',
      require('smart-splits').swap_buf_left,
      { desc = '[W]indow: [S]wap buffer left' }
    )
    vim.keymap.set(
      'n',
      '<leader>wj',
      require('smart-splits').swap_buf_down,
      { desc = '[W]indow: [S]wap buffer down' }
    )
    vim.keymap.set(
      'n',
      '<leader>wk',
      require('smart-splits').swap_buf_up,
      { desc = '[W]indow: [S]wap buffer up' }
    )
    vim.keymap.set(
      'n',
      '<leader>wl',
      require('smart-splits').swap_buf_right,
      { desc = '[W]indow: [S]wap buffer right' }
    )

    -- Window splitting (these override keyremaps.lua since plugins load last)
    vim.keymap.set('n', '<leader>wd', '<C-w>s', { desc = '[W]indow: Split horizontally' })
    vim.keymap.set('n', '<leader>wv', '<C-w>v', { desc = '[W]indow: Split vertically' })

    -- Toggle maximize current split
    local function toggle_maximize()
      if vim.t.maximized then
        vim.cmd 'wincmd ='
        vim.t.maximized = false
      else
        vim.cmd 'wincmd |'
        vim.cmd 'wincmd _'
        vim.t.maximized = true
      end
    end
    vim.keymap.set(
      'n',
      '<leader>ww',
      toggle_maximize,
      { desc = '[W]indow: Toggle maximize split' }
    )

    -- Equalize splits
    vim.keymap.set('n', '<leader>we', '<C-w>=', { desc = '[W]indow: Equalize splits' })

    -- TODO: make sure undotree has a minimum size
  end,
}
