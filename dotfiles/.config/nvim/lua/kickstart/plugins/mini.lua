return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup {
        n_lines = 500,
        custom_textobjects = {
          -- TODO: add description hints
          -- line text object
          l = function()
            local line_num = vim.fn.line '.'
            local line_content = vim.fn.getline(line_num)
            local first_non_blank = vim.fn.match(line_content, '\\S') + 1
            local last_non_blank = vim.fn.match(line_content, '\\s*$')

            if first_non_blank == 0 then
              first_non_blank = 1
            end
            if last_non_blank == -1 then
              last_non_blank = #line_content
            end

            return {
              from = { line = line_num, col = first_non_blank },
              to = { line = line_num, col = last_non_blank },
            }
          end,

          -- Add entire document text object
          d = function()
            local from = { line = 1, col = 1 }
            local to = {
              line = vim.fn.line '$',
              col = math.max(vim.fn.getline('$'):len(), 1),
            }
            return { from = from, to = to }
          end,
        },
      }

      -- Override the default line text objects after mini.ai setup
      vim.keymap.set({ 'x', 'o' }, 'il', function()
        require('mini.ai').select_textobject('i', 'l')
      end, { desc = 'Inside line (non-blank)' })

      -- DELETE: ?
      -- vim.keymap.set({ 'x', 'o' }, 'al', function()
      --   require('mini.ai').select_textobject('a', 'l')
      -- end, { desc = 'Around entire line' })

      -- TODO: turn off s substitute mcommand in normal mode?
      -- its getting triggeredby accident If I don't execute ss or sd or sr fast enough.
      -- - ssiw) - [S]urround [S]add [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup {
        mappings = {
          add = 'ss', -- Add surrounding in Normal and Visual modes  (works)
          delete = 'sd', -- Delete surrounding
          find = 'sf', -- Find surrounding (to the right)
          find_left = 'sF', -- Find surrounding (to the left)
          highlight = 'sh', -- Highlight surrounding
          replace = 'sc', -- Replace surrounding
          update_n_lines = 'sn', -- Update `n_lines`
        },
      }

      vim.keymap.set('v', 'S', 'ss', { desc = 'Surround visual selection', remap = true })

      -- NOTE:: yank some text then go to a word and do siw to replace that word with the yanked text. then go to another word and . repeat it
      -- yank a line (yy), then go to a line and do rr, or ril to replace that line with the yanked text
      -- 'r' + motion/text-object = substitute motion with register content
      -- 'rr' = substitute entire line
      -- 'r' in visual mode = substitute selection
      -- All support dot-repeat automatically
      -- 2025_08_07: using r for substiture prefix, and s works as single character replace (the old r function)
      -- Examples of usage:
      -- 1. yiw (yank word) -> riw (substitute inner word) -> . (repeat on next word)
      -- 2. yy (yank line) -> rs (substitute line) -> . (repeat on next line)
      -- 3. yy (yank line) -> ril (substitute inner line) -> . (repeat)

      require('mini.operators').setup {
        -- Each operator is disabled by default
        evaluate = { prefix = '' },
        exchange = { prefix = '' },
        multiply = { prefix = '' },
        replace = {
          prefix = 'r',
          -- Use unnamed register by default (what you yank goes here)
          reindent_linewise = true,
        },
        sort = { prefix = '' },
      }

      -- Add this inside your existing mini config function
      require('mini.hipatterns').setup {
        highlighters = {
          hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
        },
      }

      --  TODO: Map [[ and ]] to send [% and ]%
      -- vim.keymap.set({ 'n', 'v' }, '[[', function()
      --   vim.cmd 'normal! [%'
      -- end, { desc = 'Execute [%' })
      -- vim.keymap.set({ 'n', 'v' }, ']]', function()
      --   vim.cmd 'normal! ]%'
      -- end, { desc = 'Execute ]%' })
      -- TODO: o more convenient way to jump through recent files than [o and ]o
      require('mini.bracketed').setup()
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
