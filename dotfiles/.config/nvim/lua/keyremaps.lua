-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

vim.keymap.set('x', '<leader>ktl', '<cmd>lua print(vim.fn.wordcount().visual_words)<CR>')

function ToggleAutoWrap()
  -- Only allow wrapping for markdown and text files
  local allowed_filetypes = { 'markdown', 'text' }
  local current_ft = vim.bo.filetype
  local is_allowed = false
  -- Check if current filetype is allowed to wrap
  for _, ft in ipairs(allowed_filetypes) do
    if current_ft == ft then
      is_allowed = true
      break
    end
  end
  if not is_allowed then
    print('Soft wrap is only allowed for markdown and text files (current: ' .. current_ft .. ')')
    return
  end
  -- Toggle wrap for allowed filetypes
  if vim.wo.wrap then
    vim.wo.wrap = false
    vim.wo.linebreak = false
    vim.wo.breakindent = false
    print 'Soft wrap OFF'
  else
    vim.wo.wrap = true
    vim.wo.linebreak = true
    vim.wo.breakindent = true
    vim.opt.textwidth = 0
    vim.opt.wrapmargin = 0
    print 'Soft wrap ON'
  end
end

vim.api.nvim_create_user_command(
  'ToggleAutoWrap',
  ToggleAutoWrap,
  { desc = 'Toggle soft wrapping' }
)
vim.keymap.set('n', '<leader>ktw', ToggleAutoWrap, { desc = 'Toggle soft wrapping' })

-- Toggle hard wrapping by setting/unsetting textwidth
function ToggleTextwidth()
  if vim.opt.textwidth:get() == 0 then
    local width = vim.api.nvim_win_get_width(0) - 2
    vim.opt.textwidth = width
    print('Hard wrap ON (' .. width .. ' cols)')
  else
    vim.opt.textwidth = 0
    print 'Hard wrap OFF'
  end
end
vim.keymap.set(
  'n',
  '<leader>ktt',
  ToggleTextwidth,
  { desc = 'Toggle textwidth wrapping' }
)
vim.api.nvim_create_user_command(
  'ToggleTextwidth',
  ToggleTextwidth,
  { desc = 'Toggle textwidth wrapping' }
)

--  See `:help hlsearch`
vim.keymap.set(
  'n',
  '<Return>',
  '<cmd>nohlsearch<CR>',
  { desc = 'Clear search highlight' }
)

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
vim.keymap.set({ 'n', 'v' }, 'K', 'gE', { desc = '(gE) Go to the end of the last Word' })
vim.keymap.set('n', 'n', 'nzv', { desc = 'Go to next match' })
vim.keymap.set('n', 'N', 'Nzv', { desc = 'Go to previous match' })
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join line below to current line' })

-- Good bc doesnt clutter up the jumplist
-- Scroll half as much as default (1/4 page instead of 1/2)
vim.keymap.set('n', '<C-d>', function()
  local scroll_amount = math.floor(vim.fn.winheight(0) / 4)
  vim.cmd('normal! ' .. scroll_amount .. 'jzz')
end, { desc = 'Scroll down 1/4 page' })

vim.keymap.set('n', '<C-u>', function()
  local scroll_amount = math.floor(vim.fn.winheight(0) / 4)
  vim.cmd('normal! ' .. scroll_amount .. 'kzz')
end, { desc = 'Scroll up 1/4 page' })

-- Line movement remaps
vim.keymap.set({ 'o', 'v', 'n' }, 'L', 'g_', { desc = 'Move to end of line' })
vim.keymap.set({ 'o', 'v', 'n' }, 'H', '^', { desc = 'Move to beginning of line' })
vim.keymap.set({ 'o', 'v', 'n' }, 'zl', 'L', { desc = 'Move to bottom of page' })
vim.keymap.set({ 'o', 'v', 'n' }, 'zh', 'H', { desc = 'Move to top of page' })
vim.keymap.set({ 'o', 'v', 'n' }, 'zm', 'M', { desc = 'Move to middle of page' })

vim.keymap.set({ 'o', 'v', 'n' }, 'gL', 'g$', { desc = 'Move to end of viewport line' })
vim.keymap.set({ 'o', 'v', 'n' }, 'gH', 'g^', { desc = 'Move to end of viewport line' })

vim.keymap.set({ 'v', 'n' }, 'j', 'gj', { desc = 'Down same for wrapped or no wrapped' })
vim.keymap.set({ 'v', 'n' }, 'k', 'gk', { desc = 'Up same for wrapped or no wrapped' })

-- TODO: M available

vim.keymap.set('n', 'Q', '<Nop>', { desc = 'Disable Q' })

-- Delete without cutting
vim.keymap.set({ 'n', 'v' }, 'x', '"_x', { desc = 'Delete without cutting' })
vim.keymap.set({ 'n', 'v' }, 'c', '"_c', { desc = 'Delete without cutting' })
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
vim.keymap.set(
  'v',
  '//',
  "\"sy:let @/ = '\\V' . escape(@s, '/\\\\')<Bar>set hls<Bar>execute 'normal! nN'<CR>",
  { silent = true, desc = 'Search in file: selected text' }
)

