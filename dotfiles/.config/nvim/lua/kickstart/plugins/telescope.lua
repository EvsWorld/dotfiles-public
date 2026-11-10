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
      {
        'nvim-telescope/telescope-live-grep-args.nvim',
        version = '^1.0.0',
      },

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
      local lga_actions = require 'telescope-live-grep-args.actions'

      -- Push the current grep prompt into the `/` register and turn on the
      -- transient highlight, so handing results off to a file or the quickfix
      -- list keeps matches highlighted (e.g. when jumping with ]q / [q).
      local function set_search_from_prompt(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local prompt = picker:_get_prompt()

        -- Only set search register for grep-based searches
        if prompt and prompt ~= '' then
          -- Escape special characters for vim search
          local search_term = vim.fn.escape(prompt, '\\/.*$^~[]')
          -- Set the search register
          vim.fn.setreg('/', search_term)
          -- Keep Telescope handoff aligned with native transient search behavior.
          if _G.EnableSearchHighlight then
            _G.EnableSearchHighlight()
          else
            vim.o.hlsearch = true
          end
        end
      end

      -- Custom action to set search register when opening files from grep
      local function set_search_register(prompt_bufnr)
        set_search_from_prompt(prompt_bufnr)
        -- Proceed with normal file selection
        actions.select_default(prompt_bufnr)
      end

      -- Send grep results to the quickfix list while preserving search
      -- highlighting, so ]q / [q navigation keeps the matched word highlighted.
      local function set_search_and_open_qflist(action)
        return function(prompt_bufnr)
          set_search_from_prompt(prompt_bufnr)
          action(prompt_bufnr)
          actions.open_qflist(prompt_bufnr)
        end
      end

      local send_selected_to_qflist =
        set_search_and_open_qflist(actions.send_selected_to_qflist)
      local add_selected_to_qflist =
        set_search_and_open_qflist(actions.add_selected_to_qflist)
      local add_to_qflist = set_search_and_open_qflist(actions.add_to_qflist)

      local base_ignore_patterns = {
        '.git/.*',
        '.undodir/.*',
        'nvim%-archive/.*',
        'sessions/.*',
        'package%-lock%.json',
        'Projects/dot-files-publish/dotfiles/.*',
      }
      -- Vault folders holding history, imports, or trash. Active searches skip
      -- them; the archive and Employer searches opt back in.
      local inactive_vault_dirs = { 'archive', 'sources', 'trash' }
      local inactive_vault_patterns = vim.tbl_map(function(dir)
        return '^' .. vim.pesc(dir) .. '/.*'
      end, inactive_vault_dirs)
      local default_ignore_patterns =
        vim.list_extend(vim.deepcopy(base_ignore_patterns), inactive_vault_patterns)

      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`

        defaults = {
          file_ignore_patterns = default_ignore_patterns,
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
              -- Fuzzy-narrow the already-fetched results instead of re-running
              -- the search. Requires tmux `extended-keys on` to arrive distinct
              -- from a plain <CR>; see adrs/017 in ~/.config/docs/.
              ['<C-enter>'] = 'to_fuzzy_refine',
              ['<C-q>'] = send_selected_to_qflist,
              ['<C-a>'] = add_selected_to_qflist,
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
          live_grep_args = {
            auto_quoting = true,
            mappings = {
              i = {
                ['<C-k>'] = lga_actions.quote_prompt(),
                ['<C-l>'] = lga_actions.quote_prompt { postfix = ' -F ' },
                ['<C-g>'] = lga_actions.quote_prompt { postfix = ' --glob ' },
                ['<C-t>'] = lga_actions.quote_prompt { postfix = ' -t' },
              },
            },
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      pcall(require('telescope').load_extension, 'live_grep_args')

      local function live_grep_args(opts)
        require('telescope').extensions.live_grep_args.live_grep_args(opts or {})
      end

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
      local paths = {
        obsidian = vim.fn.expand '~/Documents/ObsidianVault',
        employer_code = vim.fn.expand '~/code/employerCode',
      }
      paths.employer_notes = {
        paths.obsidian .. '/archive/work/employer/notes',
        paths.obsidian .. '/archive/work/employer/journal',
      }
      paths.archives = { paths.obsidian .. '/archive' }

      local function existing_paths(candidates)
        return vim.tbl_filter(function(path)
          return vim.uv.fs_stat(path) ~= nil
        end, candidates)
      end

      -- Directory of the current buffer's file, as a real path.
      -- `expand('%:p:h')` alone is wrong for oil buffers (it yields an
      -- `oil://...` string that fd/rg cannot cd into) and for no-name buffers.
      local function buffer_dir()
        local bufname = vim.api.nvim_buf_get_name(0)
        if vim.startswith(bufname, 'oil://') then
          return require('oil').get_current_dir()
        end
        if bufname == '' then
          return vim.fn.getcwd() -- respects lcd -> tcd -> cd
        end
        return vim.fn.fnamemodify(bufname, ':p:h')
      end

      local active_vault_globs = { '*.md', '*.txt' }
      for _, dir in ipairs(inactive_vault_dirs) do
        table.insert(active_vault_globs, '!' .. dir .. '/**')
      end

      -- Folders that package managers and tools manage. Including ignored files
      -- turns every ignore file off, so these are skipped by glob instead.
      local tool_managed = {
        '.git/',
        '.DS_Store',
        'node_modules/',
        '.venv/',
        '.uv-cache/',
        '__pycache__/',
        '.mypy_cache/',
        '.pytest_cache/',
        '.next/',
        '.turbo/',
      }

      -- builtin.find_files, plus <M-i> to rerun the same search with gitignored
      -- files included, and again to switch back.
      local function find_files(opts)
        local function open(include_ignored, default_text)
          local picker_opts = vim.tbl_extend('force', opts, {
            default_text = default_text,
            attach_mappings = function(_, map)
              map({ 'i', 'n' }, '<M-i>', function(prompt_bufnr)
                local prompt = action_state.get_current_line()
                actions.close(prompt_bufnr)
                open(not include_ignored, prompt)
              end)
              return true
            end,
          })
          if include_ignored then
            -- find_files appends its flags to this table, so build it fresh.
            picker_opts.find_command = { 'rg', '--files', '--color', 'never' }
            for _, path in ipairs(tool_managed) do
              vim.list_extend(picker_opts.find_command, { '--glob', '!' .. path })
            end
            picker_opts.no_ignore = true
            picker_opts.prompt_title = (opts.prompt_title or 'Find Files')
              .. ' (including ignored)'
          end
          builtin.find_files(picker_opts)
        end
        open(false)
      end

      -- TODO: make all these default to search with very magic mode

      -- ═══════════════════════════════════════════════════════════════════════════════
      -- GIT INTEGRATION WITH DIFFVIEW
      -- ═══════════════════════════════════════════════════════════════════════════════
      vim.keymap.set('n', '<leader>gvc', function()
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
      end, { desc = '[G]it [V]iew [C]ommits (open in diffview)' })

      vim.keymap.set('n', '<leader>gvb', function()
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
      end, { desc = '[G]it [V]iew [B]ranches (compare in diffview)' })

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
      -- vim.keymap.set('n', '<leader>TODO', builtin.help_tags, { desc = '[F]ind [H]el[P]' })
      vim.keymap.set(
        'n',
        '<leader>fd',
        builtin.diagnostics,
        { desc = '[F]ind [D]iagnostics' }
      )

      -- ═══════════════════════════════════════════════════════════════════════════════
      -- FILE SEARCHES
      -- ═══════════════════════════════════════════════════════════════════════════════
      -- TODO: <leader>fp    for find in projects/ directory
      vim.keymap.set('n', '<leader>fp', function()
        find_files {
          cwd = vim.fn.expand '~/Projects',
          prompt_title = '[F]ind files in [P]rojects',
          hidden = true,
        }
      end, { desc = '[F]ind files in [P]rojects' })

      vim.keymap.set('n', '<leader>ff', function()
        find_files { hidden = true, follow = true }
      end, { desc = '[F]ind [F]iles' })

      -- DELETE: consider deleting
      -- Duplicate of <leader>ff for faster access (2 keystrokes instead of 3)
      -- vim.keymap.set('n', '<leader>,', function()
      --   builtin.find_files { hidden = true }
      -- end, { desc = 'Find Files (fast: ,)' })

      vim.keymap.set('n', '<leader>fF', function()
        find_files {
          cwd = buffer_dir(),
          prompt_title = '[F]ind [F]iles in buffer dir',
          hidden = true,
        }
      end, { desc = '[F]ind [F]iles in buffer dir' })

      -- TODO: rename?
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
        find_files {
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

      vim.keymap.set('n', '<leader>fhe', function()
        local hermes_dir = vim.fn.expand '~/Projects/hermes'
        local hermes_docker_dir = vim.fn.expand '~/.hermes-docker'
        builtin.find_files {
          prompt_title = '[F]ind files in [H][E]rmes',
          cwd = vim.fn.expand '~',
          hidden = true,
          find_command = {
            'find',
            hermes_dir,
            hermes_docker_dir,
            '-type',
            'f',
          },
        }
      end, { desc = '[F]ind files in [H]er[M]es' })

      -- TODO: make this so it searches for shortcuts, and when i hit enter on the found result,
      -- it goes to the shortcut where the shortcut is defined, not execute the shortcut.
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })

      vim.keymap.set('n', '<leader>fcs', function()
        find_files {
          cwd = paths.employer_code,
          prompt_title = 'Find Employer code files',
          hidden = true,
        }
      end, { desc = '[F]ind [C]ode: [S]ennder' })

      -- Location-specific file searches
      vim.keymap.set('n', '<leader>fc', function()
        find_files {
          cwd = vim.fn.expand '~/.config',
          prompt_title = '[F]ind [F]iles in ~/.config',
          hidden = true,
        }
      end, { desc = '[F]ind [F]iles in ~/.config' })

      vim.keymap.set('n', '<leader>fh', function()
        find_files {
          cwd = vim.fn.expand '~/',
          hidden = true,
        }
      end, { desc = '[F]ind [F]iles in [H]ome' })

      vim.keymap.set('n', '<leader>fo', function()
        local find_command = { 'rg', '--files' }
        for _, glob in ipairs(active_vault_globs) do
          vim.list_extend(find_command, { '--glob', glob })
        end
        builtin.find_files {
          cwd = paths.obsidian,
          prompt_title = 'Find Obsidian files',
          find_command = find_command,
        }
      end, { desc = '[F]ind [O]bsidian files' })

      vim.keymap.set('n', '<leader>fai', function()
        local home = vim.fn.expand '~'
        builtin.find_files {
          prompt_title = '[F]ind [A]I [I]nstruction files (CLAUDE.md, GEMINI.md, AGENTS.md)',
          cwd = home,
          find_command = {
            'sh',
            '-c',
            string.format(
              'find "%s/Projects" "%s/projects" "%s/code" -type f \\( -iname "CLAUDE.md" -o -iname "GEMINI.md" -o -iname "AGENTS.md" \\) 2>/dev/null | sort',
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

      vim.keymap.set('n', '<leader>sp', function()
        builtin.live_grep {
          search_dirs = { vim.fn.expand '~/Projects' },
          prompt_title = '[S]earch by Grep in [P]rojects',
        }
      end, { desc = '[S]earch by Grep in [P]rojects' })

      -- Prompt is a regex; append -F after the quoted pattern for literal text
      vim.keymap.set('n', '<leader>ss', function()
        live_grep_args {
          prompt_title = '[S]earch by Grep in project',
          -- rg skips symlinks by default; follow them so symlink-only dirs are searchable.
          vimgrep_arguments = vim.list_extend(
            vim.deepcopy(require('telescope.config').values.vimgrep_arguments),
            { '--follow' }
          ),
        }
      end, { desc = '[S]earch by Grep in project' })

      -- DELETE: consider deleting
      -- Duplicate of <leader>ss for faster access (2 keystrokes instead of 3)
      -- vim.keymap.set('n', '<leader>.', function()
      --   live_grep_args {
      --     prompt_title = 'Search by Grep in project',
      --   }
      -- end, { desc = 'Search by Grep (fast: .)' })

      -- TODO: live grep in ~/.claude/plans  directory

      vim.keymap.set('n', '<leader>sS', function()
        builtin.live_grep {
          cwd = buffer_dir(),
          prompt_title = '[S]earch by Grep in buffer dir',
        }
      end, { desc = '[S]earch by Grep in buffer dir' })

      vim.keymap.set('n', '<leader>sb', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = '[S]earch by Grep in open [B]uffers',
        }
      end, { desc = '[S]earch by Grep in open [B]uffers' })

      vim.keymap.set('n', '<leader>soa', function()
        builtin.live_grep {
          cwd = paths.obsidian,
          prompt_title = 'Search active Obsidian notes',
          glob_pattern = active_vault_globs,
        }
      end, { desc = '[S]earch [O]bsidian: [A]ctive notes' })

      vim.keymap.set('n', '<leader>soA', function()
        builtin.live_grep {
          search_dirs = existing_paths(paths.archives),
          prompt_title = 'Search Obsidian archive',
          glob_pattern = { '*.md', '*.txt' },
          file_ignore_patterns = base_ignore_patterns,
        }
      end, { desc = '[S]earch [O]bsidian: [A]rchive' })

      vim.keymap.set('n', '<leader>sos', function()
        builtin.live_grep {
          search_dirs = existing_paths(paths.employer_notes),
          prompt_title = 'Search Employer Obsidian notes',
          glob_pattern = { '*.md', '*.txt' },
          file_ignore_patterns = base_ignore_patterns,
        }
      end, { desc = '[S]earch [O]bsidian: [S]ennder notes' })

      -- PK-14 vault audits: work queues for standardizing notes.
      -- Temporary: delete this block when PK-14 closes.
      local function vault_rg(...)
        local cmd = { 'rg', '--color', 'never', ... }
        for _, glob in ipairs(active_vault_globs) do
          vim.list_extend(cmd, { '--glob', glob })
        end
        return vim.list_extend(cmd, { '.' })
      end

      vim.keymap.set('n', '<leader>soc', function()
        -- Provisional shapes from dayone ADR 0005 and Things ADR 0010;
        -- replace when PK-14's vault-wide filename ADR lands.
        local convention =
          '(^|/)([0-9]{4}-[0-9]{2}-[0-9]{2}(-[0-9]{4}-[A-Za-z0-9]{8})?|[a-z0-9-]+--([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}-)?[A-Za-z0-9]{8,})[.]md$'
        local audits = {
          { 'No frontmatter', files = vault_rg('--files-without-match', '-U', '\\A---\\n') },
          { 'No type:', files = vault_rg('--files-without-match', '^type:') },
          { 'Unsorted (type: capture)', files = vault_rg('--files-with-matches', '^type: "?capture"?') },
          { 'Wikilinks', files = vault_rg('--files-with-matches', '\\[\\[') },
          {
            'Filename off convention',
            files = {
              'sh',
              '-c',
              table.concat(vim.tbl_map(vim.fn.shellescape, vault_rg '--files'), ' ')
                .. ' | grep -Ev '
                .. vim.fn.shellescape(convention),
            },
          },
          { 'Open checkboxes', grep = '^\\s*[-*+] \\[ \\]' },
        }
        local pickers = require 'telescope.pickers'
        local finders = require 'telescope.finders'
        pickers.new({}, {
          prompt_title = 'Vault audits',
          finder = finders.new_table {
            results = audits,
            entry_maker = function(audit)
              return { value = audit, display = audit[1], ordinal = audit[1] }
            end,
          },
          sorter = require('telescope.config').values.generic_sorter {},
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local audit = action_state.get_selected_entry().value
              actions.close(prompt_bufnr)
              if audit.grep then
                builtin.live_grep {
                  cwd = paths.obsidian,
                  prompt_title = audit[1],
                  default_text = audit.grep,
                  glob_pattern = active_vault_globs,
                }
              else
                builtin.find_files {
                  cwd = paths.obsidian,
                  prompt_title = audit[1],
                  find_command = audit.files,
                }
              end
            end)
            return true
          end,
        }):find()
      end, { desc = '[S]earch [O]bsidian: [C]hecks' })

      vim.keymap.set('n', '<leader>scs', function()
        builtin.live_grep {
          cwd = paths.employer_code,
          prompt_title = 'Search Employer code',
        }
      end, { desc = '[S]earch [C]ode: [S]ennder' })

      vim.keymap.set('n', '<leader>sas', function()
        builtin.live_grep {
          search_dirs = existing_paths(
            vim.list_extend({ paths.employer_code }, vim.deepcopy(paths.employer_notes))
          ),
          prompt_title = 'Search all Employer sources',
          file_ignore_patterns = base_ignore_patterns,
        }
      end, { desc = '[S]earch [A]ll sources: [S]ennder' })

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
            vim.fn.stdpath 'config', -- nvim
            vim.fn.expand '~/.config/tmux', -- tmux
            vim.fn.expand '~/.config/ghostty', -- ghostty
            vim.fn.expand '~/.ssh/config', -- ssh
            vim.fn.expand '~/.config/gh/config.yml', -- github cli
            vim.fn.expand '~/.config/.claude', -- claude code
            vim.fn.expand '~/.config/opencode', -- opencode cli
            vim.fn.expand '~/.gemini', -- gemini
            vim.fn.expand '~/.config/gemini.md', -- gemini config
            vim.fn.expand '~/.config/karabiner.edn', -- karabiner
            vim.fn.expand '~/.config/oh-my-zsh/custom', -- all custom zsh files
            vim.fn.expand '~/.zshrc', -- zsh configs
            vim.fn.expand '~/.zshenv',
            vim.fn.expand '~/.zprofile',
            vim.fn.expand '~/.bash_profile',
            vim.fn.expand '~/.gitconfig', -- git configs
            vim.fn.expand '~/.gitignore_global',
            vim.fn.expand '~/.vimrc', -- vim
          },
          prompt_title = '[S]earch by Grep in [N]eovim, [T]mux, Ghostty & config files',
        }
      end, { desc = '[S]earch by Grep in [N]eovim, [T]mux, Ghostty & config files' })

      vim.keymap.set('n', '<leader>she', function()
        builtin.live_grep {
          search_dirs = {
            vim.fn.expand '~/Projects/hermes',
            vim.fn.expand '~/.hermes-docker',
          },
          prompt_title = '[S]earch by Grep in [H][e]rmes',
        }
      end, { desc = '[S]earch by Grep in [H][E]rmes' })

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
              '--glob',
              'CLAUDE.md',
              '--glob',
              'GEMINI.md',
              '--glob',
              'AGENTS.md',
            }
          end,
        }
      end, { desc = '[S]earch content in [A]I [I]nstruction files across projects' })

      vim.keymap.set('n', '<leader>sh', function()
        builtin.live_grep {
          cwd = vim.fn.expand '~/',
          prompt_title = '[S]earch by Grep in ~/ ',
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

      vim.keymap.set('n', '<leader>fz', function()
        builtin.find_files {
          search_dirs = {
            vim.fn.expand '~/.zshrc',
            vim.fn.expand '~/.zshenv',
            vim.fn.expand '~/.zprofile',
            vim.fn.expand '~/.bash_profile',
            vim.fn.expand '~/.config/oh-my-zsh/custom/aliases.zsh',
            vim.fn.expand '~/.config/oh-my-zsh/custom/evan_robbyrussell_theme.zsh-theme',
          },
          prompt_title = '[F]ind [Z]sh/shell config files',
        }
      end, { desc = '[F]ind [Z]sh/shell config files' })

      -- -- DELETE: ??
      -- vim.keymap.set('n', '<leader>example', function()
      --   builtin.live_grep {
      --     cwd = vim.fn.expand '~/Documents/ObsidianVault',
      --     prompt_title = '[S]earch by Grep in [O]bsidian',
      --   }
      -- end, { desc = '[S]earch by Grep in [O]bsidian' })

      -- -- DELETE: ??
      -- vim.keymap.set('n', '<leader>example', function()
      --   builtin.live_grep(require('telescope.themes').get_dropdown {
      --     winblend = 10,
      --     previewer = true,
      --     -- cwd = vim.fn.expand '~/.config/nvim',
      --     prompt_title = 'Fuzzy popup search in Nvim files',
      --   })
      -- end, { desc = '[S]earch by Grep in [H]ome' })

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

      vim.keymap.set('n', '<leader>swo', function()
        builtin.grep_string { cwd = paths.obsidian, glob_pattern = active_vault_globs }
      end, { desc = '[F]ind current [W]ord in [O]bsidian' })

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

      vim.keymap.set('n', '<leader>sWo', function()
        local word = vim.fn.expand '<cWORD>'
        builtin.grep_string {
          search = word,
          cwd = paths.obsidian,
          glob_pattern = active_vault_globs,
        }
      end, { desc = 'Search grep current cWORD in [O]bsidian' })

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

      vim.keymap.set('v', '<leader>swo', function()
        local mode = vim.fn.mode()
        if mode == 'v' or mode == 'V' or mode == '' then
          vim.cmd 'normal! "sy'
          local selected_text = vim.fn.getreg 's'
          selected_text = vim.trim(selected_text:gsub('\n', ' '))
          if selected_text ~= '' then
            builtin.grep_string {
              search = selected_text,
              cwd = paths.obsidian,
              glob_pattern = active_vault_globs,
              use_regex = false,
              prompt_title = '[S]earch visual [W]ord selection in [O]bsidian',
            }
          end
        end
      end, { desc = '[S]earch visual [W]ord selection in [O]bsidian' })

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
