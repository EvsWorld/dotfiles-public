-- https://github.com/chrisgrieser/nvim-spider
return {
  'chrisgrieser/nvim-spider',
  lazy = true,
  keys = {
    {
      'w',
      "<cmd>lua require('spider').motion('w')<CR>",
      mode = { 'n', 'o', 'x' },
      desc = 'Spider w (subword forward)',
    },
    {
      'e',
      "<cmd>lua require('spider').motion('e')<CR>",
      mode = { 'n', 'o', 'x' },
      desc = 'Spider e (subword end)',
    },
    {
      'b',
      "<cmd>lua require('spider').motion('b')<CR>",
      mode = { 'n', 'o', 'x' },
      desc = 'Spider b (subword backward)',
    },
    {
      'ge',
      "<cmd>lua require('spider').motion('ge')<CR>",
      mode = { 'n', 'o', 'x' },
      desc = 'Spider ge (subword end backward)',
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