vim.keymap.set(
  'n',
  '*',
  ":let @/='\\<'.expand('<cword>').'\\>'<CR>:set hls<CR>:execute 'normal! n'<CR>:execute 'normal! N'<CR>",
  { silent = true, desc = 'Search in file: word under cursor' }
)
vim.keymap.set(
  'v',
  '*',
  "\"sy:let @/ = '\\V' . escape(@s, '/\\\\')<Bar>set hls<Bar>execute 'normal! nN'<CR>",
  { silent = true, desc = 'Search in file: selected text' }
)

vim.keymap.set('n', '<leader>Y', ':let @+ = expand("%:p")<CR>', {
  silent = true,
  desc = '[Y]ank file path',
})

vim.keymap.set({ 'v', 'x' }, '<leader>Y', function()
  vim.cmd 'normal! y'
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  local filepath = vim.fn.expand '%:p'
  local line_range = start_line == end_line and tostring(start_line)
    or start_line .. '-' .. end_line
  local result = '## ' .. filepath .. ':' .. line_range
  -- Set the clipboard register with our formatted result
  vim.fn.setreg('+', result)
  print('Copied: ' .. filepath .. ':' .. line_range .. ' with selected text')
end, { desc = '[Y]ank file path, line range' })

vim.keymap.set({ 'n' }, '<leader>y', function()
  local line_num = vim.fn.line '.'
  -- First, yank the selection to capture it properly
  vim.cmd 'normal! yy'
  -- Get selection info after yanking
  -- local start_line = vim.fn.line "'<"
  -- local end_line = vim.fn.line "'>"
  -- Get the selected text from the unnamed register (just yanked)
  local selected_text = vim.fn.getreg '"'
  local filepath = vim.fn.expand '%:p'
  -- local line_range = start_line == end_line and tostring(start_line) or start_line .. '-' .. end_line
  local result = selected_text .. '\n\n' .. '## ' .. filepath .. ':' .. line_num
  -- Set the clipboard register with our formatted result
  vim.fn.setreg('+', result)
  print('Copied: ' .. filepath .. ':' .. line_num .. ' with selected text')
end, { desc = '[Y]ank file path, line range, and selected text' })

vim.keymap.set({ 'v', 'x' }, '<leader>y', function()
  vim.cmd 'normal! y'
  -- Get selection info after yanking
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  -- Get the selected text from the unnamed register (just yanked)
  local selected_text = vim.fn.getreg '"'
  local filepath = vim.fn.expand '%:p'
  local line_range = start_line == end_line and tostring(start_line)
    or start_line .. '-' .. end_line
  local result = selected_text .. '\n\n' .. '## ' .. filepath .. ':' .. line_range
  -- Set the clipboard register with our formatted result
  vim.fn.setreg('+', result)
  print('Copied: ' .. filepath .. ':' .. line_range .. ' with selected text')
end, { desc = '[Y]ank file path, line range, and selected text' })

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

-- -- Delete blank lines in selection
-- function DeleteBlankLinesInSelection()
--   vim.cmd "'<,'>g/^\\s*$/d"
-- end
-- vim.keymap.set(
--   'v',
--   '<leader>d',
--   ':<C-u>lua DeleteBlankLinesInSelection()<CR>',
--   { desc = 'Delete blank lines in visual selection' }
-- )
-- vim.keymap.set(
--   'v',
--   '<leader>e',
--   ':<C-u>lua DeleteBlankLinesInSelection()<CR>',
--   { desc = 'Delete blank lines in visual selection' }
-- )
--
-- -- Delete next or current blank line
-- function DeleteNextOrCurrentBlankLine()
--   if vim.fn.getline('.'):match '^%s*$' then
--     vim.cmd 'normal! "_dd'
--   else
--     local found = vim.fn.search('^\\s*$', 'W')
--     if found > 0 then
--       vim.cmd 'normal! "_dd'
--     end
--   end
-- end
-- vim.keymap.set('n', '<leader>d', DeleteNextOrCurrentBlankLine, { desc = 'Delete next or current blank line' })
--
-- -- Delete previous or current blank line
-- function DeletePreviousOrCurrentBlankLine()
--   if vim.fn.getline('.'):match '^%s*$' then
--     vim.cmd 'normal! "_dd'
--   else
--     local found = vim.fn.search('^\\s*$', 'bW')
--     if found > 0 then
--       vim.cmd 'normal! "_dd'
--     end
--   end
-- end
-- vim.keymap.set('n', '<leader>e', DeletePreviousOrCurrentBlankLine, { desc = 'Delete previous or current blank line' })

-- What's the difference between the quick fix list and the location list?
--
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
--
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

vim.api.nvim_create_user_command('QfToFile', function(opts)
  vim.cmd('redir > ' .. filename)
  vim.cmd 'silent clist'
  vim.cmd 'redir END'
  print('Quickfix list exported to ' .. filename)
  vim.cmd('edit ' .. filename)
end, { nargs = '?' })

-- Export quickfix list to file (unique files only)
vim.api.nvim_create_user_command('QfToFileU', function(opts)
  local filename = opts.args ~= '' and opts.args or 'quickfix_export.txt'
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
  local entry = file .. ':' .. line_num .. ':' .. line_text
  vim.fn.setqflist(
    { {
      filename = file,
      lnum = line_num,
      text = line_text,
    } },
    'a'
  ) -- 'a' means append
  print('Added to quickfix: ' .. entry)
end, { desc = '[Q]uickfix [A]dd current line' })

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

