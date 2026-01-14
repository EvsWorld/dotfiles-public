-- Alpha dashboard for nvim-kickstart welcome screen
return {
  'goolord/alpha-nvim',
  event = 'VimEnter',
  config = function()
    local alpha = require 'alpha'
    local dashboard = require 'alpha.themes.dashboard'

    -- Custom ASCII art header
    dashboard.section.header.val = {
      [[                                                     ]],
      [[  ███╗   ██╗██╗   ██╗██╗███╗   ███╗               ]],
      [[  ████╗  ██║██║   ██║██║████╗ ████║               ]],
      [[  ██╔██╗ ██║██║   ██║██║██╔████╔██║               ]],
      [[  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║               ]],
      [[  ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║               ]],
      [[  ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝               ]],
      [[                                                     ]],
      [[ ██╗  ██╗██╗ ██████╗██╗  ██╗███████╗████████╗ █████╗ ██████╗ ████████╗]],
      [[ ██║ ██╔╝██║██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝]],
      [[ █████╔╝ ██║██║     █████╔╝ ███████╗   ██║   ███████║██████╔╝   ██║   ]],
      [[ ██╔═██╗ ██║██║     ██╔═██╗ ╚════██║   ██║   ██╔══██║██╔══██╗   ██║   ]],
      [[ ██║  ██╗██║╚██████╗██║  ██╗███████║   ██║   ██║  ██║██║  ██║   ██║   ]],
      [[ ╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ]],
      [[                                                     ]],
      [[        🚀 A NEOVIM CONFIG FOR THE FEARLESS 🚀       ]],
      [[                                                     ]],
    }

    -- Menu buttons
    dashboard.section.buttons.val = {
      dashboard.button('e', '  New file', ':ene <BAR> startinsert <CR>'),
      dashboard.button('f', '󰈞  Find file', ':Telescope find_files<CR>'),
      dashboard.button('g', '󰊄  Find word', ':Telescope live_grep<CR>'),
      dashboard.button('r', '󰄉  Recent files', ':Telescope oldfiles<CR>'),
      dashboard.button('c', '  Config', ':e $MYVIMRC<CR>'),
      dashboard.button('h', '󰘥  Check health', ':checkhealth<CR>'),
      dashboard.button('l', '󰒲  Lazy', ':Lazy<CR>'),
      dashboard.button('q', '  Quit', ':qa<CR>'),
    }

    -- Footer
    dashboard.section.footer.val = {
      '',
      '💡 Tip: Use <space>sh to search help docs',
      '🔧 This is your KICKSTART configuration',
      '📚 Learn more: :help kickstart',
      '',
      'Happy coding! 🎉',
    }

    -- Configure layout
    dashboard.config.layout = {
      { type = 'padding', val = 2 },
      dashboard.section.header,
      { type = 'padding', val = 2 },
      dashboard.section.buttons,
      { type = 'padding', val = 1 },
      dashboard.section.footer,
    }

    -- Set colors
    dashboard.section.header.opts.hl = 'Include'
    dashboard.section.buttons.opts.hl = 'Keyword'
    dashboard.section.footer.opts.hl = 'Type'

    -- Don't show statusline on alpha buffer
    vim.api.nvim_create_autocmd('User', {
      pattern = 'AlphaReady',
      desc = 'disable statusline for alpha',
      callback = function()
        local old_laststatus = vim.opt.laststatus
        vim.api.nvim_create_autocmd('BufUnload', {
          buffer = 0,
          callback = function()
            vim.opt.laststatus = old_laststatus
          end,
        })
        vim.opt.laststatus = 0
      end,
    })

    alpha.setup(dashboard.config)
  end,
}

