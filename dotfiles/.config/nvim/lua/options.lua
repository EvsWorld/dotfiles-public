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

-- Blink the cursor only in insert mode
vim.opt.guicursor = 'n-v-c-sm:block,i:ver25-blinkwait800-blinkon700-blinkoff700,ci-ve:ver25,r-cr-o:hor20,t:block-TermCursor'

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
vim.o.updatetime = 250 -- was 50; 50ms caused LSP document_highlight to fire 20x/sec on CursorHold

-- time to wait for a mapped sequence to complete. milliseconds
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

-- TODO: fix. as of 2026_03_18_T13_33 its not working
-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 4

-- Minimal number of screen columns to keep to the left and right of the cursor.
vim.o.sidescrolloff = 3

-- Disable line wrapping
vim.o.wrap = false

-- Visual guide for line length (matches black default)
vim.o.colorcolumn = '88' -- Show vertical line at column 88
-- vim.o.textwidth = 88    -- Don't auto-wrap; let black handle formatting
vim.o.foldmethod = 'manual'

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true
vim.o.autoread = true

-- from https://fredrikaverpil.github.io/blog/2024/12/04/ghostty-on-macos/
-- tab title
if vim.fn.getenv 'TERM_PROGRAM' == 'ghostty' then
  vim.opt.title = true
  vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"
end

-- AutoCommands

-- TODO: for makefiles only keep actual tabs instead of converting to spaces
-- autocmd FileType make setlocal noexpandtab

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local vim_resized_group = augroup('VimResized', { clear = true })
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

-- Enable soft wrap by default for markdown-like text buffers, disable for all others
local wrap_control_group = augroup('WrapControl', { clear = true })
autocmd({ 'FileType', 'BufEnter', 'BufWinEnter' }, {
  group = wrap_control_group,
  pattern = '*',
  callback = function()
    local ft = vim.bo.filetype
    -- Enable wrap by default for markdown, prose, and Avante response buffers
    if ft == 'markdown' or ft == 'text' or ft == 'Avante' then
      vim.opt_local.wrap = true
      vim.opt_local.linebreak = true
      vim.opt_local.breakindent = true
    else
      -- All other filetypes: enforce no wrap
      vim.opt_local.wrap = false
      vim.opt_local.linebreak = false
      vim.opt_local.breakindent = false
    end
  end,
})

-- Session persistence is handled by auto-session (lua/custom/plugins/sessions.lua),
-- keyed by cwd + git branch. LSP memory hygiene is handled by garbage-day.nvim.
-- Trial: omit curdir so restored sessions use the directory Neovim was
-- launched from. Revisit if restoring sessions from other directories
-- becomes important; adding curdir back would restore saved cwd state.
vim.o.sessionoptions = 'blank,buffers,folds,help,tabpages,winsize,winpos,terminal,localoptions'

-- Folding settings. To work with treesitter
-- vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
-- vim.o.foldlevelstart = 99 -- Start with all folds open

-- vim: ts=2 sts=2 sw=2 et
