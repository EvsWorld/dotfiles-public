-- [[ Setting options ]]
-- See `:help vim.o`
--  For more options, you can see `:help option-list`

-- Auto-detect light/dark based on system (matches Ghostty)
if vim.fn.system('defaults read -g AppleInterfaceStyle 2>/dev/null'):match 'Dark' then
  vim.o.background = 'dark'
else
  vim.o.background = 'light'
end

-- TODO: whats this do?
-- vim.o.viewoptions = 'cursor,folds,slash,unix'

-- TODO: is this going to pick up my .zshrc file and aliases.zsh?
vim.opt.shell = '/bin/zsh'
vim.opt.shellcmdflag = '-c'

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- TODO: Prevent backspacing past command mode (:) start

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- Set highlight on search
vim.o.hlsearch = false
vim.o.incsearch = true

-- Make line numbers default
vim.o.number = true
vim.o.relativenumber = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv 'HOME' .. '/.config/.vim/.undodir'
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 50

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-options-guide`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 4

-- Minimal number of screen columns to keep to the left and right of the cursor.
vim.o.sidescrolloff = 3

-- Disable line wrapping
vim.o.wrap = false

vim.o.colorcolumn = '90'

-- TODO: is this needed?
vim.o.textwidth = 90
vim.o.foldmethod = 'manual'

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- from https://fredrikaverpil.github.io/blog/2024/12/04/ghostty-on-macos/
-- tab title
if vim.fn.getenv 'TERM_PROGRAM' == 'ghostty' then
  vim.opt.title = true
  vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"
end

-- AutoCommands
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local no_auto_comments = augroup('NoAutoComments', { clear = true })
autocmd('FileType', {
  group = no_auto_comments,
  pattern = '*',
  command = 'setlocal formatoptions=qw formatoptions-=t formatoptions-=c formatoptions-=r formatoptions-=o',
})

-- Resize splits when the window is resized
-- local vim_resized_group = augroup('VimResized', { clear = true })
autocmd('VimResized', {
  group = vim_resized_group,
  pattern = '*',
  command = 'wincmd =',
})

-- Only allow soft wrap for markdown and text files
local wrap_allowed_group = augroup('WrapAllowedFileTypes', { clear = true })
autocmd({ 'FileType', 'BufEnter', 'BufWinEnter' }, {
  group = wrap_allowed_group,
  pattern = '*',
  callback = function()
    local ft = vim.bo.filetype
    -- Only markdown and text files are allowed to wrap
    if ft == 'markdown' or ft == 'text' then
      -- Don't enable wrap by default, just allow it to be toggled
      -- Keep it off by default
      vim.opt_local.wrap = false
    else
      -- All other filetypes: enforce no wrap
      vim.opt_local.wrap = false
      vim.opt_local.linebreak = false
      vim.opt_local.breakindent = false
    end
  end,
})

-- Tmux-aware session management
local function get_tmux_session_name()
  local tmux_session =
    vim.fn.system("tmux display-message -p '#S' 2>/dev/null"):gsub('\n', '')
  if vim.v.shell_error == 0 and tmux_session ~= '' then
    return tmux_session
  end
  return nil
end

local function get_session_file()
  local session_dir = vim.fn.expand '~/.config/nvim/sessions/'
  vim.fn.mkdir(session_dir, 'p')
  local tmux_session = get_tmux_session_name()
  if tmux_session then
    return session_dir .. tmux_session .. '.vim'
  else
    return session_dir .. 'default.vim'
  end
end

local function get_qf_file()
  local session_dir = vim.fn.expand '~/.config/nvim/sessions/'
  local tmux_session = get_tmux_session_name()
  if tmux_session then
    return session_dir .. tmux_session .. '_qf.json'
  else
    return session_dir .. 'default_qf.json'
  end
end

local function save_quickfix_list()
  local qf_file = get_qf_file()
  local qflist = vim.fn.getqflist()
  if #qflist > 0 then
    local json = vim.fn.json_encode(qflist)
    local file = io.open(qf_file, 'w')
    if file then
      file:write(json)
      file:close()
    end
  else
    -- Remove qf file if list is empty
    vim.fn.delete(qf_file)
  end
end

local function restore_quickfix_list()
  local qf_file = get_qf_file()
  if vim.fn.filereadable(qf_file) == 1 then
    local file = io.open(qf_file, 'r')
    if file then
      local json = file:read '*all'
      file:close()
      local ok, qflist = pcall(vim.fn.json_decode, json)
      if ok and qflist and #qflist > 0 then
        vim.fn.setqflist(qflist)
      end
    end
  end
end

-- Auto-save session on exit
vim.api.nvim_create_autocmd('VimLeavePre', {
  desc = 'Save session automatically (tmux-aware)',
  group = vim.api.nvim_create_augroup('SaveSession', { clear = true }),
  callback = function()
    local session_file = get_session_file()
    vim.cmd('mksession! ' .. session_file)
    save_quickfix_list()
    local tmux_session = get_tmux_session_name()
    if tmux_session then
      print('Session saved for tmux session: ' .. tmux_session)
    end
  end,
})

-- Auto-load session on startup
vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Auto-load session (tmux-aware)',
  callback = function()
    if vim.fn.argc() == 0 then
      local session_file = get_session_file()
      if vim.fn.filereadable(session_file) == 1 then
        -- Defer session loading until after lazy.nvim is ready
        vim.defer_fn(function()
          -- TODO:  lua/options.lua|196 col 33-40 warning| Cannot assign
          -- `table` to parameter `fun(...any):...unknown`. - `table`
          -- cannot match `fun(...any):...unknown` - Type `table`
          --   cannot match `fun(...any):...unknown`
          local ok, err = pcall(vim.cmd, 'source ' .. session_file)
          if ok then
            local tmux_session = get_tmux_session_name()
            if tmux_session then
              print('Session loaded for tmux session: ' .. tmux_session)
            end
          else
            print('Failed to load session: ' .. err)
            -- Clean up the problematic session file
            vim.fn.delete(session_file)
            print('Deleted corrupted session file: ' .. session_file)
          end
        end, 100) -- Wait 100ms for lazy.nvim to finish loading
      end
    end
  end,
})

-- Folding settings. To work with treesitter
-- vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
-- vim.o.foldlevelstart = 99 -- Start with all folds open

-- vim: ts=2 sts=2 sw=2 et
