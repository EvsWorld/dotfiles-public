return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
        key = function()
          return vim.uv.cwd() or vim.fn.getcwd()
        end,
      },
      default = {
        display = function(list_item)
          local path = list_item.value
          -- Replace home directory with ~
          local home = vim.fn.expand '~'
          if path:sub(1, #home) == home then
            path = '~' .. path:sub(#home + 1)
          end
          return path
        end,
      },
    }

    -- Prevent accidental character edits in Harpoon menu, but allow line operations (dd, p, etc)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'harpoon',
      callback = function()
        -- Disable soft wrap in Harpoon menu
        vim.opt_local.wrap = false
        vim.opt_local.linebreak = false
        vim.opt_local.breakindent = false
        -- harpoon opens the menu with `style = "minimal"`, which forces
        -- cursorline off. Restore it so the selected entry reads as a full
        -- row, matching how the focused split marks the current line.
        vim.opt_local.cursorline = true

        local opts = { buffer = true, silent = true }
        vim.keymap.set({ 'n', 'v' }, 'x', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 'X', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 's', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 'c', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 'C', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 'i', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 'I', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 'a', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 'A', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 'o', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 'O', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 'r', '<Nop>', opts)
        vim.keymap.set({ 'n', 'v' }, 'R', '<Nop>', opts)

        -- 'd' should only ever resolve as 'dd' (remove entry). Any other
        -- motion after 'd' (dw, d$, dl, ...) would edit the path text in
        -- place, which harpoon syncs back as a rename. Swallow those instead.
        vim.keymap.set('n', 'd', function()
          local ok, char = pcall(vim.fn.getchar)
          if ok and vim.fn.nr2char(char) == 'd' then
            return 'dd'
          end
          return ''
        end, { buffer = true, silent = true, expr = true })
      end,
    })

    vim.keymap.set('n', '<leader>d', function()
      harpoon:list():remove()
      harpoon:list():prepend()
    end, {
      desc = 'Harpoon: Add to top of list. (Or if its already in the list then move it to top.',
    })

    vim.keymap.set('n', '<leader>D', function()
      harpoon:list():remove()
      harpoon:list():add()
    end, { desc = 'Harpoon: Add to bottom list' })

    vim.keymap.set('n', '<leader><leader>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list(), {
        border = 'rounded',
        title_pos = 'center',
        ui_width_ratio = 0.9,
      })
    end, { desc = 'harpoon: toggle quick pick menu' })

    vim.keymap.set('n', '<leader>1', function()
      harpoon:list():select(1)
    end, { desc = 'harpoon: select 1' })
    vim.keymap.set('n', '<leader>2', function()
      harpoon:list():select(2)
    end, { desc = 'harpoon: select 2' })
    vim.keymap.set('n', '<leader>3', function()
      harpoon:list():select(3)
    end, { desc = 'harpoon: select 3' })
    vim.keymap.set('n', '<leader>4', function()
      harpoon:list():select(4)
    end, { desc = 'harpoon: select 4' })
    vim.keymap.set('n', '<leader>5', function()
      harpoon:list():select(5)
    end, { desc = 'harpoon: select 5' })
    vim.keymap.set('n', '<leader>6', function()
      harpoon:list():select(6)
    end, { desc = 'harpoon: select 6' })
    vim.keymap.set('n', '<leader>7', function()
      harpoon:list():select(7)
    end, { desc = 'harpoon: select 7' })
    vim.keymap.set('n', '<leader>8', function()
      harpoon:list():select(8)
    end, { desc = 'harpoon: select 8' })

    vim.keymap.set('n', '<leader>j', function()
      harpoon:list():select(1)
    end, { desc = 'harpoon: select 1' })
    vim.keymap.set('n', '<leader>k', function()
      harpoon:list():select(2)
    end, { desc = 'harpoon: select 2' })
    vim.keymap.set('n', '<leader>l', function()
      harpoon:list():select(3)
    end, { desc = 'harpoon: select 3' })
    vim.keymap.set('n', '<leader>:', function()
      harpoon:list():select(4)
    end, { desc = 'harpoon: select 4' })
    vim.keymap.set('n', "<leader>'", function()
      harpoon:list():select(5)
    end, { desc = 'harpoon: select 5' })

    -- TODO: make these insert not replace
    vim.keymap.set('n', '<leader>\\1', function()
      harpoon:list():replace_at(1)
    end, { desc = 'harpoon: replace at 1' })
    vim.keymap.set('n', '<leader>\\2', function()
      harpoon:list():replace_at(2)
    end, { desc = 'Harpoon replace at 2' })
    vim.keymap.set('n', '<leader>\\3', function()
      harpoon:list():replace_at(3)
    end, { desc = 'Harpoon: replace at 3' })
    vim.keymap.set('n', '<leader>\\4', function()
      harpoon:list():replace_at(4)
    end, { desc = 'Harpoon replace at 4' })
    vim.keymap.set('n', '<leader>\\5', function()
      harpoon:list():replace_at(5)
    end, { desc = 'Harpoon replace at 5' })
    vim.keymap.set('n', '<leader>\\6', function()
      harpoon:list():replace_at(6)
    end, { desc = 'Harpoon replace at 6' })
    vim.keymap.set('n', '<leader>\\7', function()
      harpoon:list():replace_at(7)
    end, { desc = 'Harpoon replace at 7' })
    vim.keymap.set('n', '<leader>\\8', function()
      harpoon:list():replace_at(8)
    end, { desc = 'Harpoon replace at 8' })
    vim.keymap.set('n', '<leader>\\9', function()
      harpoon:list():replace_at(9)
    end, { desc = 'Harpoon replace at 9' })
    vim.keymap.set('n', '<leader>\\0', function()
      harpoon:list():replace_at(10)
    end, { desc = 'Harpoon replace at 0' })

    -- TODO: make this work also in the harpoon quick pick list
    vim.keymap.set('n', '<leader>x', function()
      harpoon:list():remove()
    end, { desc = 'Harpoon: remove current file from list' })

    -- Remove specific files by index (works in quick view)
    -- TODO: assign keys
    -- vim.keymap.set('n', '<leader>TODO1', function()
    --   harpoon:list():remove_at(1)
    -- end, { desc = 'Harpoon: remove file at index 1' })
    -- vim.keymap.set('n', '<leader>TODO2', function()
    --   harpoon:list():remove_at(2)
    -- end, { desc = 'Harpoon: remove file at index 2' })
    -- vim.keymap.set('n', '<leader>TODO3', function()
    --   harpoon:list():remove_at(3)
    -- end, { desc = 'Harpoon: remove file at index 3' })
    -- vim.keymap.set('n', '<leader>TODO4', function()
    --   harpoon:list():remove_at(4)
    -- end, { desc = 'Harpoon: remove file at index 4' })
  end,
}
