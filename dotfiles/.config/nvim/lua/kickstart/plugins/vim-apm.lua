return {
  'ThePrimeagen/vim-apm',
  config = function()
    local apm = require 'vim-apm'
    apm:setup {}
    -- TODO: assign to keymap that doesnt conflict. some low frequency starter key
    vim.keymap.set('n', '<leader><F8>', function()
      apm:toggle_monitor()
    end)
  end,
}
