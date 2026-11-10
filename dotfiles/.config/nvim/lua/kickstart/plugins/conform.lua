local function format_and_write()
  require('conform').format {
    async = false,
    lsp_format = 'fallback',
  }
  vim.cmd 'silent! write'
end

return {
  { -- Autoformat
    'stevearc/conform.nvim',
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>h',
        format_and_write,
        mode = 'n',
        desc = 'Format and write buffer',
      },
      {
        'M',
        format_and_write,
        mode = 'n',
        desc = 'Format and write buffer',
      },
    },
    opts = {
      notify_on_error = false,
      -- No format_on_save: saving never reformats. Formatting stays explicit,
      -- Other mappings write without changing the buffer.
      formatters_by_ft = {
        lua = { 'stylua' },
        json = { 'prettier' },
        clojure = { 'cljfmt' },
        toml = { 'taplo' },
        markdown = { 'markdownlint' },
        -- TODO: this might be causing problems with some files
        -- ['*'] = { 'trim_whitespace' },

        -- Conform can also run multiple formatters sequentially
        python = { 'isort', 'black' },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
