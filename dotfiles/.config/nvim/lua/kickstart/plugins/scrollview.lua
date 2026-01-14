-- nvim-scrollview: Minimal scrollbar for Neovim
return {
  'dstein64/nvim-scrollview',
  opts = {
    excluded_filetypes = { 'alpha', 'dashboard', 'oil', 'lazy' },
    current_only = false, -- Only show scrollbar in current window
    base = 'right', -- Position on right side
    column = 1, -- Distance from right edge
    signs_on_startup = { 'all' }, -- Disable the T symbols
    diagnostics_severities = {
      vim.diagnostic.severity.ERROR,
      vim.diagnostic.severity.WARN,
    },
    -- Make it not cover text
    scrollview_character = '█',
    scrollview_winblend = 20,
  },
}