vim.keymap.set('n', '<leader>ksl', function()
  vim.cmd ':Lazy sync'
end, { desc = ':[L]azy [S]ync' })

vim.keymap.set('n', '<leader>kso', function()
  vim.cmd 'source ~/.config/nvim/init.lua'
  print 'Reloaded nvim config'
end, { desc = '[S][O]urce nvim config' })

vim.keymap.set(
  'n',
  '<leader>kx',
  '<cmd>!chmod +x %<CR>',
  { silent = true, desc = 'chmod +x' }
)

-- Navigation mappings for Karabiner sections
vim.keymap.set('n', '<leader>kkn', 'G?normal-mappings--<CR>zt')
vim.keymap.set('n', '<leader>kkcb', 'G?clipboard-mappings--<CR>zt')
vim.keymap.set('n', '<leader>kktx', 'G?text-objects--<CR>zt')
vim.keymap.set('n', '<leader>kkf', 'G?find-mappings--<CR>zt')
vim.keymap.set('n', '<leader>kkfr', 'G?find-and-replace-mappings--<CR>zt')
vim.keymap.set('n', '<leader>kkp', 'G?plugins--<CR>zt')
vim.keymap.set('n', '<leader>kke', 'G?experiments--<CR>zt')
vim.keymap.set('n', '<leader>kkeg', 'G?experiments-good--<CR>zt')
vim.keymap.set('n', '<leader>kkte', 'G?text-manipulation--<CR>zt')
vim.keymap.set('n', '<leader>kkmv', 'G?movement-mappings--<CR>zt')

-- Karabiner template navigation
vim.keymap.set('n', '<leader>kkt', 'G/templates--<CR>zt')
vim.keymap.set('n', '<leader>kkto', 'G/to--<CR>zt')
vim.keymap.set('n', '<leader>kkfrom', 'G/from--<CR>zt')
vim.keymap.set('n', '<leader>kkl', 'G/layers--<CR>zt')
vim.keymap.set('n', '<leader>kkgr', 'G/grave-mode--<CR>zt')
vim.keymap.set('n', '<leader>kkf2', 'G/f2-mode--<CR>zt')
vim.keymap.set('n', '<leader>kkhl', 'G/hyper-mode+<CR>zt')
vim.keymap.set('n', '<leader>kkal', 'G/applications-list--<CR>zt')

vim.keymap.set('n', '<leader>kkm', 'G?main--<CR>zt')
vim.keymap.set('n', '<leader>kka', 'G/app-specific--<CR>zz<CR>')
vim.keymap.set('n', '<leader>kkvs', 'G/vscode--<CR>zt')
vim.keymap.set('n', '<leader>kkcu', 'G/cursor--<CR>zt')
vim.keymap.set('n', '<leader>kkvc', 'G/vsodeAndCursor--<CR>zt')
vim.keymap.set('n', '<leader>kkff', 'G/firefox--<CR>zt')
vim.keymap.set('n', '<leader>kkch', 'G/chrome--<CR>zt')
vim.keymap.set('n', '<leader>kkfx', 'G/firefox-extension--<CR>zt')
vim.keymap.set('n', '<leader>kkb', 'G/bear--<CR>zt')

vim.keymap.set('n', '<leader>kkgs', 'G/global--section--<CR>zt<CR>')
vim.keymap.set('n', '<leader>kkg', 'G/global--<CR>zt<CR>')

-- Q-mode mappings
vim.keymap.set('n', '<leader>kkq', 'G/q-mode--<CR>zt')
vim.keymap.set('n', '<leader>kkq1', 'G/q-FUNCTION--<CR>zt')
vim.keymap.set('n', '<leader>kkq2', 'G/q-NUMBERS--<CR>zt')
vim.keymap.set('n', '<leader>kkqq', 'G/q-QUERTY--<CR>zt')
vim.keymap.set('n', '<leader>kkqa', 'G/q-ASDFG--<CR>zt')
vim.keymap.set('n', '<leader>kkqz', 'G/q-ZXCVB--<CR>zt')

-- Hyper-mode mappings
vim.keymap.set('n', '<leader>kkh', 'G/hyper-mode--<CR>zt')
vim.keymap.set('n', '<leader>kkhn', 'G/hyper-mode-navigation<CR>zt')
vim.keymap.set('n', '<leader>kkh1', 'G/hyper-FUNCTION--<CR>zt')
vim.keymap.set('n', '<leader>kkh2', 'G/hyper-NUMBERS--<CR>zt')
vim.keymap.set('n', '<leader>kkhq', 'G/hyper-QUERTY--<CR>zt')
vim.keymap.set('n', '<leader>kkha', 'G/hyper-ASDFG--<CR>zt')
vim.keymap.set('n', '<leader>kkhz', 'G/hyper-ZXCVB--<CR>zt')

-- Z-mode mappings
vim.keymap.set('n', '<leader>kkz', 'G/z-mode--<CR>zt')
vim.keymap.set('n', '<leader>kkz1', 'G/z-FUNCTION--<CR>zt')
vim.keymap.set('n', '<leader>kkz2', 'G/z-NUMBERS--<CR>zt')
vim.keymap.set('n', '<leader>kkzq', 'G/z-QUERTY--<CR>zt')
vim.keymap.set('n', '<leader>kkza', 'G/z-ASDFG--<CR>zt')
vim.keymap.set('n', '<leader>kkzz', 'G/z-ZXCVB--<CR>zt')

