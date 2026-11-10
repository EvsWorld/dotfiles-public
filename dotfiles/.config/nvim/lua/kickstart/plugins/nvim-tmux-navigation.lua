-- vim-tmux-navigator decides whether to hand a key to tmux by checking whether
-- `wincmd h` changed the window number (tmux_navigator.vim:122-127). Centering
-- puts a no-neck-pain padding window on each side, so that check always says
-- "moved inside Neovim", tmux never gets the key, and no-neck-pain's WinEnter
-- guard bounces focus back, trapping the cursor.
--
-- `tmux_navigator_no_mappings` is required: the plugin defines its own <C-hjkl>
-- mappings at load time (tmux_navigator.vim:17-22), silently overwriting the
-- ones lazy.nvim creates from `keys`. That also drops its terminal-mode
-- mappings, so those are redefined here.
--
-- See docs/2026-09-04-centered-markdown-reading-measure.md
local MODES = { 'n', 'i', 'x', 't' }

-- Padding is always the outermost window on its axis, so reaching it means we
-- are at Neovim's edge.
local function padding_is_next(key)
  local target = vim.fn.winnr('1' .. key)
  if target == vim.fn.winnr() then
    return false -- genuinely at the edge; let the plugin handle it
  end
  local buf = vim.api.nvim_win_get_buf(vim.fn.win_getid(target))
  return vim.bo[buf].filetype == 'no-neck-pain'
end

-- Same select-pane call and no-wrap guard as tmux_navigator.vim:143-149.
local function select_tmux_pane(edge, flag)
  vim.fn.system {
    'tmux',
    'if-shell',
    '-F',
    '#{' .. edge .. '}',
    '',
    ('select-pane -t %s -%s'):format(vim.env.TMUX_PANE or '', flag),
  }
end

local function navigate(key, command, edge, flag)
  return function()
    if vim.bo.filetype == 'fzf' then -- fzf owns these keys in its own buffer
      local lhs = vim.api.nvim_replace_termcodes('<C-' .. key .. '>', true, false, true)
      return vim.api.nvim_feedkeys(lhs, 'n', false)
    end
    if vim.env.TMUX and padding_is_next(key) then
      return select_tmux_pane(edge, flag)
    end
    vim.cmd(command)
  end
end

local left = navigate('h', 'TmuxNavigateLeft', 'pane_at_left', 'L')
local down = navigate('j', 'TmuxNavigateDown', 'pane_at_bottom', 'D')
local up = navigate('k', 'TmuxNavigateUp', 'pane_at_top', 'U')
local right = navigate('l', 'TmuxNavigateRight', 'pane_at_right', 'R')

return {
  'christoomey/vim-tmux-navigator',
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
    'TmuxNavigatePrevious',
    'TmuxNavigatorProcessList',
  },
  keys = {
    { '<c-h>', left, mode = MODES },
    { '<c-j>', down, mode = MODES },
    { '<c-k>', up, mode = MODES },
    { '<c-l>', right, mode = MODES },
    -- Ghostty sends Ctrl+Option+hjkl as these; same actions, different keys.
    { '<c-m-s-h>', left, mode = MODES },
    { '<c-m-s-j>', down, mode = MODES },
    { '<c-m-s-k>', up, mode = MODES },
    { '<c-m-s-l>', right, mode = MODES },
    { '<c-\\>', '<cmd>TmuxNavigatePrevious<cr>', mode = MODES },
  },
  init = function()
    vim.g.tmux_navigator_no_wrap = 1 -- don't wrap around at the outermost pane
    vim.g.tmux_navigator_no_mappings = 1 -- keep the mappings defined above
  end,
}
