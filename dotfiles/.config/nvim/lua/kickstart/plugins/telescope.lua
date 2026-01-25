-- NOTE: Plugins can specify dependencies.

-- The dependencies are proper plugin specifications as well - anything
-- you do for a plugin at the top level, you can do for a dependency.

-- Use the `dependencies` key to specify the dependencies of a particular plugin

return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      -- Custom action to set search register when opening files from grep
      local function set_search_register(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local prompt = picker:_get_prompt()

        -- Only set search register for grep-based searches
        if prompt and prompt ~= '' then
          -- Escape special characters for vim search
          local search_term = vim.fn.escape(prompt, '\\/.*$^~[]')
          -- Set the search register
          vim.fn.setreg('/', search_term)
          -- Enable search highlighting
          vim.cmd 'set hlsearch'
        end

        -- Proceed with normal file selection
        actions.select_default(prompt_bufnr)
      end

      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`

        defaults = {
          file_ignore_patterns = {
            '.git/.*',
            '.undodir/.*',
            'nvim%-archive/.*',
            'sessions/.*',
            'package%-lock%.json',
            'Projects/dotfilesPublish/dotfiles/.*',
          },
          path_display = { 'truncate' },
          dynamic_preview_title = true,
          layout_strategy = 'flex',
          layout_config = {
            width = 0.95,
            height = 0.95,
            horizontal = {
              preview_width = 0.6,
            },
            vertical = {
              preview_height = 0.5,
            },
            flex = {
              flip_columns = 100, -- Switch to vertical when width < 100
            },
            prompt_position = 'bottom',
            preview_cutoff = 50, -- Lower cutoff since we have vertical fallback
          },
          preview = {
            highlight_limit = 0.5,
          },
          mappings = {
            i = {
              ['<C-s>'] = set_search_register,
              ['<C-enter>'] = 'to_fuzzy_refine', -- TODO: fix
              ['<C-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
              ['<C-a>'] = actions.send_to_qflist + actions.open_qflist,
            },
            n = {
              ['<C-s>'] = set_search_register,
            },
          },
        },
        -- pickers = {}
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- Enable line wrapping in Telescope previews for markdown files
      vim.api.nvim_create_autocmd('User', {
        pattern = 'TelescopePreviewerLoaded',
        callback = function(args)
          if args.data.filetype == 'markdown' then
            vim.wo.wrap = true
          end
        end,
      })

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'

      -- TODO: make all these default to search with very magic mode

      -- ═══════════════════════════════════════════════════════════════════════════════
      -- GIT INTEGRATION WITH DIFFVIEW
      -- ═══════════════════════════════════════════════════════════════════════════════
      vim.keymap.set('n', '<leader>gc', function()
        builtin.git_commits {
          attach_mappings = function(_, map)
            map('i', '<CR>', function(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              vim.cmd('DiffviewOpen ' .. selection.value .. '^!')
            end)
            return true
          end,
        }
      end, { desc = '[G]it [C]ommits (open in diffview)' })

      vim.keymap.set('n', '<leader>gb', function()
        builtin.git_branches {
          attach_mappings = function(_, map)
            map('i', '<CR>', function(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              -- Compare current branch with selected branch
              vim.cmd('DiffviewOpen ' .. selection.value)
            end)
            return true
          end,
        }
      end, { desc = '[G]it [B]ranches (compare in diffview)' })

      -- ═══════════════════════════════════════════════════════════════════════════════
      -- META/HELP SEARCHES
      -- ═══════════════════════════════════════════════════════════════════════════════
      vim.keymap.set(
        'n',
        '<leader>fH',
        builtin.builtin,
        { desc = '[F]ind [S]elect Telescope' }
      )
      vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' })
      vim.keymap.set('n', '<leader>fp', builtin.help_tags, { desc = '[F]ind [H]el[P]' })
      vim.keymap.set(
        'n',
        '<leader>fd',
        builtin.diagnostics,
        { desc = '[F]ind [D]iagnostics' }
      )

      -- ═══════════════════════════════════════════════════════════════════════════════
      -- FILE SEARCHES
      -- ═══════════════════════════════════════════════════════════════════════════════
      vim.keymap.set('n', '<leader>ff', function()
        builtin.find_files { hidden = true }
      end, { desc = '[F]ind [F]iles' })

      vim.keymap.set('n', '<leader>fF', function()
        require('telescope.builtin').find_files {
          cwd = vim.fn.expand '%:p:h',
          hidden = true,
        }
      end, { desc = '[F]ind [F]iles in cwd' })

      vim.keymap.set(
        'n',
        '<leader>f.',
        builtin.oldfiles,
        { desc = '[F]ind Recent Files ("." for repeat)' }
      )
      vim.keymap.set(
        'n',
        '<leader>fb',
        builtin.buffers,
        { desc = '[F]ind existing [B]uffers' }
      )

      -- TODO: why doesnt this work when in the nvim dir?
      vim.keymap.set('n', '<leader>fn', function()
        builtin.find_files {
          cwd = vim.fn.stdpath 'config',
          prompt_title = '[F]ind [N]eovim files',
          hidden = true,
        }
      end, { desc = '[F]ind [N]eovim files' })

      vim.keymap.set('n', '<leader>ft', function()
        local nvim_dir = vim.fn.stdpath 'config'
        local tmux_dir = vim.fn.expand '~/.config/tmux'
        local ghostty_dir = vim.fn.expand '~/.config/ghostty'
        local claude_dir = vim.fn.expand '~/.config/.claude'
        local opencode_dir = vim.fn.expand '~/.config/opencode'
        local gemini_dir = vim.fn.expand '~/.gemini'
        local ohmyzsh_custom_dir = vim.fn.expand '~/.config/oh-my-zsh/custom'
        local home = vim.fn.expand '~'
        builtin.find_files {
          prompt_title = '[F]ind [N]eovim, [T]mux, Ghostty & config files',
          cwd = home,
          find_command = {
            'sh',
            '-c',
            string.format(
              '(find "%s" "%s" "%s" "%s" "%s" "%s" "%s" -type f 2>/dev/null; printf "%%s\\n" "%s/.ssh/config" "%s/.config/gh/config.yml" "%s/.config/gemini.md" "%s/.zshrc" "%s/.zshenv" "%s/.zprofile" "%s/.bash_profile" "%s/.gitconfig" "%s/.gitignore_global" "%s/.vimrc" "%s/.config/karabiner.edn") | sort -u',
              nvim_dir,
              tmux_dir,
              ghostty_dir,
              claude_dir,
              opencode_dir,
              gemini_dir,
              ohmyzsh_custom_dir,
              home,
              home,
              home,
              home,
              home,
              home,
              home,
              home,
              home,
              home,
              home
            ),
          },
        }
      end, { desc = '[F]ind [N]eovim, [T]mux, Ghostty & config files' })

      -- TODO: make this so it searches for shortcuts, and when i hit enter on the found result,
      -- it goes to the shortcut where the shortcut is defined, not execute the shortcut.
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })

      vim.keymap.set('n', '<leader>fg', function()
        builtin.find_files {
          cwd = vim.fn.expand '~/code/sennderCode',
          prompt_title = '[F]ind [S]ennder files',
          hidden = true,
        }
      end, { desc = '[F]ind [S]ennder files' })

      -- Location-specific file searches
      vim.keymap.set('n', '<leader>fc', function()
        builtin.find_files {
          cwd = vim.fn.expand '~/.config',
          prompt_title = '[F]ind [F]iles in ~/.config',
          hidden = true,
        }
      end, { desc = '[F]ind [F]iles in ~/.config' })

      vim.keymap.set('n', '<leader>fh', function()
        builtin.find_files {
          cwd = vim.fn.expand '~/',
          hidden = true,
        }
      end, { desc = '[F]ind [F]iles in [H]ome' })

      vim.keymap.set('n', '<leader>fo', function()
        builtin.find_files {
          cwd = vim.fn.expand '~/Documents/ObsidianVault',
          prompt_title = '[F]ind [O]bsidian files',
          find_command = {
            'rg',
            '--files',
            '--glob',
            '*.md',
            '--glob',
            '*.txt',
          },
        }
      end, { desc = '[F]ind [O]bsidian files' })

      vim.keymap.set('n', '<leader>fai', function()
        local home = vim.fn.expand '~'
        builtin.find_files {
          prompt_title = '[F]ind [A]I [I]nstruction files (CLAUDE.md, gemini.md, agent.md)',
          cwd = home,
          find_command = {
            'sh',
            '-c',
            string.format(
              'find "%s/Projects" "%s/projects" "%s/code" -type f \\( -iname "CLAUDE.md" -o -iname "gemini.md" -o -iname "agent.md" \\) 2>/dev/null | sort',
              home,
              home,
              home
            ),
          },
        }
      end, { desc = '[F]ind [A]I [I]nstruction files across projects' })

      -- ═══════════════════════════════════════════════════════════════════════════════
      -- LIVE GREP SEARCHES (Type and search as you go)
      -- ═══════════════════════════════════════════════════════════════════════════════
      -- QUESTION: When searching using this function, I have to escape brackets (\[) for some reason.
      vim.keymap.set('n', '<leader>ss', function()
        builtin.live_grep {
          prompt_title = '[S]earch by Grep in project',
        }
      end, { desc = '[S]earch by Grep in project' })

      vim.keymap.set('n', '<leader>sS', function()
        builtin.live_grep {
          cwd = vim.fn.expand '%:p:h',
          prompt_title = '[S]earch by Grep in cwd',
        }
      end, { desc = '[S]earch by Grep in cwd' })

      -- TODO: make a search for all things sennder (obsidian and code) some conbination
      -- of <leader>sg and <leader>so
      -- TODO: make this work like the obsidian package:
      -- { '<leader>so', '<cmd>Obsidian search<cr>', desc = '[O]bsidian [S]earch' },
      --  $HOME/.config/nvim/lua/kickstart/plugins/obsidian.lua:88
      vim.keymap.set('n', '<leader>sG', function()
        builtin.live_grep {
          search_dirs = {
            vim.fn.expand '~/code/sennderCode',
            vim.fn.expand '~/Documents/ObsidianVault',
            vim.fn.expand '~/Documents/ObsidianVault',
          },
          prompt_title = '[S]earch by Grep Sennder Code and Obsidian Notes',
        }
      end, { desc = '[S]earch by Grep Sennder Code and Obsidian Notes' })

      vim.keymap.set('n', '<leader>sg', function()
        builtin.live_grep {
          cwd = vim.fn.expand '~/code/sennderCode',
          prompt_title = '[S]earch by Grep Sennder Code',
        }
      end, { desc = '[S]earch by Grep Sennder Code' })

      -- TODO: make this work when searching for "things with [ or ]"
      -- to find what i needed, i had to manually type \ to escape [ and ] symbols
      -- vim.keymap.set('n', '<leader>ssc', function()
      --   builtin.live_grep {
      --     cwd = vim.fn.expand '~/.config',
      --     -- TODO: ignore nvim-archive everywhere
      --     prompt_title = '[F]ind by [G]rep in ~/.config',
      --   }
      -- end, { desc = '[F]ind by [G]rep in ~/.config' })

      -- TODO: test using dropdown
      -- vim.keymap.set('n', '<leader>scc', function()
      --   builtin.live_grep(require('telescope.themes').get_dropdown {
      --     winblend = 10,
      --     previewer = true,
      --     cwd = vim.fn.expand '~/.config',
      --     prompt_title = '[F]ind by [G]rep in ~/.config',
      --   })
      -- end, { desc = '[F]ind by [G]rep in ~/.config' })

      vim.keymap.set('n', '<leader>sn', function()
        builtin.live_grep {
          cwd = vim.fn.expand '~/.config/nvim',
          prompt_title = '[S]earch by Grep in Nvim files',
        }
      end, { desc = '[S]earch by Grep in [N]vim files' })

      vim.keymap.set('n', '<leader>st', function()
        builtin.live_grep {
          search_dirs = {
            vim.fn.stdpath 'config',                      -- nvim
            vim.fn.expand '~/.config/tmux',               -- tmux
            vim.fn.expand '~/.config/ghostty',            -- ghostty
            vim.fn.expand '~/.ssh/config',                -- ssh
            vim.fn.expand '~/.config/gh/config.yml',      -- github cli
            vim.fn.expand '~/.config/.claude',            -- claude code
            vim.fn.expand '~/.config/opencode',           -- opencode cli
            vim.fn.expand '~/.gemini',                    -- gemini
            vim.fn.expand '~/.config/gemini.md',          -- gemini config
            vim.fn.expand '~/.config/karabiner.edn',      -- karabiner
            vim.fn.expand '~/.config/oh-my-zsh/custom',   -- all custom zsh files
            vim.fn.expand '~/.zshrc',                     -- zsh configs
            vim.fn.expand '~/.zshenv',
            vim.fn.expand '~/.zprofile',
            vim.fn.expand '~/.bash_profile',
            vim.fn.expand '~/.gitconfig',                 -- git configs
            vim.fn.expand '~/.gitignore_global',
            vim.fn.expand '~/.vimrc',                     -- vim
          },
          prompt_title = '[S]earch by Grep in [N]eovim, [T]mux, Ghostty & config files',
        }
      end, { desc = '[S]earch by Grep in [N]eovim, [T]mux, Ghostty & config files' })

      vim.keymap.set('n', '<leader>sai', function()
        builtin.live_grep {
          search_dirs = {
            vim.fn.expand '~/Projects',
            vim.fn.expand '~/projects',
            vim.fn.expand '~/code',
          },
          prompt_title = '[S]earch content in [A]I [I]nstruction files',
          additional_args = function()
            return {
              '--glob-case-insensitive',
              '--glob', 'CLAUDE.md',
              '--glob', 'gemini.md',
              '--glob', 'agent.md',
            }
          end,
        }
      end, { desc = '[S]earch content in [A]I [I]nstruction files across projects' })

      vim.keymap.set('n', '<leader>sh', function()
        builtin.live_grep {
          cwd = vim.fn.expand '~/',
          prompt_title = '[S]earch by Grep in ~/',
        }
      end, { desc = '[S]earch by Grep in [H]ome' })

      vim.keymap.set('n', '<leader>sz', function()
        builtin.live_grep {
          search_dirs = {
            vim.fn.expand '~/.zshrc',
            vim.fn.expand '~/.zshenv',
            vim.fn.expand '~/.zprofile',
            vim.fn.expand '~/.bash_profile',
            vim.fn.expand '~/.config/oh-my-zsh/custom/aliases.zsh',
            vim.fn.expand '~/.config/oh-my-zsh/custom/evan_robbyrussell_theme.zsh-theme',
          },
          prompt_title = '[S]earch by Grep in [Z]sh/shell config files',
        }
      end, { desc = '[S]earch by Grep in [Z]sh/shell config files' })

      -- vim.keymap.set('n', '<leader>so', function()
      --   builtin.live_grep {
      --     cwd = vim.fn.expand '~/Documents/ObsidianVault',
      --     prompt_title = '[S]earch by Grep in [O]bsidian',
      --   }
      -- end, { desc = '[S]earch by Grep in [O]bsidian' })

      vim.keymap.set('n', '<leader>shh', function()
        builtin.live_grep(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = true,
          -- cwd = vim.fn.expand '~/.config/nvim',
          prompt_title = 'Fuzzy search in Nvim files',
        })
      end, { desc = '[S]earch by Grep in [H]ome' })

      vim.keymap.set('n', '<leader>sls', function()
        builtin.live_grep {
          default_text = '',
          prompt_title = '[F]ind [L]iteral [S]tring live grep',
          vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--fixed-strings', -- This makes rg treat patterns literally
          },
        }
      end, { desc = '[F]ind [L]iteral [S]tring live grep' })

      -- ═══════════════════════════════════════════════════════════════════════════════
      -- WORD UNDER CURSOR SEARCHES (word - bounded by word characters)
      -- ═══════════════════════════════════════════════════════════════════════════════
      vim.keymap.set(
        'n',
        '<leader>sw',
        builtin.grep_string,
        { desc = '[F]ind current [W]ord in project' }
      )
      vim.keymap.set('n', '<leader>swc', function()
        builtin.grep_string { cwd = vim.fn.expand '~/.config' }
      end, { desc = '[F]ind current [W]ord in ~/.config' })

      vim.keymap.set('n', '<leader>swh', function()
        builtin.grep_string { cwd = vim.fn.expand '~/' }
      end, { desc = '[F]ind current [W]ord in [H]ome ~/' })

      -- ═══════════════════════════════════════════════════════════════════════════════
      -- WORD UNDER CURSOR SEARCHES (WORD - bounded by whitespace)
      -- ═══════════════════════════════════════════════════════════════════════════════
      vim.keymap.set('n', '<leader>sW', function()
        local word = vim.fn.expand '<cWORD>'
        builtin.grep_string { search = word }
      end, { desc = 'Search grep current cWORD in project' })

      vim.keymap.set('n', '<leader>sWc', function()
        local word = vim.fn.expand '<cWORD>'
        local cwd = vim.fn.expand '~/.config'
        builtin.grep_string { search = word, cwd }
      end, { desc = 'Search grep current cWORD in ~/.config' })

      vim.keymap.set('n', '<leader>sWh', function()
        local word = vim.fn.expand '<cWORD>'
        local cwd = vim.fn.expand '~/'
        builtin.grep_string { search = word, cwd }
      end, { desc = 'Search grep current cWORD in [H]ome ~/' })

      -- ═══════════════════════════════════════════════════════════════════════════════
      -- VISUAL SELECTION SEARCH
      -- ═══════════════════════════════════════════════════════════════════════════════
      vim.keymap.set('v', '<leader>sw', function()
        -- Get the visually selected text
        local mode = vim.fn.mode()
        if mode == 'v' or mode == 'V' or mode == '' then
          -- Yank selected text to register s
          vim.cmd 'normal! "sy'
          local selected_text = vim.fn.getreg 's'
          -- Clean up the text (remove leading/trailing whitespace and newlines)
          selected_text = vim.trim(selected_text:gsub('\n', ' '))
          if selected_text ~= '' then
            builtin.grep_string {
              search = selected_text,
              use_regex = false,
              prompt_title = '[F]ind visual [W]ord selection in project',
            }
          end
        end
      end, { desc = '[F]ind visual [W]ord selection in project' })

      vim.keymap.set('v', '<leader>swc', function()
        local mode = vim.fn.mode()
        if mode == 'v' or mode == 'V' or mode == '' then
          -- Yank selected text to register s
          vim.cmd 'normal! "sy'
          local selected_text = vim.fn.getreg 's'
          -- Clean up the text (remove leading/trailing whitespace and newlines)
          selected_text = vim.trim(selected_text:gsub('\n', ' '))
          if selected_text ~= '' then
            builtin.grep_string {
              search = selected_text,
              cwd = vim.fn.expand '~/.config',
              use_regex = false,
              prompt_title = '[S]earch visual [W]ord selection in ~/.[C]onfig',
            }
          end
        end
      end, { desc = '[S]earch visual [W]ord selection in ~/.[C]onfig' })

      vim.keymap.set('v', '<leader>swh', function()
        -- Get the visually selected text
        local mode = vim.fn.mode()
        if mode == 'v' or mode == 'V' or mode == '' then
          -- Yank selected text to register s
          vim.cmd 'normal! "sy'
          local selected_text = vim.fn.getreg 's'
          -- Clean up the text (remove leading/trailing whitespace and newlines)
          selected_text = vim.trim(selected_text:gsub('\n', ' '))
          if selected_text ~= '' then
            builtin.grep_string {
              search = selected_text,
              cwd = vim.fn.expand '~/',
              use_regex = false,
              prompt_title = '[S]earch visual [W]ord selection in [H]ome ~/',
            }
          end
        end
      end, { desc = '[S]earch visual [W]ord selection in [H]ome ~/' })

      -- ═══════════════════════════════════════════════════════════════════════════════
      -- BUFFER-SPECIFIC SEARCHES
      -- ═══════════════════════════════════════════════════════════════════════════════

      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = true,
          prompt_title = '[/] Fuzzy search in current buffer',
        })
      end, { desc = '[/] Fuzzy search in current buffer' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