-- Quote-mode mappings
vim.keymap.set('n', '<leader>kkqu', 'G/quote-mode-<CR>zt')
vim.keymap.set('n', '<leader>kkqu1', 'G/quote-FUNCTION--<CR>zt')
vim.keymap.set('n', '<leader>kkqu2', 'G/quote-NUMBERS--<CR>zt')
vim.keymap.set('n', '<leader>kkquq', 'G/quote-QUERTY--<CR>zt')
vim.keymap.set('n', '<leader>kkqua', 'G/quote-ASDFG--<CR>zt')
vim.keymap.set('n', '<leader>kkquz', 'G/quote-ZXCVB--<CR>zt')

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- ------------------------  experiments ------------------------

-- vim.keymap.set(
--   'n',
--   '<leader>',
--   vim.cmd.Ex,
--   { desc = 'Explorer (netrw) (not working bc oil replacing it?' }
-- )
-- ------------------------------------------------
-- TODO: make gt = peek definition
-- TODO: make gj = show hover
-- TODO: make gr = show references

-- Console log functions
-- function ConsoleLogHereVisual()
-- 	local start_line = vim.fn.line("'<")
-- 	local end_line = vim.fn.line("'>")
-- 	local lines = vim.fn.getline(start_line, end_line)
-- 	local log_statement = "console.log('\\n***** " .. table.concat(lines, " ") .. " **\\n')"
-- 	vim.fn.setreg("+", log_statement)
-- 	vim.cmd("normal! o")
-- 	vim.cmd('normal! "+p')
-- 	vim.cmd("normal! dd")
-- 	vim.cmd("normal! k")
-- end
-- vim.keymap.set("v", "<leader>TODO", ":<C-u>lua ConsoleLogHereVisual()<CR>")

-- TODO: make work. right now it doesnt show up as command in command mode
-- function ShowReg()
-- 	local regs = vim.fn.execute("registers")
-- 	vim.cmd("vnew")
-- 	vim.api.nvim_buf_set_option(0, "buftype", "nofile")
-- 	vim.api.nvim_buf_set_option(0, "bufhidden", "wipe")
-- 	vim.api.nvim_buf_set_option(0, "swapfile", false)
-- 	vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(regs, "\n"))
-- end
-- vim.api.nvim_create_user_command("ShowReg", ShowReg, {})

-- Replace mappings
-- vim.keymap.set('n', '<leader>r', ":let @/='\\<'.expand('<cword>').'\\>'<CR>cgn", { silent = true, desc = 'Replace' })
-- vim.keymap.set('x', '<leader>r', '"sy:let @/=@s<CR>cgn', { silent = true, desc = 'Replace' })
-- ***** TODO: from old $HOME/.config/nvim/init.vim file ****
-- TODO: install and configure these plugins, or find lua replacements
-- " find the last import statement like import {..} from '...' then center page (doesnt exactly work)
-- " nnoremap <leader>6 G?import<CR> gg<C-o>)zz

-- Plug 'vuciv/golf'
--
-- " https://github.com/justinmk/vim-sneak
-- " works but i want to try out subversive
-- Plug 'justinmk/vim-sneak'

-- Plug 'tpope/vim-surround'
-- Plug 'mg979/vim-visual-multi', {'branch': 'master'}
--
-- " Im not actually sure if this is doing anything for me. because in vscode
-- " leaving insert mode is handled by vscode
-- Plug 'jdhao/better-escape.vim'

-- " https://github.com/takac/vim-hardtime
-- Plug 'takac/vim-hardtime'
-- " find-and-replace-mappings--

-- " https://vimawesome.com/plugin/abolish-vim
-- " https://til.hashrocket.com/posts/850ace86d4-case-aware-substitution-with-vim-abolish
-- " Want to turn fooBar into foo_bar? Press crs (coerce to snake_case).
-- " MixedCase (crm), camelCase (crc), snake_case (crs), UPPER_CASE (cru),
-- " dash-case (cr-), dot.case (cr.), space case (cr<space>), and Title Case
-- " (crt) are all just 3 keystrokes away.
-- Plug 'tpope/vim-abolish'

-- " https://github.com/arthurxavierx/vim-caser
-- " Plug 'arthurxavierx/vim-caser'
--
-- " https://github.com/tpope/vim-repeat
-- Plug 'tpope/vim-repeat'

