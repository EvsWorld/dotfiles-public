-- nvim-scrollview: Minimal scrollbar for Neovim
return {
  'dstein64/nvim-scrollview',
  init = function()
    vim.g.scrollview_on_startup = false
  end,
  opts = {
    excluded_filetypes = { 'alpha', 'dashboard', 'oil', 'lazy' },
    current_only = false, -- Only show scrollbar in current window
    base = 'right', -- Position on right side
    column = 1, -- Distance from right edge
    -- Keep the scrollbar visible, but avoid enabling every sign module at startup.
    signs_on_startup = { 'diagnostics', 'search' },
    diagnostics_severities = {
      vim.diagnostic.severity.ERROR,
      vim.diagnostic.severity.WARN,
    },
    -- Make it not cover text
    scrollview_character = '█',
    scrollview_winblend = 20,
  },
  config = function(_, opts)
    require('scrollview').setup(opts)

    vim.api.nvim_create_autocmd('VimEnter', {
      once = true,
      callback = function()
        vim.schedule(function()
          local original_cmd = vim.cmd

          local ok, err = xpcall(function()
            vim.cmd = function(command)
              if type(command) == 'string' and command:find('augroup scrollview', 1, true) then
                command =
                  command:gsub("\n%s*autocmd VimResized %* lua require%('scrollview'%).refresh_impl_async%(%)", '')
              end

              return original_cmd(command)
            end

            require('scrollview').set_state(true)
          end, debug.traceback)

          vim.cmd = original_cmd

          if not ok then
            vim.notify('nvim-scrollview failed to start: ' .. err, vim.log.levels.ERROR)
          end
        end)
      end,
    })
  end,
}
