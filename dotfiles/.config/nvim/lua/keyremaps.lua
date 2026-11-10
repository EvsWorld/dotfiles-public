-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- vim.keymap.set('x', '<leader>ktl', '<cmd>lua print(vim.fn.wordcount().visual_words)<CR>')

-- Wrap toggles removed 2026-09-04. Markdown always soft wraps via the
-- WrapControl augroup in lua/options.lua, and long lines on a wide pane are
-- now handled by centering (<leader>\tt, kickstart/plugins/no-neck-pain.lua)
-- rather than by reshaping the file.
-- See docs/2026-09-04-centered-markdown-reading-measure.md

local function enable_search_highlight()
  vim.o.hlsearch = true
end

local function clear_search_highlight()
  -- `:nohlsearch` clears the active overlay, and resetting the option keeps the
  -- config in its default "off until a search starts" state.
  vim.cmd 'nohlsearch'
  vim.o.hlsearch = false
end

-- Expose the helper so Telescope and any future search UIs can reuse the same
-- transient highlight behavior instead of each plugin managing `hlsearch`.
_G.EnableSearchHighlight = enable_search_highlight

local transient_search_group =
  vim.api.nvim_create_augroup('TransientSearchHighlight', { clear = true })
vim.api.nvim_create_autocmd('CmdlineEnter', {
  group = transient_search_group,
  pattern = { '/', '?' },
  -- Native `/` and `?` keep their default UI; this only flips highlight on when
  -- you enter the search command-line so matches stay visible for n/N cycling.
  callback = enable_search_highlight,
})

local function goToLineBeginning()
  if vim.v.count > 0 then
    vim.cmd('normal! ' .. vim.v.count .. 'G')
  else
    vim.cmd 'normal! 0'
  end
end

-- Optional future variant: clear on InsertEnter if you want search state to end
-- as soon as you start editing instead of waiting for a manual dismiss key.
vim.keymap.set('n', '<BS>', clear_search_highlight, { desc = 'Clear search highlight' })

vim.keymap.set('n', '<leader>n', '<cmd>update<cr>', { desc = 'Write buffer' })

--  See `:help wincmd` for a list of all window commands

-- Window splitting
-- Note: this is related to smart-splits which loads last and will override any duplicates
-- First line.   Time: 2025_11_19_T15_19. Lorem ipsum dolor sit amet. -- First line.   Time: 2025_11_19_T15_19. Lorem ipsum dolor sit amet.

