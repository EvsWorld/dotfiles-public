return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose', 'DiffviewToggleFiles', 'DiffviewFocusFiles' },
  config = function()
    local actions = require('diffview.actions')

    require('diffview').setup {
      -- Enhanced diff view for merge conflicts (3-way diff)
      diff_binaries = false,
      enhanced_diff_hl = true,
      use_icons = true,

      view = {
        -- Configure the layout for merge conflicts
        merge_tool = {
          layout = 'diff3_mixed', -- Shows: OURS | BASE | THEIRS
          disable_diagnostics = true,
        },

        file_panel = {
          win_config = {
            width = 35,
          },
        },
      },

      file_panel = {
        listing_style = 'list',
        win_config = {
          position = 'left',
          width = 35,
        },
      },

      keymaps = {
        view = {
          -- Navigation between conflicts
          ['[x'] = actions.prev_conflict,
          [']x'] = actions.next_conflict,

          -- Conflict resolution
          ['<leader>6o'] = actions.conflict_choose 'ours',
          ['<leader>6t'] = actions.conflict_choose 'theirs',
          ['<leader>6b'] = actions.conflict_choose 'base',
          ['<leader>6a'] = actions.conflict_choose 'all',
          ['<leader>6O'] = actions.conflict_choose_all 'ours',
          ['<leader>6T'] = actions.conflict_choose_all 'theirs',
          ['<leader>6B'] = actions.conflict_choose_all 'base',
          ['<leader>6A'] = actions.conflict_choose_all 'all',

          -- Navigation
          ['<tab>'] = actions.select_next_entry,
          ['<s-tab>'] = actions.select_prev_entry,
          ['<leader>e'] = actions.focus_files,
          ['<leader>b'] = actions.toggle_files,
        },

        file_panel = {
          ['j'] = actions.next_entry,
          ['k'] = actions.prev_entry,
          ['<cr>'] = actions.select_entry,
          ['o'] = actions.select_entry,
          ['l'] = actions.select_entry,
          ['<2-LeftMouse>'] = actions.select_entry,
          ['-'] = actions.toggle_stage_entry,
          ['S'] = actions.stage_all,
          ['U'] = actions.unstage_all,
          ['R'] = actions.refresh_files,
          ['<tab>'] = actions.select_next_entry,
          ['<s-tab>'] = actions.select_prev_entry,
          ['gf'] = actions.goto_file,
          ['i'] = actions.listing_style,
          ['<leader>e'] = actions.focus_files,
          ['<leader>b'] = actions.toggle_files,
        },

        file_history_panel = {
          ['g!'] = actions.options,
          ['<C-d>'] = actions.open_in_diffview,
          ['y'] = actions.copy_hash,
          ['L'] = actions.open_commit_log,
          ['zR'] = actions.open_all_folds,
          ['zM'] = actions.close_all_folds,
          ['j'] = actions.next_entry,
          ['k'] = actions.prev_entry,
          ['<cr>'] = actions.select_entry,
          ['o'] = actions.select_entry,
          ['<2-LeftMouse>'] = actions.select_entry,
          ['<tab>'] = actions.select_next_entry,
          ['<s-tab>'] = actions.select_prev_entry,
          ['gf'] = actions.goto_file,
          ['<leader>e'] = actions.focus_files,
          ['<leader>b'] = actions.toggle_files,
        },
      },
    }

    -- Global keybindings for diffview
    vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<cr>', { desc = '[G]it [D]iff view' })
    vim.keymap.set('n', '<leader>gD', '<cmd>DiffviewOpen HEAD~1<cr>', { desc = '[G]it [D]iff vs last commit' })
    vim.keymap.set('n', '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', { desc = '[G]it file [H]istory' })
    vim.keymap.set('n', '<leader>gH', '<cmd>DiffviewFileHistory<cr>', { desc = '[G]it repo [H]istory' })
    vim.keymap.set('n', '<leader>gm', function()
      -- Check if in merge/rebase
      local git_dir = vim.fn.finddir('.git', '.;')
      if git_dir ~= '' then
        vim.cmd 'DiffviewOpen'
      else
        print 'Not in a git repository'
      end
    end, { desc = '[G]it [M]erge conflicts' })
    vim.keymap.set('n', '<leader>gq', '<cmd>DiffviewClose<cr>', { desc = '[G]it diff [Q]uit' })

    -- Visual mode: compare selected commits
    vim.keymap.set('v', '<leader>gh', ':DiffviewFileHistory<cr>', { desc = '[G]it file [H]istory (visual range)' })
  end,
}
