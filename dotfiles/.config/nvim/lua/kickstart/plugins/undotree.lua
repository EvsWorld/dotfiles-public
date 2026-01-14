return {
  'mbbill/undotree',

  config = function()
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.g.undotree_SplitWidth = 90 -- default is 30
    vim.g.undotree_DiffpanelHeight = 20 -- default is 10

    local function undotree_toggle()
      vim.cmd.UndotreeToggle()
    end

    vim.keymap.set('n', '<leader>u', undotree_toggle, { desc = 'Undotree Toggle' })

    -- Set the keymap in the undotree buffer as well
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'undotree',
      callback = function()
        vim.keymap.set(
          'n',
          '<leader>u',
          undotree_toggle,
          { buffer = true, desc = 'Undotree Toggle' }
        )
      end,
    })
  end,
}