-- [[ Basic Autocommands ]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Movement mappings
vim.keymap.set('n', 'n', 'nzv', { desc = 'Go to next match' })
vim.keymap.set('n', 'N', 'Nzv', { desc = 'Go to previous match' })

-- Navigate by display lines so movement behaves consistently when text wraps.
vim.keymap.set({ 'n', 'x' }, 'j', 'gj', { desc = 'Move down by display line' })
vim.keymap.set({ 'n', 'x' }, 'k', 'gk', { desc = 'Move up by display line' })
vim.keymap.set({ 'n', 'x' }, 'J', '6gj', { desc = 'Move down 6 display lines' })
vim.keymap.set({ 'n', 'x' }, 'K', '6gk', { desc = 'Move up 6 display lines' })
vim.keymap.set('n', 'gj', 'mzJ`z', { desc = 'Join line below to current line' })

-- Go to line number (e.g., 42- goes to line 42), or beginning of line
vim.keymap.set(
  'n',
  '-',
  goToLineBeginning,
  { desc = 'Go to line (with count) or beginning of current line' }
)
vim.keymap.set(
  'n',
  '_',
  goToLineBeginning,
  { desc = 'Go to line (with count) or beginning of current line' }
)

-- Good bc doesnt clutter up the jumplist
-- Scroll half as much as default (1/4 page instead of 1/2)
vim.keymap.set('n', '<C-d>', function()
  local scroll_amount = math.floor(vim.fn.winheight(0) / 5)
  vim.cmd('normal! ' .. scroll_amount .. 'gjzz')
end, { desc = 'Move down 1/5 window by display lines and center cursor' })

vim.keymap.set('n', '<C-u>', function()
  local scroll_amount = math.floor(vim.fn.winheight(0) / 5)
  vim.cmd('normal! ' .. scroll_amount .. 'gkzz')
end, { desc = 'Move up 1/5 window by display lines and center cursor' })

-- Line movement remaps
vim.keymap.set(
  { 'o', 'v', 'n' },
  'gH',
  'g^',
  { desc = 'Move to first nonblank of display line' }
)
vim.keymap.set(
  { 'o', 'v', 'n' },
  'gL',
  'g<End>',
  { desc = 'Move to last nonblank of display line' }
)

vim.keymap.set(
  { 'o', 'v', 'n' },
  'H',
  '^',
  { desc = 'Move to first nonblank of logical line' }
)
vim.keymap.set(
  { 'o', 'v', 'n' },
  'L',
  'g_',
  { desc = 'Move to last nonblank of logical line' }
)

vim.keymap.set({ 'o', 'v', 'n' }, 'zh', 'H', { desc = 'Move to top of window' })
vim.keymap.set({ 'o', 'v', 'n' }, 'zl', 'L', { desc = 'Move to bottom of window' })
vim.keymap.set({ 'o', 'v', 'n' }, 'zm', 'M', { desc = 'Move to middle of window' })

vim.keymap.set('n', 'Q', '<Nop>', { desc = 'Disable Q' })

-- Delete without cutting
vim.keymap.set({ 'n', 'v' }, 'x', '"_x', { desc = 'Delete without cutting' })
-- TODO: review: this might be making the which key helpers confused regarding
-- commands starting with c like for "changing surround"
-- vim.keymap.set({ 'n', 'v' }, 'c', '"_c', { desc = 'Delete without cutting' })
-- TODO: mapke normal mode 'D' delete the the whole line like dd, But leave a space
-- vim.keymap.set('n', 'D', '"_D', { desc = 'Delete to end of line without cutting' })

vim.keymap.set(
  'x',
  'p',
  'p:let @+=@0<CR>',
  { silent = true, desc = 'Paste (better for visual mode)' }
)

vim.keymap.set({ 'n', 'v' }, 'vv', 'V', { desc = 'Highlight line' })

-- ******** Find and Search mappings **********
local function set_search_pattern(pattern, jump_sequence)
  vim.fn.setreg('/', pattern)
  enable_search_highlight()
  if jump_sequence and jump_sequence ~= '' then
    vim.cmd.normal { jump_sequence, bang = true }
  end
end

local function get_visual_selection_text()
  local visual_mode = vim.fn.mode()
  if not vim.tbl_contains({ 'v', 'V', '\22' }, visual_mode) then
    visual_mode = vim.fn.visualmode()
  end

  local ok, region =
    pcall(vim.fn.getregion, vim.fn.getpos 'v', vim.fn.getpos '.', { type = visual_mode })

  if ok then
    return table.concat(region, '\n')
  end

  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"

  if
    start_pos[2] > end_pos[2]
    or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3])
  then
    start_pos, end_pos = end_pos, start_pos
  end

  -- Use the buffer API so multi-line visual searches keep the exact selected
  -- text instead of relying on register side effects or manual slicing.
  local lines = vim.api.nvim_buf_get_text(
    0,
    start_pos[2] - 1,
    start_pos[3] - 1,
    end_pos[2] - 1,
    end_pos[3],
    {}
  )

  return table.concat(lines, '\n')
end

local function exit_visual_mode()
  vim.cmd [[execute "normal! \<Esc>"]]
end

local function set_literal_visual_search()
  local selection = get_visual_selection_text()
  if selection == '' then
    return
  end

  exit_visual_mode()
  set_search_pattern('\\V' .. vim.fn.escape(selection, '/\\'), 'nN')
end

vim.keymap.set(
  'v',
  '//',
  set_literal_visual_search,
  { silent = true, desc = 'Search in file: selected text' }
)

