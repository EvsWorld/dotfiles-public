return {
  {
    'zbirenbaum/copilot.lua',
    enabled = true,
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        suggestion = {
          enabled = true,
          auto_trigger = true,
          hide_during_completion = true,
          debounce = 75,
          keymap = {
            accept = 'Down',
            accept_word = '<Tab>',
            accept_line = '<Right>',
            next = '<M-]>',
            prev = '<M-[>',
            dismiss = '<C-]>',
          },
        },
        -- Allowlist: Copilot only runs in filetypes listed as `true`.
        -- Prevents LSP spawning in scratch buffers, terminals, and one-off files.
        filetypes = {
          ['*'] = false,
          lua = true,
          python = true,
          javascript = true,
          javascriptreact = true,
          typescript = true,
          typescriptreact = true,
          go = true,
          rust = true,
          sh = true,
          bash = true,
          css = true,
          html = true,
          json = true,
          toml = true,
          clojure = true,
        },
        copilot_node_command = 'node',
        server_opts_overrides = {},
      }
    end,
  },
}