-- " TODO: experimental
-- " Plug 'svermeulen/vim-easyclip'
--
-- " https://github.com/svermeulen/vim-subversive
-- Plug 'svermeulen/vim-subversive'
--
-- Plug 'svermeulen/vim-yoink'
--
-- Plug 'tpope/vim-unimpaired'
--
-- " 2024_04_19_T15_23 added vim-indent-object
-- Plug 'michaeljsmith/vim-indent-object'
--
-- " ********* Pluggin Mapping Definitions begin ***************
--
-- " TODO: rememad  'michaeljsmith/vim-indent-object' aI to ai
-- " Disable the default mappings
-- " let g:indent_object_no_default_key_mappings = 1
--
-- " Remap `ai` to act like `aI`
-- " TODO doesnt work
-- " xmap ai <Plug>(IndentObject_aI)
-- " omap ai <Plug>(IndentObject_aI)
-- " xnoremap ai <Plug>(IndentObject_aI)
-- " onoremap ai <Plug>(IndentObject_aI)
--
-- " " 1. Remove the plugin’s default ai text-object mapping
-- " silent! ounmap ai
-- " silent! vunmap ai
--
-- " " 2. Remap ai to do what aI normally does
-- " onoremap <silent> ai :<C-u>call <SID>HandleTextObjectMapping(0, 1, 0, [line("."), line("."), col("."), col(".")])<CR>
-- " vnoremap <silent> ai :<C-u>call <SID>HandleTextObjectMapping(0, 1, 1, [line("'<"), line("'>"), col("'<"), col("'>")])<CR><Esc>gv
-- "
-- " set nocompatible
-- " Replace all normal/visual operator mappings from `cr` to `<leader>r`.
-- " // TODO: not working
-- " For snake_case:
-- nmap <silent> <leader><leader>as <Plug>(abolish-coerce)S
-- xmap <silent> <leader><leader>as <Plug>(abolish-coerce)S
-- omap <silent> <leader><leader>as <Plug>(abolish-coerce)S
--
-- " For camelCase:
-- nmap <silent> <leader><leader>ac <Plug>(abolish-coerce)c
-- xmap <silent> <leader><leader>ac <Plug>(abolish-coerce)c
-- omap <silent> <leader><leader>ac <Plug>(abolish-coerce)c
--
-- " etc.
--
-- " vim-repeat
-- " silent! call repeat#set("\<Plug>MyWonderfulMap", v:count)  TODO: make this work
--
-- " ********* sneak settings ****
-- " works perfect for sneak forward, but now ror some reason still having
-- " problem. sometimes its sending period and this repeating edits when i'm just
-- " trying move to next with space. maybe its something else going on with mac.
-- " Ok now i actually dont think this is the problem. I think its bc vim-repeat
-- " is now able to repeat more kinds of things, and something else on the
-- " computer is making it auto insert period when i hit two spaces
-- "
-- let g:sneak#s_next = 1
--
-- " TODO(?) make command + \ trigger sneak backwards. or Shift + \
-- " 2-character Sneak (default)
-- "
--
-- "  TODO: Change sneak forward to the default, whatever it is.
-- " nmap mm <Plug>Sneak_s
-- " xmap mm <Plug>Sneak_s
-- " omap mm <Plug>Sneak_s

-- "  TODO: change to default
-- " nmap MM <Plug>Sneak_S
-- " xmap MM <Plug>Sneak_S
-- " omap MM <Plug>Sneak_S

-- " Repeat motion forward
-- "  TODO: change to default
-- " nmap <Space> <Plug>Sneak_;
-- " xmap <Space> <Plug>Sneak_;
-- " omap <Space> <Plug>Sneak_;

-- " Map 'f', 'F', 't', 'T' to Sneak in Normal Mode
-- nmap f <Plug>Sneak_f
-- nmap F <Plug>Sneak_F
-- nmap t <Plug>Sneak_t
-- nmap T <Plug>Sneak_T

-- " Optional: Map in Visual and Operator-Pending Modes if desired
-- xmap f <Plug>Sneak_f
-- xmap F <Plug>Sneak_F
-- xmap t <Plug>Sneak_t
-- xmap T <Plug>Sneak_t

-- omap f <Plug>Sneak_f
-- omap F <Plug>Sneak_F
-- omap t <Plug>Sneak_t
-- omap T <Plug>Sneak_T

-- let g:hardtime_default_on = 1
-- let g:hardtime_showmsg = 1
-- let g:hardtime_maxcount = 35
-- let g:list_of_normal_keys = ["h", "j", "k", "l", "-", "+", "<UP>", "<DOWN>", "<LEFT>", "<RIGHT>"]
-- let g:list_of_visual_keys = ["h", "j", "k", "l", "-", "+", "<UP>", "<DOWN>", "<LEFT>", "<RIGHT>"]
-- let g:list_of_insert_keys = ["<UP>", "<DOWN>", "<LEFT>", "<RIGHT>"]
-- let g:list_of_disabled_keys = [""]

-- " ****** vim-subversive (find-and-replace-mappings--)  ******
-- " vim-substitute does same thing and is popular

-- " s for substitute
-- " https://www.youtube.com/watch?v=crxHxqzXMzw
-- " let g:subversiveCurrentTextRegister = 'r' < this makes it so i can do sgn then . to repeat
-- nmap s <plug>(SubversiveSubstitute)
-- nmap ss <plug>(SubversiveSubstituteLine)
-- nmap S <plug>(SubversiveSubstituteToEndOfLine)

-- " for blocks of text (not confirming each one)
-- nmap <leader>s <plug>(SubversiveSubstituteRange)
-- xmap <leader>s <plug>(SubversiveSubstituteRange)
-- nmap <leader>ss <plug>(SubversiveSubstituteWordRange)

-- " confirming each one (not working)
-- " TODO make this work
-- " nmap <leader>cs <plug>(SubversiveSubstituteRangeConfirm)
-- " xmap <leader>cs <plug>(SubversiveSubstituteRangeConfirm)
-- " nmap <leader>css <plug>(SubversiveSubstituteWordRangeConfirm)