vim.keymap.set('n', '*', function()
  set_search_pattern('\\<' .. vim.fn.expand '<cword>' .. '\\>', 'nN')
end, { silent = true, desc = 'Search in file: word under cursor' })
vim.keymap.set(
  'v',
  '*',
  set_literal_visual_search,
  { silent = true, desc = 'Search in file: selected text' }
)

vim.keymap.set('n', '<leader>y', ':let @+ = expand("%:p")<CR>', {
  silent = true,
  desc = '[Y]ank file path',
})

local function append_to_system_clipboard(text)
  local clipboard = vim.fn.getreg '+'
  local separator = ''
  if clipboard ~= '' and clipboard:sub(-1) ~= '\n' then
    separator = '\n'
  end

  vim.fn.setreg('+', clipboard .. separator .. text)
end

vim.keymap.set('n', '<leader>Y', function()
  append_to_system_clipboard(vim.fn.expand '%:p')
end, { desc = '[Y]ank file path and append to system clipboard' })

local function append_block_to_system_clipboard(text)
  local clipboard = vim.fn.getreg '+'
  local separator = ''

  if clipboard ~= '' then
    if clipboard:sub(-2) == '\n\n' then
      separator = ''
    elseif clipboard:sub(-1) == '\n' then
      separator = '\n'
    else
      separator = '\n\n'
    end
  end

  vim.fn.setreg('+', clipboard .. separator .. text)
end

local function get_visual_line_range()
  local mode = vim.fn.mode()
  local start_line
  local end_line

  if vim.tbl_contains({ 'v', 'V', '\22' }, mode) then
    start_line = vim.fn.getpos('v')[2]
    end_line = vim.fn.getpos('.')[2]
  else
    start_line = vim.fn.line "'<"
    end_line = vim.fn.line "'>"
  end

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  return start_line == end_line and tostring(start_line) or start_line .. '-' .. end_line
end

vim.keymap.set({ 'n', 'i' }, '<C-g>', function()
  local clipboard = vim.fn.getreg '+'
  if clipboard == '' then
    vim.notify('Clipboard is empty', vim.log.levels.WARN)
    return
  end
  local col = vim.fn.col '.'
  local link = '[](' .. clipboard .. ')'
  vim.api.nvim_put({ link }, 'c', true, true)
  vim.fn.cursor(vim.fn.line '.', col + 1)
  vim.cmd 'startinsert'
end, { desc = 'Insert markdown link from clipboard' })

-- TODO: map normal mode Y to something. i dont have much use for the default
-- which is yanking from cursor to the end of the line

vim.keymap.set({ 'v', 'x' }, 'Y', function()
  append_to_system_clipboard(get_visual_selection_text())
  exit_visual_mode()
end, { desc = '[Y]ank selected text, append to system clipboard' })

local function get_visual_selection_with_path()
  local selected_text = get_visual_selection_text()
  local filepath = vim.fn.expand '%:p'
  local line_range = get_visual_line_range()

  return selected_text .. '\n\n' .. '## ' .. filepath .. ':' .. line_range
end

vim.keymap.set({ 'v', 'x' }, '<leader>y', function()
  local result = get_visual_selection_with_path()
  -- Set the clipboard register with our formatted result
  vim.fn.setreg('+', result)
  exit_visual_mode()
  -- vim.notify(
  --   'Copied: ' .. filepath .. ':' .. line_range .. ' with selected text',
  --   vim.log.levels.INFO
  -- )
end, { desc = '[Y]ank file path, line range, and selected text' })

vim.keymap.set({ 'v', 'x' }, '<leader>Y', function()
  append_block_to_system_clipboard(get_visual_selection_with_path())
  exit_visual_mode()
end, { desc = '[Y]ank and append to clipboard: file path, line range, selected text' })

