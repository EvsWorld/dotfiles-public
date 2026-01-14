-- Highlight todo, notes, etc in comments

-- Default color names:
-- ERROR: -  red
-- WARNING: -  yellow/orange
-- INFO: -  blue
-- HINT: -  light blue/cyan
-- TEST: -  purple/magenta

return {
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      signs = false,
      keywords = {
        FIX = {
          icon = ' ', -- icon used for the sign, and in search results
          color = 'error', -- can be a hex color, or a named color (see below)
          alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE', 'ERROR' }, -- a set of other keywords that all map to this FIX keywords
        },
        TODO = { icon = ' ', color = 'info' },
        QUESTION = { icon = ' ', color = '#355E38' },
        HACK = { icon = ' ', color = 'warning' },
        WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'XXX' } },
        PERF = { icon = ' ', alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' } },
        NOTE = { icon = ' ', color = 'hint', alt = { 'INFO' } },
        TEST = { icon = '⏲ ', color = 'test', alt = { 'TESTING', 'PASSED', 'FAILED' } },
        REFACTOR = { icon = ' ', color = 'warning', alt = { 'REFACT' } },
        DELETE = { icon = ' ', color = 'warning' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
