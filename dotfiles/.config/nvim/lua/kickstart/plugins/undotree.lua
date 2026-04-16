return {
  'mbbill/undotree',

  config = function()
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.g.undotree_SplitWidth = 90 -- default is 30
    vim.g.undotree_DiffpanelHeight = 20 -- default is 10

    local function apply_undotree_diff_highlights()
      vim.api.nvim_set_hl(0, 'UndotreeDiffAdd', { fg = '#dff6dd', bg = '#1f5f3a', bold = true })
      vim.api.nvim_set_hl(0, 'UndotreeDiffDelete', { fg = '#ffe2e2', bg = '#7a1f2b', bold = true })
      vim.api.nvim_set_hl(0, 'UndotreeDiffChange', { fg = '#fff1cc', bg = '#7a4b00', bold = true })

      vim.api.nvim_set_hl(0, 'diffAdded', { link = 'UndotreeDiffAdd' })
      vim.api.nvim_set_hl(0, 'diffRemoved', { link = 'UndotreeDiffDelete' })
      vim.api.nvim_set_hl(0, 'diffChanged', { link = 'UndotreeDiffChange' })

      vim.g.undotree_HighlightSyntaxAdd = 'UndotreeDiffAdd'
      vim.g.undotree_HighlightSyntaxDel = 'UndotreeDiffDelete'
      vim.g.undotree_HighlightSyntaxChange = 'UndotreeDiffChange'
    end

    apply_undotree_diff_highlights()
    vim.api.nvim_create_autocmd('ColorScheme', {
      callback = apply_undotree_diff_highlights,
    })

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