-- " for doing replaces but keeping the case of the replaced word (uses vim-abolish)
-- nmap <leader><leader>s <plug>(SubversiveSubvertRange)
-- xmap <leader><leader>s <plug>(SubversiveSubvertRange)
-- nmap <leader><leader>ss <plug>(SubversiveSubvertWordRange)

-- " so it works with yoink
-- xmap s <plug>(SubversiveSubstitute)
-- xmap p <plug>(SubversiveSubstitute)
-- xmap P <plug>(SubversiveSubstitute)
-- let g:subversiveCurrentTextRegister = 'r'
-- " ***** end vim-subversive  *****

-- " -- Yoink settings  // NOTE: not important. I dont even know what this does
-- nmap p <plug>(YoinkPaste_p)
-- nmap P <plug>(YoinkPaste_P)

-- " Also replace the default gp with yoink paste so we can toggle paste in this case too
-- nmap gp <plug>(YoinkPaste_gp)
-- nmap gP <plug>(YoinkPaste_gP)

-- " ******************* movement-mappings--  (pluggins) ********************
--   " VSCode extension commands (vscode-mode-- vscode--)
-- if exists('g:vscode')
-- " ************* Find-and-replace-mappings-- ***************************

--   " macro for pasting in env vars from aws
--   nnoremap <leader>vars Gvippgv:norm df<Space><CR>
--   " picking out the event from a datadog log copy, then replacing the whole document
--   nnoremap <leader>vent /event":<CR>f{ya{ggVGp
--   nnoremap <leader>tail /detail":<CR>f{ya{ggVGp
--   " nnoremap <leader>context /context":<CR>f{ya{ggVGp  "" TODO make this work
--   " noremap <leader>rl <Cmd>call VSCodeNotify('workbench.action.reloadWindow')<CR>

--   " TODO: make this work
--   command! -bar -nargs=0 NeoVimFunctionFindInFileFromClipboard call NeoVimFunctionFindInFileFromClipboardFunction()
--   function! NeoVimFunctionFindInFileFromClipboardFunction() abort
--       let query = @+
--       let @/ = query
--       call VSCodeNotify('workbench.action.findInFiles', {'query': query, 'isRegex': v:false})
--   endfunction

--   " Find and replace visual selection
--   command! -bar -nargs=0 FindReplaceGlobalVisual call FindReplaceGlobalVisualFunction()
--   function! FindReplaceGlobalVisualFunction() abort
--       let query = @p
--       let @/ = query
--       call VSCodeNotify('workbench.action.findInFiles', {'query': query, 'replace': '', 'isRegex': v:false})
--   endfunction
--   xnoremap <silent> <Leader><Leader><Leader>r "py<Esc>:FindReplaceGlobalVisual<CR>

--     " Find and replace word under caret
--   command! -bar -nargs=0 FindReplaceGlobal call FindReplaceGlobalFunction()
--   function! FindReplaceGlobalFunction() abort
--       let query = expand('<cword>')
--       let @/ = query
--       call VSCodeNotify('workbench.action.findInFiles', {'query': query, 'replace': ''})
--   endfunction
--   nnoremap <silent> <Leader><Leader><Leader>r :FindReplaceGlobal<CR>

-- command! -bar -nargs=0 FindConsoleAndLoggerLogs call FindConsoleAndLoggerLogs()
-- function! FindConsoleAndLoggerLogs() abort
--     " alternate? '(?:console|logger)\.(?:log|error|warn|debug|info)\((?:[^)(]+|\((?:[^)(]+|\([^)(]*\))*\))*\)'
--     let queryForVscode = '.*(?:console)\.(?:log|error|warn|debug|info)\((?:[^)(]+|\((?:[^)(]+|\((?:[^)(]+|\([^)(]*\))*\))*\))*\).*\n'
--     let queryForVim = '\v(console|logger)\.(log|error|warn|debug|info)\('
--     let @/ = queryForVim
--     call VSCodeNotify('workbench.action.findInFiles', {'query': queryForVscode, 'isRegex': v:true})
-- endfunction
-- nnoremap <leader>kl :FindConsoleAndLoggerLogs<CR>

-- command! -bar -nargs=0 FindConsoleLogs call FindConsoleLogs()
-- function! FindConsoleLogs() abort
--     let queryForVscode = '.*(?:console)\.(?:log|error|warn|debug|info)\((?:[^)(]+|\((?:[^)(]+|\((?:[^)(]+|\([^)(]*\))*\))*\))*\).*\n'
--     let queryForVim = '\vconsole\.(log|error|warn|debug|info)\('
--     let @/ = queryForVim
--     call VSCodeNotify('workbench.action.findInFiles', {'query': queryForVscode, 'isRegex': v:true})
-- endfunction
-- " Key mapping to trigger FindConsoleLogs command
-- nnoremap <leader>kc :FindConsoleLogs<CR>

-- command! -bar -nargs=0 FindTodos call FindTodos()
-- function! FindTodos() abort
--     let queryForVscode = '.*(?:\/\/|#|")\s*(TODO|ERROR|NOTE|FAILING|PASSING|REFACTOR|DELETE|IMP|QUESTION|EXPLANATION)[^\n]*\n?|\/\*\*[\s\S]*?(TODO|ERROR|NOTE|FAILING|PASSING|REFACTOR|DELETE|IMP|QUESTION|EXPLANATION)[\s\S]*?\*\/.*'
--   " Simplified pattern for inline TODO comments (works)
--   let queryForVim = '\v(\/\/|#|")\s*(TODO|ERROR|NOTE|REFACTOR|DELETE|IMP|QUESTION|EXPLANATION)'
--     " Set the search register (/) with the regex pattern
--     let @/ = queryForVim
--     call VSCodeNotify('workbench.action.findInFiles', {'query': queryForVscode, 'isRegex': v:true})
-- endfunction
-- nnoremap <leader>kt :FindTodos<CR>

-- command! -bar -nargs=0 FindComments call FindComments()
-- function! FindComments() abort
--   let queryForVscode = '.*(?:\/\/|#|/\*|\*/).*'
--   let queryForVim = '\v(\/\/|#|/\*|\*/)'
--   let @/ = queryForVim
--   call VSCodeNotify('workbench.action.findInFiles', {
--         \ 'query': queryForVscode,
--         \ 'isRegex': v:true
--         \ })
-- endfunction
-- nnoremap <leader>kco :FindComments<CR>

-- " ******************************************** text-manipulation-- **************************************
-- " ****** combinefiles chatgpt extension ****
-- " find lines with more that 4 asterisks/astrix
-- " good example of matching whole line with regex
-- nnoremap <leader>wv /.*\*\{4,\}.*/<CR>
-- vnoremap <leader>wv /.*\*\{4,\}.*/<CR>

-- " find text Included Files, then move one line down ,
-- " cut from current line to bottom or page , then close tab
--   nnoremap <leader>wf /Included Files<CR>jdG:call VSCodeNotify('workbench.action.closeActiveEditor')<CR>

-- " find included files text, then paste in below
-- nnoremap <leader>wg  /Included Files<CR>}kVp
-- vnoremap <leader>wg  /Included Files<CR>}kVp
-- " ******  end combinefiles chatgpt extension ****