-- Yank entire document with file path appended
vim.keymap.set('n', 'yaD', function()
  -- Yank entire document (this triggers the highlight flash)
  vim.cmd 'normal! ggVGy'
  -- Get the yanked text from the unnamed register
  local document_text = vim.fn.getreg '"'
  -- Get the absolute file path
  local filepath = vim.fn.expand '%:p'
  local result = document_text .. '\n\n## ' .. filepath
  -- Set the clipboard register with our formatted result
  vim.fn.setreg('+', result)
  -- Notify the user
  -- vim.notify('Copied entire document with file path: ' .. filepath, vim.log.levels.INFO)
end, { desc = '[Y]ank [A]round [D]ocument with file path' })

-- ERROR: not working right now
-- vim.keymap.set('n', 'glp', function()
--   vim.cmd 'normal! TODO
-- end, { desc = 'Select recently pasted' })

vim.keymap.set('n', 'gly', function()
  vim.cmd 'normal! `[v`]'
end, { desc = 'Highlight last [Y]anked' })

vim.keymap.set({ 'n', 'v' }, ';', ':', { desc = 'Command mode' })
vim.keymap.set({ 'n', 'v' }, ':', ';', { desc = 'Repeat f/t motion' })

vim.keymap.set('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })
vim.keymap.set('i', 'jj', '<Esc>', { desc = 'Exit insert mode' })
vim.keymap.set('i', 'kk', '<Esc>', { desc = 'Exit insert mode' })

-- Preserve Karabiner q-mode navigation and deletion in Insert mode.
vim.keymap.set('i', '<M-Left>', '<C-Left>', { desc = 'Move backward by word' })
vim.keymap.set('i', '<M-Right>', '<C-Right>', { desc = 'Move forward by word' })
vim.keymap.set('i', '<D-Left>', '<Home>', { desc = 'Move to beginning of line' })
vim.keymap.set('i', '<D-Right>', '<End>', { desc = 'Move to end of line' })
vim.keymap.set('i', '<M-BS>', '<C-w>', { desc = 'Delete backward by word' })
vim.keymap.set('i', '<M-Del>', '<C-o>"_de', { desc = 'Delete forward by word' })

function DeleteLineIfEmpty()
  if vim.fn.getline '.' == '' then
    return '"_dd'
  else
    return 'dd'
  end
end

function DeleteIfEmpty()
  if vim.fn.getline '.' == '' then
    return '"_d'
  else
    return 'd'
  end
end

function DeleteLineLeaveBlankLine()
  -- return 'S<Esc>'
  return '"_S<Esc>' -- to not cut it to clipboard
end

vim.keymap.set({ 'n', 'v' }, 'D', DeleteLineLeaveBlankLine, { expr = true })
vim.keymap.set('n', 'dd', DeleteLineIfEmpty, { expr = true })
vim.keymap.set('n', 'd', DeleteIfEmpty, { expr = true })

--   Quickfix List (:copen):
--   - Global to the entire Vim session
--   - Shared across all windows and tabs
--   - Commands start with c: :copen, :cnext, :cprev, :cdo
--   - Used by commands like :grep, :make, :vimgrep
--   - One quickfix list per Vim instance
--
--   Location List (:lopen):
--   - Local to each window
--   - Each window can have its own location list
--   - Commands start with l: :lopen, :lnext, :lprev, :ldo
--   - Used by LSP diagnostics, some plugins
--   - Multiple location lists can exist simultaneously
--
--   Key differences:
--   - Scope: Quickfix is global, location list is per-window
--   - Use case: Quickfix for project-wide searches/builds, location
--   list for window-specific results
--   - Persistence: Quickfix persists when switching windows, location
--   list is tied to its window
--
--   Most commonly you'll use quickfix for grep results and location
--   list for LSP errors/warnings.

-- TODO:  QUESTION: what is this? whats difference between location list and quickfix list?
-- QUESTION: maybe this should be remaped to something else coresponding to location
-- letters/commands, and make a similar function for the QUICKFIX list and map it to:
-- <leader>qq  ??
-- Diagnostic keymaps
-- TODO: this opens the location list, not the quickfix list
vim.keymap.set(
  'n',
  '<leader>qq',
  vim.diagnostic.setloclist,
  { desc = 'Open diagnostic [Q]uickfix list' }
)

-- Create a user command for toggling location list
vim.api.nvim_create_user_command('Ltoggle', function()
  local wininfo = vim.fn.getwininfo()
  for _, win in pairs(wininfo) do
    if win.loclist == 1 then
      vim.cmd 'lclose'
      return
    end
  end
  vim.cmd 'lopen'
end, { desc = 'Toggle location list' })

-- quickfix list, q
-- TODO: make <leader> command to toggle list
vim.api.nvim_create_user_command('Ctoggle', function()
  local wininfo = vim.fn.getwininfo()
  for _, win in pairs(wininfo) do
    if win.quickfix == 1 then
      vim.cmd 'cclose'
      return
    end
  end
  -- vim.cmd 'copen'
  vim.cmd 'cwindow'
end, { desc = 'Toggle quickfix list' })

-- Default export path: global cwd (where nvim was launched, ignoring :tcd/:lcd),
-- named with an ISO date prefix per the YYYY_MM_DD-name convention.
local function qf_export_path(arg, suffix)
  if arg ~= '' then return arg end
  return vim.fs.joinpath(vim.fn.getcwd(-1, -1), os.date('%Y_%m_%d-%H%M%S-') .. suffix .. '.txt')
end

-- Export quickfix list as file:line:col:text, reloadable with :cfile
vim.api.nvim_create_user_command('QfToFile', function(opts)
  local filename = qf_export_path(opts.args, 'quickfix')
  local lines = vim.tbl_map(function(item)
    return ('%s:%d:%d:%s'):format(vim.fn.bufname(item.bufnr), item.lnum, item.col, item.text)
  end, vim.fn.getqflist())
  vim.fn.writefile(lines, filename)
  print('Quickfix list exported to ' .. filename)
  vim.cmd.edit(vim.fn.fnameescape(filename))
end, { nargs = '?', complete = 'file' })

-- Export quickfix list to file (unique files only)
vim.api.nvim_create_user_command('QfToFileU', function(opts)
  local filename = qf_export_path(opts.args, 'quickfix-files')
  local qflist = vim.fn.getqflist()
  -- Extract unique filenames
  local files = {}
  local seen = {}
  for _, item in ipairs(qflist) do
    local filepath = vim.fn.bufname(item.bufnr)
    if filepath ~= '' and not seen[filepath] then
      table.insert(files, filepath)
      seen[filepath] = true
    end
  end
  -- Write to file
  local file = io.open(filename, 'w')
  if file then
    for _, filepath in ipairs(files) do
      file:write(filepath .. '\n')
    end
    file:close()
    print('Exported ' .. #files .. ' unique files to ' .. filename)
    vim.cmd('edit ' .. filename)
  else
    print('Error: Could not write to ' .. filename)
  end
end, { nargs = '?' })

vim.keymap.set('n', '<leader>qa', function()
  local file = vim.fn.expand '%'
  local line_num = vim.fn.line '.'
  local line_text = vim.fn.getline '.'
  vim.fn.setqflist(
    { {
      filename = file,
      lnum = line_num,
      text = line_text,
    } },
    'a'
  ) -- 'a' means append
  vim.notify(
    ('Added %s:%d to quickfix'):format(file, line_num),
    vim.log.levels.INFO,
    { timeout = 1500 }
  )
end, { desc = '[Q]uickfix [A]dd current line' })

-- DELETE: ??? this might be redundant. i think i can just delete using dd
vim.keymap.set('n', '<leader>qd', function()
  local qflist = vim.fn.getqflist()
  local current_idx = vim.fn.line '.'
  if #qflist == 0 then
    print 'Quickfix list is empty'
    return
  end
  if current_idx > 0 and current_idx <= #qflist then
    table.remove(qflist, current_idx)
    vim.fn.setqflist(qflist, 'r') -- 'r' means replace
    print('Removed item ' .. current_idx .. ' from quickfix list')
  else
    print 'Invalid quickfix item index'
  end
end, { desc = '[Q]uickfix [D]elete current item' })

-- QUESTION: what is location list?
-- This function toggles the list, But I'm not sure how to use the location list.
-- TODO: make leader>something like this but toggle qflist
vim.keymap.set('n', '<leader>ql', function()
  local wininfo = vim.fn.getwininfo()
  for _, win in pairs(wininfo) do
    if win.loclist == 1 then
      vim.cmd 'lclose'
      return
    end
  end
  vim.cmd 'lopen'
end, { desc = '[Q]uickfix [T]oggle location list' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function()
    vim.keymap.set('n', 'dd', function()
      local current_line = vim.fn.line '.'
      local qflist = vim.fn.getqflist()
      table.remove(qflist, current_line)
      vim.fn.setqflist(qflist, 'r')
      local new_line = math.min(current_line, #qflist)
      if new_line > 0 then
        vim.fn.cursor(new_line, 1)
      end
    end, { buffer = true, desc = 'Delete quickfix item' })
  end,
})

-- vim.keymap.set('n', '<leader>kA', function()
--   vim.cmd 'w'
--   vim.cmd 'qa'
-- end, { desc = 'Write current Buffer then Quit all' })
--
-- vim.keymap.set('n', '<leader>kQ', function()
--   vim.cmd 'q'
-- end, { desc = 'Quit buffer' })
--
-- vim.keymap.set('n', '<leader>kq', function()
--   vim.cmd 'wq'
-- end, { desc = 'Write and Quit buffer' })

vim.keymap.set('n', '<leader>\\sl', function()
  vim.cmd ':Lazy sync'
end, { desc = ':[L]azy [S]ync' })

vim.keymap.set('n', '<leader>\\so', function()
  vim.cmd 'source ~/.config/nvim/init.lua'
  print 'Reloaded nvim config'
end, { desc = '[S][O]urce nvim config' })

-- DELETE:
-- vim.keymap.set(
--   'n',
--   '<leader>kx',
--   '<cmd>!chmod +x %<CR>',
--   { silent = true, desc = 'chmod +x' }
-- )

-- Navigation mappings for Karabiner sections
vim.keymap.set('n', '<leader>\\kn', 'G?normal-mappings--<CR>zt')
vim.keymap.set('n', '<leader>\\kcb', 'G?clipboard-mappings--<CR>zt')
vim.keymap.set('n', '<leader>\\ktx', 'G?text-objects--<CR>zt')
vim.keymap.set('n', '<leader>\\kf', 'G?find-mappings--<CR>zt')
vim.keymap.set('n', '<leader>\\kfr', 'G?find-and-replace-mappings--<CR>zt')
vim.keymap.set('n', '<leader>\\kp', 'G?plugins--<CR>zt')
vim.keymap.set('n', '<leader>\\ke', 'G?experiments--<CR>zt')
vim.keymap.set('n', '<leader>\\keg', 'G?experiments-good--<CR>zt')
vim.keymap.set('n', '<leader>\\kte', 'G?text-manipulation--<CR>zt')
vim.keymap.set('n', '<leader>\\kmv', 'G?movement-mappings--<CR>zt')

-- Karabiner template navigation
vim.keymap.set('n', '<leader>\\kt', 'G/templates--<CR>zt')
vim.keymap.set('n', '<leader>\\kto', 'G/to--<CR>zt')
vim.keymap.set('n', '<leader>\\kfrom', 'G/from--<CR>zt')
vim.keymap.set('n', '<leader>\\kl', 'G/layers--<CR>zt')
vim.keymap.set('n', '<leader>\\kgr', 'G/grave-mode--<CR>zt')
vim.keymap.set('n', '<leader>\\kf2', 'G/f2-mode--<CR>zt')
vim.keymap.set('n', '<leader>\\khl', 'G/hyper-mode+<CR>zt')
vim.keymap.set('n', '<leader>\\kal', 'G/applications-list--<CR>zt')

vim.keymap.set('n', '<leader>\\km', 'G?main--<CR>zt')
vim.keymap.set('n', '<leader>\\ka', 'G/app-specific--<CR>zz<CR>')
vim.keymap.set('n', '<leader>\\kvs', 'G/vscode--<CR>zt')
vim.keymap.set('n', '<leader>\\kcu', 'G/cursor--<CR>zt')
vim.keymap.set('n', '<leader>\\kvc', 'G/vsodeAndCursor--<CR>zt')
vim.keymap.set('n', '<leader>\\kff', 'G/firefox--<CR>zt')
vim.keymap.set('n', '<leader>\\kch', 'G/chrome--<CR>zt')
vim.keymap.set('n', '<leader>\\kfx', 'G/firefox-extension--<CR>zt')
vim.keymap.set('n', '<leader>\\kb', 'G/bear--<CR>zt')

vim.keymap.set('n', '<leader>\\kgs', 'G/global--section--<CR>zt<CR>')
vim.keymap.set('n', '<leader>\\kg', 'G/global--<CR>zt<CR>')

-- Q-mode mappings
vim.keymap.set('n', '<leader>\\kq', 'G/q-mode--<CR>zt')
vim.keymap.set('n', '<leader>\\kq1', 'G/q-FUNCTION--<CR>zt')
vim.keymap.set('n', '<leader>\\kq2', 'G/q-NUMBERS--<CR>zt')
vim.keymap.set('n', '<leader>\\kqq', 'G/q-QUERTY--<CR>zt')
vim.keymap.set('n', '<leader>\\kqa', 'G/q-ASDFG--<CR>zt')
vim.keymap.set('n', '<leader>\\kqz', 'G/q-ZXCVB--<CR>zt')

-- Hyper-mode mappings
vim.keymap.set('n', '<leader>\\kh', 'G/hyper-mode--<CR>zt')
vim.keymap.set('n', '<leader>\\khn', 'G/hyper-mode-navigation<CR>zt')
vim.keymap.set('n', '<leader>\\kh1', 'G/hyper-FUNCTION--<CR>zt')
vim.keymap.set('n', '<leader>\\kh2', 'G/hyper-NUMBERS--<CR>zt')
vim.keymap.set('n', '<leader>\\khq', 'G/hyper-QUERTY--<CR>zt')
vim.keymap.set('n', '<leader>\\kha', 'G/hyper-ASDFG--<CR>zt')
vim.keymap.set('n', '<leader>\\khz', 'G/hyper-ZXCVB--<CR>zt')

-- Z-mode mappings
vim.keymap.set('n', '<leader>\\kz', 'G/z-mode--<CR>zt')
vim.keymap.set('n', '<leader>\\kz1', 'G/z-FUNCTION--<CR>zt')
vim.keymap.set('n', '<leader>\\kz2', 'G/z-NUMBERS--<CR>zt')
vim.keymap.set('n', '<leader>\\kzq', 'G/z-QUERTY--<CR>zt')
vim.keymap.set('n', '<leader>\\kza', 'G/z-ASDFG--<CR>zt')
vim.keymap.set('n', '<leader>\\kzz', 'G/z-ZXCVB--<CR>zt')

-- Quote-mode mappings
vim.keymap.set('n', '<leader>\\kqu', 'G/quote-mode-<CR>zt')
vim.keymap.set('n', '<leader>\\kqu1', 'G/quote-FUNCTION--<CR>zt')
vim.keymap.set('n', '<leader>\\kqu2', 'G/quote-NUMBERS--<CR>zt')
vim.keymap.set('n', '<leader>\\kquq', 'G/quote-QUERTY--<CR>zt')
vim.keymap.set('n', '<leader>\\kqua', 'G/quote-ASDFG--<CR>zt')
vim.keymap.set('n', '<leader>\\kquz', 'G/quote-ZXCVB--<CR>zt')

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Inactive keymap and plugin experiments were moved to
-- docs/2026-07-28-keymap-experiments-parking-lot.md so this file stays focused
-- on active behavior.

-- vim: ts=2 sts=2 sw=2 et
