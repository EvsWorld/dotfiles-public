-- Word highlighting plugin similar to VS Code highlight-words extension
-- https://github.com/Mr-LLLLL/interestingwords.nvim

return {
  'Mr-LLLLL/interestingwords.nvim',
  config = function()
    require('interestingwords').setup {
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
      search_key = '<leader>m',
      cancel_search_key = '<leader>M',
      -- NOTE:  will act as a toggle, so you can use it to highlight and remove the highlight
      -- from a given word. Note that you can highlight different words at the same time.
      color_key = '<leader>c',
      cancel_color_key = '<leader>C',
      select_mode = 'loop',
    }
  end,
}