-- " console.log normal mode stringify
-- function! StringifyConsoleLogWordNormal()
--   let l:selectedText = expand("<cword>")
--   let l:logStatement = "console.log('\\n" . l:selectedText . ": ', JSON.stringify(" . l:selectedText . ", null, 2))"
--   let @+ = l:logStatement
--   execute "normal! o"
--   execute "normal! \"+p"
--   " delete/cut console.log line for pasting elsewhere as new line
--   execute "normal! dd"
--   execute "normal! k"
-- endfunction
-- nnoremap <leader>j :call StringifyConsoleLogWordNormal()<CR>
--
-- " aws logger.info normal mode stringify
-- function! StringifyLoggerInfoWordNormal()
--   let l:selectedText = expand("<cword>")
--   let l:logStatement = "logger.info(`" . l:selectedText . ": ${JSON.stringify(" . l:selectedText . ", null, 2)}`)"
--   let @+ = l:logStatement
--   execute "normal! o"
--   execute "normal! \"+p"
--   " delete/cut logger.info line for pasting elsewhere as new line
--   execute "normal! dd"
--   execute "normal! k"
-- endfunction
-- nnoremap <leader>lj :call StringifyLoggerInfoWordNormal()<CR>

-- " console.log visual mode stringify
-- function! StringifyConsoleLogVisual() range
--   let l:line1 = line("'<")
--   let l:line2 = line("'>")
--   let l:col1 = col("'<")
--   let l:col2 = col("'>")
--   " // QUESTION: whats this do? whats the \n for?
--   let l:selectedText = join(getline(l:line1, l:line2), "\n")
--   if l:line1 == l:line2
--     let l:selectedText = strpart(l:selectedText, l:col1 - 1, l:col2 - l:col1 + 1)
--   endif
--   let l:logStatement = "console.log('\\n" . l:selectedText . ": ', JSON.stringify(" . l:selectedText . ", null, 2))"
--   let @+ = l:logStatement
--   execute "normal! o"
--   execute "normal! \"+p"
--   execute "normal! dd"
--   execute "normal! k"
-- endfunction
-- vnoremap <leader>j :call StringifyConsoleLogVisual()<CR>

-- " aws logger.info visual mode stringify
-- function! StringifyLoggerInfoVisual() range
--   let l:line1 = line("'<")
--   let l:line2 = line("'>")
--   let l:col1 = col("'<")
--   let l:col2 = col("'>")
--   let l:selectedText = join(getline(l:line1, l:line2), "\n")
--   if l:line1 == l:line2
--     let l:selectedText = strpart(l:selectedText, l:col1 - 1, l:col2 - l:col1 + 1)
--   endif
--   let l:logStatement = "logger.info(`" . l:selectedText . ": ${JSON.stringify(" . l:selectedText . ", null, 2)}`)"
--   let @+ = l:logStatement
--   execute "normal! o"
--   execute "normal! \"+p"
--   execute "normal! dd"
--   execute "normal! k"
-- endfunction
-- vnoremap <leader>lj :call StringifyLoggerInfoVisual()<CR>

