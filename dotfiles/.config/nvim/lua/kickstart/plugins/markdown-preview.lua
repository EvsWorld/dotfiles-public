-- https://github.com/iamcco/markdown-preview.nvim
return {
  'iamcco/markdown-preview.nvim',
  keys = {
    {
      -- TODO: fix
      -- ERROR: E492: Not an editor command: MarkdownPreviewToggle
      '<leader>\\mt',
      ft = 'markdown',
      '<cmd>MarkdownPreviewToggle<cr>',
      desc = 'Markdown Preview',
    },
  },
}
