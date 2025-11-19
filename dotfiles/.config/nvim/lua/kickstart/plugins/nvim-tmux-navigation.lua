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
    { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
    { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
    { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
    { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
    { '<c-m-s-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
    { '<c-m-s-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
    { '<c-m-s-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
    { '<c-m-s-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
    { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
  },
  init = function()
    -- Disable wrapping when navigating between vim splits and tmux panes
    vim.g.tmux_navigator_no_wrap = 1
  end,
}