-- " console.log visual mode
-- function! ConsoleLogVisual() range
--   " Get the visually selected text "
--   let l:line1 = line("'<")
--   let l:line2 = line("'>")
--   let l:col1 = col("'<")
--   let l:col2 = col("'>") + 1 " Add 1 to include the last character
--   " // QUESTION: whats this do?
--   let l:selectedText = join(getline(l:line1, l:line2), "\n")
--   if l:line1 == l:line2
--     let l:selectedText = strpart(l:selectedText, l:col1 - 1, l:col2 - l:col1)
--   endif
--   let l:logStatement = "console.log('\\n" . l:selectedText . ": ', " . l:selectedText . ")"
--   let @+ = l:logStatement
--   execute "normal! o"
--   execute "normal! \"+p"
--   execute "normal! dd"
--   execute "normal! k"
-- endfunction
-- vnoremap <leader>c :call ConsoleLogVisual()<CR>

-- " aws logger.info visual mode
-- function! LoggerInfoVisual() range
--   " Get the visually selected text "
--   let l:line1 = line("'<")
--   let l:line2 = line("'>")
--   let l:col1 = col("'<")
--   let l:col2 = col("'>") + 1 " Add 1 to include the last character
--   let l:selectedText = join(getline(l:line1, l:line2), "\n")
--   if l:line1 == l:line2
--     let l:selectedText = strpart(l:selectedText, l:col1 - 1, l:col2 - l:col1)
--   endif
--   let l:logStatement = "logger.info(`" . l:selectedText . ": ${" .  l:selectedText . "}`)"
--   let @+ = l:logStatement
--   execute "normal! o"
--   execute "normal! \"+p"
--   execute "normal! dd"
--   execute "normal! k"
-- endfunction
-- vnoremap <leader>lc :call LoggerInfoVisual()<CR>
--
-- " console.log normal mode current word
-- function! ConsoleLogNormal()
--   let l:variable = expand("<cword>")
--   let l:logStatement = "console.log('\\n" . l:variable . ": ', " . l:variable . ")"
--   let @+ = l:logStatement
--   execute "normal! o"
--   execute "normal! \"+p"
--   execute "normal! dd"
--   execute "normal! k"
-- endfunction
-- nnoremap <leader>c :call ConsoleLogNormal()<CR>

-- " aws logger.info normal mode current word
-- function! LoggerInfoNormal()
--   let l:selectedText = expand("<cword>")
--   let l:logStatement = "logger.info(`" . l:selectedText . ": ${" .  l:selectedText . "}`)"
--   let @+ = l:logStatement
--   execute "normal! o"
--   execute "normal! \"+p"
--   execute "normal! dd"
--   execute "normal! k"
-- endfunction
-- nnoremap <leader>lc :call LoggerInfoNormal()<CR>

-- function! ConsoleLogHereNormal()
--   let l:variable = expand("<cword>")
--   let l:logStatement = "console.log('\\n****** " . l:variable . " **\\n')"
--   let @+ = l:logStatement
--   execute "normal! o"
--   execute "normal! \"+p"
--   execute "normal! dd"
--   execute "normal! k"
-- endfunction
-- nnoremap <leader><leader>c :call ConsoleLogHereNormal()<CR>

-- " QUESTION:  not sure what this is suppoed to do. seems to copy first line of visual selection
-- function! ConsoleLogHereVisual() range
--   let l:variableFirstLine = getline(a:firstline, a:lastline)
--   let l:logStatement = "console.log('\\n***** " . join(l:variableFirstLine, ' ') . " **\\n')"
--   let @+ = l:logStatement
--   execute "normal! o"
--   execute "normal! \"+p"
--   execute "normal! dd"
--   execute "normal! k"
-- endfunction
-- vnoremap <leader><leader>c :<C-u>call ConsoleLogHereVisual()<CR>

-- "  function remove all vim comments from a file
-- function! DeleteComments()
--     " Delete all comments from the current file
--     execute 'g/^\s*".*/d'
-- endfunction
-- command! DeleteComments call DeleteComments()
-- " nnoremap <leader>removecomments :call DeleteComments()<CR>

-- " ****************************** not used much ***************
-- vim.keymap.set('n', 'gbp', 'gg)', {desc: '[G]o to in [B]uffer: [I]mports (top paragraph)'})

--   "  TODO: make this work
-- function! OpenEnvFileAndRunMapping()
--     execute 'edit local/example.env'
--     " Go to the bottom of the file
--     " normal G
--   " Go to the last line of the file
--     execute '$'
--     " Run the provided Vim sequence
--     " normal vippgv:norm df<Space><CR>
--     normal! Gvippgv:norm df<Space><CR>
--     " normal! vippgv
--     " normal! df<Space><CR>
-- endfunction
-- nnoremap <leader>vd :call OpenEnvFileAndRunMapping()<CR>

-- " removes any lines that contain a ""
-- function! EdiClean()
--     " Delete all lines that contain empty quotes
--     execute 'g/""/d'
--     " remove all ? symbols
--     execute '%s/?//g'
--     "  TODO:  remove all spaces tht are inside quotes (only the first pair of quotes)
--     " execute '%s/\v"([^"]*)"/\=substitute(submatch(0), " ", "", "g")/g'
-- endfunction
-- command! EdiClean call EdiClean()

-- vim: ts=2 sts=2 sw=2 et
