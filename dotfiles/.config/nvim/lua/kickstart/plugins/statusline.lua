return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      -- Width tiers. One source of truth for "is this window wide enough?",
      -- shared by every component's `cond` and by the path budget below.
      local WIDE, MEDIUM = 100, 80

      local function wider_than(n)
        return function()
          return vim.fn.winwidth(0) > n
        end
      end

      -- Columns reserved for every component other than the path. Mirrors the
      -- tiers above: crossing a threshold switches MORE components on, so the
      -- path's budget does not simply grow with window width.
      local function reserved_columns()
        local w = vim.fn.winwidth(0)
        if w > WIDE then
          return 76 -- + filetype, interestingwords, progress
        elseif w > MEDIUM then
          return 46 -- + branch
        end
        return 24 -- mode, harpoon, location only
      end

      -- Stage 2 of shortening, applied after lualine has already abbreviated
      -- intermediate directories as far as it can. Drops whole leading
      -- segments; truncating from the LEFT keeps the filename and its status
      -- symbols (' ● UNSAVED') intact, since both live at the tail.
      --
      -- The filename itself is never truncated: if the last segment alone
      -- overflows, it overflows. An unreadable filename is worse than a
      -- clipped statusline.
      local function truncate_left(str, reserved)
        local budget = math.max(vim.fn.winwidth(0) - reserved(), 12)
        if #str <= budget then
          return str
        end

        local segments = vim.split(str, '/')
        while #segments > 1 and #table.concat(segments, '/') + 2 > budget do
          table.remove(segments, 1)
        end

        return '…/' .. table.concat(segments, '/')
      end

      -- lualine's built-in `location` renders line:col only. The total line
      -- count is appended here rather than relying on `progress`, which is
      -- gated behind wider_than(WIDE) and so never renders in a split.
      local function location()
        return string.format(
          '%3d:%-2d/%d',
          vim.fn.line '.',
          vim.fn.charcol '.',
          vim.fn.line '$'
        )
      end

      local filename = {
        'filename',
        path = 3, -- absolute path, with ~ for $HOME
        -- Stage 1: lualine's own shorten_path abbreviates intermediate dirs
        -- left-to-right and stops as soon as the path fits this budget.
        shorting_target = reserved_columns,
        fmt = function(str)
          return truncate_left(str, reserved_columns)
        end,
        symbols = {
          modified = ' ● UNSAVED',
          readonly = ' 󰌾',
          unnamed = '[No Name]',
          newfile = ' [New]',
        },
        color = function()
          if vim.bo.modified then
            return { fg = '#1e1e2e', bg = '#f38ba8', gui = 'bold' }
          end
        end,
      }

      -- Inactive sections only render the filename and location. Reuse the
      -- same component with the smaller reserve so inactive splits can show
      -- more of the path instead of budgeting for active-window components.
      local inactive_filename = vim.deepcopy(filename)
      local function inactive_reserved_columns()
        return 12 -- location plus a small amount of statusline padding
      end
      inactive_filename.shorting_target = inactive_reserved_columns
      inactive_filename.fmt = function(str)
        return truncate_left(str, inactive_reserved_columns)
      end

      require('lualine').setup {
        options = {
          theme = 'auto',
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          globalstatus = false, -- Single statusline for all windows
          -- Padding buffers are decoration; a filename and location rendered
          -- inside them would be visual noise.
          disabled_filetypes = { statusline = { 'no-neck-pain' } },
        },
        sections = {
          lualine_a = {
            {
              'mode',
              fmt = function(str)
                return str:sub(1, 1)
              end,
              -- color = { bg = '#f38ba8', fg = '#1e1e2e', gui = 'bold' },
              -- ^ Override to make mode box always red (active-window focus indicator).
              -- Removed: lualine's catppuccin theme already colors by mode (blue=normal,
              -- green=insert, orange=visual), and the mode box only appears in the active
              -- window (inactive_sections has no lualine_a), so it still serves as a
              -- focus indicator without forcing a single color for all modes.
            },
          },
          lualine_b = {
            { 'branch', cond = wider_than(MEDIUM) },
            'diff',
            'diagnostics',
          },
          lualine_c = {
            filename,
            { 'harpoon2', icon = '♆', indicators = { 'h', 'j', 'k', 'l' } },
          },
          lualine_x = {
            -- encoding and fileformat removed: they read utf-8/unix almost
            -- always, so they cost ~12 columns the path can use instead.
            { 'filetype', cond = wider_than(WIDE) },
            {
              require('interestingwords').lualine_get,
              cond = function()
                return require('interestingwords').lualine_has()
                  and vim.fn.winwidth(0) > WIDE
              end,
              color = { fg = '#ff9e64' },
            },
          },
          lualine_y = {
            { 'progress', cond = wider_than(WIDE) },
          },
          -- lualine_somewhere = {
          --   {
          --     -- TODO: make this only show word count only for markdown files
          --     function()
          --       return vim.fn.wordcount().words
          --     end,
          --   },
          -- },
          lualine_z = { location },
        },
        inactive_sections = {
          lualine_c = { inactive_filename },
          lualine_x = { location },
        },
      }
    end,
  },
}
