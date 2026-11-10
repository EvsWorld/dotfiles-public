-- https://github.com/mrjones2014/smart-splits.nvim?tab=readme-ov-file#key-mappings
return {
  'mrjones2014/smart-splits.nvim',
  config = function()
    local smart_splits = require 'smart-splits'
    smart_splits.setup {
      -- Disable resizing when terminal at edge
      at_edge = 'stop',
      cursor_follows_swapped_bufs = true,
    }

    -- Smart splits resizing keymaps
    -- these keymaps will also accept a range,
    -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
    -- Ghostty maps Ctrl+Option+hjkl to the bytes ESC + uppercase H/J/K/L
    -- (0x1B 0x48 for H). Neovim names that byte pair <M-H>, where "M-" just
    -- means the leading ESC -- not a modifier key. nvim never sees the real
    -- modifiers, only these bytes. See ADR 021.
    vim.keymap.set(
      'n',
      '<M-H>',
      smart_splits.resize_left,
      { desc = '[W]indow: Resize split left' }
    )
    vim.keymap.set(
      'n',
      '<M-L>',
      smart_splits.resize_right,
      { desc = '[W]indow: Resize split right' }
    )
    vim.keymap.set(
      'n',
      '<M-J>',
      smart_splits.resize_down,
      { desc = '[W]indow: Resize split down' }
    )
    vim.keymap.set(
      'n',
      '<M-K>',
      smart_splits.resize_up,
      { desc = '[W]indow: Resize split up' }
    )

    -- Disabled: conflicts with vim-tmux-navigator
    -- vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
    -- vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
    -- vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
    -- vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)
    -- vim.keymap.set('n', '<C-\\>', require('smart-splits').move_cursor_previous)

    -- Swap buffers while keeping each buffer's cursor and scroll position with it.
    local swap_directions = {
      h = { direction = 'left', reverse = 'l' },
      j = { direction = 'down', reverse = 'k' },
      k = { direction = 'up', reverse = 'j' },
      l = { direction = 'right', reverse = 'h' },
    }

    local function window_view(win)
      return vim.api.nvim_win_call(win, vim.fn.winsaveview)
    end

    local function restore_window_view(win, view)
      vim.api.nvim_win_call(win, function()
        vim.fn.winrestview(view)
      end)
    end

    local function swap_buffer_with_view(key, swap)
      local source_win = vim.api.nvim_get_current_win()
      local source_buf = vim.api.nvim_get_current_buf()

      -- Let smart-splits retain its normal handling for floating windows.
      if vim.api.nvim_win_get_config(source_win).relative ~= '' then
        smart_splits['swap_buf_' .. swap.direction] { move_cursor = true }
        return
      end

      local at_edge = vim.fn.winnr() == vim.fn.winnr(key)
      local target_key = at_edge and swap.reverse or key
      local target_count = at_edge and 99999 or vim.v.count1
      local target_winnr = vim.fn.winnr(('%d%s'):format(target_count, target_key))
      local target_win = vim.fn.win_getid(target_winnr)

      if target_win == 0 or target_win == source_win then
        return
      end

      local target_buf = vim.api.nvim_win_get_buf(target_win)
      if target_buf == source_buf then
        smart_splits['swap_buf_' .. swap.direction] { move_cursor = true }
        return
      end

      local source_view = window_view(source_win)
      local target_view = window_view(target_win)
      smart_splits['swap_buf_' .. swap.direction] { move_cursor = true }

      if
        vim.api.nvim_win_is_valid(source_win)
        and vim.api.nvim_win_is_valid(target_win)
        and vim.api.nvim_win_get_buf(source_win) == target_buf
        and vim.api.nvim_win_get_buf(target_win) == source_buf
      then
        restore_window_view(source_win, target_view)
        restore_window_view(target_win, source_view)
      end
    end

    for key, swap in pairs(swap_directions) do
      vim.keymap.set('n', '<leader>w' .. key, function()
        swap_buffer_with_view(key, swap)
      end, { desc = ('[W]indow: Swap buffer %s'):format(swap.direction) })
    end

    -- Move current split to edge (uppercase directional keys)
    local move_to_edge_commands = {
      H = '<C-w>H',
      J = '<C-w>J',
      K = '<C-w>K',
      L = '<C-w>L',
    }
    for key, cmd in pairs(move_to_edge_commands) do
      local direction_names = {
        H = 'left edge',
        J = 'bottom edge',
        K = 'top edge',
        L = 'right edge',
      }
      vim.keymap.set('n', '<leader>w' .. key, cmd, {
        desc = ('[W]indow: Move current split to %s'):format(direction_names[key]),
      })
    end

    -- Window splitting (these override keyremaps.lua since plugins load last)
    vim.keymap.set('n', '<leader>wd', '<C-w>s', { desc = '[W]indow: Split Down (stacked)' })
    vim.keymap.set('n', '<leader>w.', '<C-w>s', { desc = '[W]indow: Split Down (stacked)' })
    vim.keymap.set('n', '<leader>.', '<C-w>s', { desc = '[W]indow: Split Down (stacked)' })
    vim.keymap.set('n', '<leader>wv', '<C-w>v', { desc = '[W]indow: Split Right (side-by-side)' })
    vim.keymap.set('n', '<leader>w,', '<C-w>v', { desc = '[W]indow: Split Right (side-by-side)' })
    vim.keymap.set('n', '<leader>,', '<C-w>v', { desc = '[W]indow: Split Right (side-by-side)' })

    -- Arrange existing windows, mirroring tmux Prefix+w+s/S layouts
    vim.keymap.set(
      'n',
      '<leader>ws',
      '<cmd>windo wincmd H | wincmd =<cr>',
      { desc = '[W]indow: Arrange even columns (side-by-side)' }
    )
    vim.keymap.set(
      'n',
      '<leader>wp',
      '<cmd>windo wincmd H | wincmd =<cr>',
      { desc = '[W]indow: Arrange even columns (side-by-side) [alias]' }
    )
    vim.keymap.set(
      'n',
      '<leader>wS',
      '<cmd>windo wincmd K | wincmd =<cr>',
      { desc = '[W]indow: Arrange even rows (stacked)' }
    )
    vim.keymap.set(
      'n',
      '<leader>wP',
      '<cmd>windo wincmd K | wincmd =<cr>',
      { desc = '[W]indow: Arrange even rows (stacked) [alias]' }
    )

    -- Zoom and restore, preserving prior split dimensions
    local zoom_state = {}
    local function toggle_zoom()
      local tabid = vim.api.nvim_get_current_tabpage()
      if zoom_state[tabid] then
        -- Restore previous split dimensions
        vim.cmd 'wincmd ='
        zoom_state[tabid] = nil
      else
        -- Save current state and maximize
        zoom_state[tabid] = true
        vim.cmd 'wincmd |'
        vim.cmd 'wincmd _'
      end
    end

    vim.keymap.set('n', '<leader>ww', '<C-w>=', { desc = '[W]indow: Equalize splits' })
    vim.keymap.set(
      'n',
      '<leader>wo',
      '<C-w>=',
      { desc = '[W]indow: Equalize splits [alias]' }
    )

    vim.keymap.set(
      'n',
      '<leader>we',
      toggle_zoom,
      { desc = '[W]indow: Toggle maximize current split' }
    )
    vim.keymap.set(
      'n',
      '<leader>wi',
      toggle_zoom,
      { desc = '[W]indow: Toggle maximize current split [alias]' }
    )

    -- Fast path for zoom, mirroring tmux Prefix+p
    vim.keymap.set(
      'n',
      '<leader>p',
      toggle_zoom,
      { desc = '[W]indow: Toggle maximize current split (fast path)' }
    )

    -- TODO: make sure undotree has a minimum size
  end,
}
