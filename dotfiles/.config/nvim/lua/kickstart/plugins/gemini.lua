return {
  'kiddos/gemini.nvim',
  opts = {},
  config = function(_, opts)
    require('gemini').setup(opts)
    pcall(vim.keymap.del, 'n', '<Leader><Leader><Leader>g')
  end,
}
