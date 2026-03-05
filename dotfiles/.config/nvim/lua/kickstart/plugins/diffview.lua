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
          ['<leader>gxo'] = actions.conflict_choose 'ours',
          ['<leader>gxt'] = actions.conflict_choose 'theirs',
          ['<leader>gxb'] = actions.conflict_choose 'base',
          ['<leader>gxa'] = actions.conflict_choose 'all',
          ['<leader>gxO'] = actions.conflict_choose_all 'ours',
          ['<leader>gxT'] = actions.conflict_choose_all 'theirs',
          ['<leader>gxB'] = actions.conflict_choose_all 'base',
          ['<leader>gxA'] = actions.conflict_choose_all 'all',

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
    vim.keymap.set('n', '<leader>gvd', '<cmd>DiffviewOpen<cr>', { desc = '[G]it [V]iew [D]iff' })
    vim.keymap.set('n', '<leader>gvD', '<cmd>DiffviewOpen HEAD~1<cr>', { desc = '[G]it [V]iew [D]iff vs last commit' })
    vim.keymap.set('n', '<leader>gvh', '<cmd>DiffviewFileHistory %<cr>', { desc = '[G]it [V]iew file [H]istory' })
    vim.keymap.set('n', '<leader>gvH', '<cmd>DiffviewFileHistory<cr>', { desc = '[G]it [V]iew repo [H]istory' })
    vim.keymap.set('n', '<leader>gvm', function()
      -- Check if in merge/rebase
      local git_dir = vim.fn.finddir('.git', '.;')
      if git_dir ~= '' then
        vim.cmd 'DiffviewOpen'
      else
        print 'Not in a git repository'
      end
    end, { desc = '[G]it [V]iew [M]erge conflicts' })
    vim.keymap.set('n', '<leader>gvq', '<cmd>DiffviewClose<cr>', { desc = '[G]it [V]iew [Q]uit' })

    -- Visual mode: compare selected commits
    vim.keymap.set('v', '<leader>gvh', ':DiffviewFileHistory<cr>', { desc = '[G]it [V]iew file [H]istory (visual range)' })
  end,
}
