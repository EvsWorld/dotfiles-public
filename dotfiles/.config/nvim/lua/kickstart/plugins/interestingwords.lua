-- Word highlighting plugin similar to VS Code highlight-words extension
-- https://github.com/Mr-LLLLL/interestingwords.nvim

return {
  'Mr-LLLLL/interestingwords.nvim',
  config = function()
    local iw = require 'interestingwords'
    iw.setup {
      colors = {
        '#00FF00', -- neon green
        '#FF6B6B', -- coral red
        '#4ECDC4', -- bright teal
        '#FFA726', -- bright orange
        '#AB47BC', -- bright purple
        '#FFEB3B', -- bright yellow
        '#FF5722', -- bright red-orange
        '#45B7D1', -- sky blue
        '#E91E63', -- hot pink
        '#8BC34A', -- light green
        '#FF9800', -- deep orange
        '#9C27B0', -- deep purple
        '#F44336', -- deep red
        '#2196F3', -- blue
        '#FFCC02', -- gold
        '#795548', -- brown
        '#607D8B', -- blue grey
        '#1DE9B6', -- teal accent
        '#FF1744', -- pink accent
        '#00E676', -- green accent
        '#2979FF', -- blue accent
        '#D500F9', -- purple accent
        '#FF6D00', -- orange accent
      },
      search_count = true,
      navigation = true,
      -- scroll_offset = 5, -- lines to keep visible when jumping
      -- scroll_center = false,
      -- NOTE:  will act as a toggle, so you can use it to search and highlight or remove search
      -- from a given word. Note that you can search a words at the same time
      -- TODO:  unmap this? it seems to be the same as my * search
      search_key = '<leader><F9>',
      cancel_search_key = '<leader><F10>',
      -- NOTE:  will act as a toggle, so you can use it to highlight and remove the highlight
      -- from a given word. Note that you can highlight different words at the same time.
      color_key = '<leader>c',
      cancel_color_key = '<leader>C',
      select_mode = 'loop',
    }

    -- Persistence logic
    local function get_tmux_session_name()
      local tmux_session =
        vim.fn.system("tmux display-message -p '#S' 2>/dev/null"):gsub('\n', '')
      if vim.v.shell_error == 0 and tmux_session ~= '' then
        return tmux_session
      end
      return nil
    end

    local function get_words_file()
      local session_dir = vim.fn.expand '~/.config/nvim/sessions/'
      local tmux_session = get_tmux_session_name()
      if tmux_session then
        return session_dir .. tmux_session .. '_words.json'
      else
        return session_dir .. 'default_words.json'
      end
    end

    local function save_interesting_words()
      local words_file = get_words_file()
      if iw.words and next(iw.words) then
        local data = {
          words = iw.words,
          next = iw.next,
        }
        local json = vim.fn.json_encode(data)
        local file = io.open(words_file, 'w')
        if file then
          file:write(json)
          file:close()
        end
      else
        vim.fn.delete(words_file)
      end
    end

    local function restore_interesting_words()
      local words_file = get_words_file()
      if vim.fn.filereadable(words_file) == 1 then
        local file = io.open(words_file, 'r')
        if file then
          local json = file:read '*all'
          file:close()
          local ok, data = pcall(vim.fn.json_decode, json)
          if ok and data and data.words then
            iw.words = data.words
            iw.next = data.next or 1
            -- Mark colors as taken
            for _, word_data in pairs(iw.words) do
              if iw.colors[word_data.color] then
                iw.colors[word_data.color] = 0
              end
            end
            -- Apply highlights to current window manually since recolorAllWords is local to the plugin
            for pattern, word_data in pairs(iw.words) do
              pcall(
                vim.fn.matchadd,
                word_data.color,
                pattern,
                1,
                word_data.mid,
                { window = 0 }
              )
            end
          end
        end
      end
    end

    -- Auto-save words on exit
    vim.api.nvim_create_autocmd('VimLeavePre', {
      group = vim.api.nvim_create_augroup('InterestingWordsPersist', { clear = true }),
      callback = save_interesting_words,
    })

    -- Auto-load words on startup
    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        vim.defer_fn(restore_interesting_words, 200) -- Wait for session and lazy plugins
      end,
    })
  end,
}
