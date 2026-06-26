return {
  'yetone/avante.nvim',
  enabled = false,
  cmd = {
    'AvanteAsk',
    'AvanteChat',
    'AvanteChatNew',
    'AvanteToggle',
    'AvanteEdit',
    'AvanteRefresh',
    'AvanteFocus',
    'AvanteSwitchProvider',
    'AvanteSwitchSelectorProvider',
    'AvanteSwitchInputProvider',
  },
  keys = {
    '<leader>vv',
    '<leader>ve',
    '<leader>vf',
    '<leader>vn',
    '<leader>vh',
    '<leader>vm',
    '<leader>vk',
    '<leader>vt',
    '<leader>vc',
  },
  version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
  opts = {
    -- Disabled for now because this config previously depended on Copilot.
    -- TODO: make the avante chat output wrap. right now it just goes off the screen and i have to scroll to see the rest of the answer
    behaviour = {
      minimize_diff = false, -- vim.text.diff not available in nvim 0.11.x
    },
    windows = {
      wrap = true,
    },
    mappings = {
      ask = '<leader>vv',
      edit = '<leader>ve',
      focus = '<leader>vf',
      new_ask = '<leader>vn',
      select_history = '<leader>vh',
      select_model = '<leader>vm',
      stop = '<leader>vk',
      toggle = {
        default = '<leader>vt',
      },
      files = {
        add_current = '<leader>vc',
      },
      submit = {
        normal = '<CR>',
        insert = '<C-y>',
      },
    },
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = 'make',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    --- The below dependencies are optional,
    'echasnovski/mini.pick', -- for file_selector provider mini.pick
    'nvim-telescope/telescope.nvim', -- for file_selector provider telescope
    'hrsh7th/nvim-cmp', -- autocompletion for avante commands and mentions
    'ibhagwan/fzf-lua', -- for file_selector provider fzf
    'nvim-tree/nvim-web-devicons', -- or echasnovski/mini.icons
    {
      -- support for image pasting
      'HakonHarnes/img-clip.nvim',
      event = 'VeryLazy',
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = false,
        },
      },
    },
  },
}
