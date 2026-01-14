-- NOTE: Plugins can also be configured to run Lua code when they are loaded.
--
-- This is often very useful to both group configuration, as well as handle
-- lazy loading plugins that don't need to be loaded immediately at startup.
--
-- For example, in the following configuration, we use:
--  event = 'VimEnter'
--
-- which loads which-key before all the UI elements are loaded. Events can be
-- normal autocommands events (`:help autocmd-events`).
--
-- Then, because we use the `opts` key (recommended), the configuration runs
-- after the plugin has been loaded as `require(MODULE).setup(opts)`.

return {
  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      -- this setting is independent of vim.o.timeoutlen
      delay = 800,
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- TODO: implement some way of documenting all mappings (tmux too)

      -- Document existing key chains
      spec = {
        { 'g', group = '[G] Group' },
        { 'gr', group = '[G]r Group' },
        { 'gl', group = '[G]o to [L]ast Position Group' },
        { '<leader>f', group = '[F]ind [F]ile Group' },
        { '<leader>f', group = '[F]ind Group' },
        { '<leader>t', group = '[T]oggle Group' },
        { '<leader>s', group = '[S]earch grep Group' },
        { '<leader>w', group = '[W]indow Group' },
        { '<leader>ws', group = '[W]indow [S]wap Group' },
        { '<leader>ks', group = '[k](Utility) [S]ource Group' },
        { '<leader>kk', group = '[K][K]arabiner meta search Group' },
        { '<leader>kq', group = '[K][Q]uit Group' },
        { '<leader>kt', group = '[K][T]ext Width, Wrapping Group' },
        { '<leader>o', group = '[O]bsidian Group' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { '<leader>g', group = '[G]it Advanced', mode = { 'n', 'v' } },
        { '<leader>6', group = '[C]onflict Resolution' },
        { '<leader>c', group = '[C]olor ' },
        { '<leader>s', group = '[S]earch Group' },
        { '<leader>sl', group = '[S]earch [L] Group' },
        { '<leader>sw', group = '[S]earch [w]ord Group' },
        { '<leader>sW', group = '[S]earch [W]ORD Group' },
        { '<leader>j', group = 'Write and format ( Not a Group )' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
