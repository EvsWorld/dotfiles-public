return {
  'tpope/vim-eunuch',
  config = function()
    local function rename_arg_is_absolute(arg)
      return arg:match('^[~$#%%]') ~= nil or arg:match('^/') ~= nil or arg:match('^%a+:') ~= nil
    end

    local function rename_arg(arg)
      if rename_arg_is_absolute(arg) then
        return arg
      end

      return '%:h/' .. arg
    end

    local function rename_complete(arg_lead)
      local separator = '/'
      local prefix = rename_arg_is_absolute(arg_lead) and '' or (vim.fn.expand('%:h') .. separator)
      local files = vim.fn.glob(prefix .. arg_lead .. '*', false, true)

      return vim.tbl_map(function(file)
        local name = file:sub(#prefix + 1)
        if vim.fn.isdirectory(file) == 1 then
          name = name .. separator
        end
        return vim.fn.fnameescape(name)
      end, files)
    end

    vim.api.nvim_del_user_command('Rename')
    vim.api.nvim_create_user_command('Rename', function(opts)
      if opts.args == '' then
        local current_file_name = vim.fn.expand('%:t')
        if current_file_name == '' then
          vim.notify('Current buffer has no file name', vim.log.levels.ERROR)
          return
        end

        local command = ':Rename' .. (opts.bang and '!' or '') .. ' ' .. vim.fn.fnameescape(current_file_name)
        vim.api.nvim_feedkeys(command, 'n', false)
        return
      end

      local command = ('Move%s %s'):format(opts.bang and '!' or '', vim.fn.escape(rename_arg(opts.args), '"|'))
      vim.cmd(command)
    end, {
      bang = true,
      complete = rename_complete,
      desc = 'Rename the current file, prefilling the current name when omitted',
      nargs = '?',
    })

    local function copy_current_file_component(modifier, description)
      local file_path = vim.api.nvim_buf_get_name(0)
      if file_path == '' then
        vim.notify('Current buffer has no file name', vim.log.levels.ERROR)
        return
      end

      local value = vim.fn.fnamemodify(file_path, modifier)
      vim.fn.setreg('+', value)
      vim.notify(('Copied %s: %s'):format(description, value))
    end

    -- :Touch {path} - create the file and any missing parent directories in
    -- one command (mkdir -p + touch), matching eunuch's :Mkdir/:Copy pattern.
    vim.api.nvim_create_user_command('Touch', function(opts)
      local path = vim.fn.fnameescape(vim.fn.expand(opts.args))
      vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
      vim.cmd.edit(path)
    end, { nargs = 1, complete = 'file' })

    vim.api.nvim_create_user_command('CopyFileName', function()
      copy_current_file_component(':t', 'file name')
    end, { desc = 'Copy the current file name to the system clipboard' })

    vim.api.nvim_create_user_command('CopyParentDirectory', function()
      copy_current_file_component(':p:h', 'parent directory')
    end, { desc = "Copy the current file's parent directory to the system clipboard" })
  end,
}

-- Vim sugar for the UNIX shell commands that need it the most. Features include:
--
-- :Remove: Delete a file on disk without E211: File no longer available.
-- :Delete: Delete a file on disk and the buffer too.
-- :Move: Rename a buffer and the file on disk simultaneously. See also :Rename, :Copy, and :Duplicate.
-- :Chmod: Change the permissions of the current file.
-- :Mkdir: Create a directory, defaulting to the parent of the current file.
-- :Cfind: Run find and load the results into the quickfix list.
-- :Clocate: Run locate and load the results into the quickfix list.
-- :Lfind/:Llocate: Like above, but use the location list.
-- :Wall: Write every open window. Handy for kicking off tools like guard.
-- :SudoWrite: Write a privileged file with sudo.
-- :SudoEdit: Edit a privileged file with sudo.
-- Typing a shebang line causes the file type to be re-detected. Additionally the file will be automatically made executable (chmod +x) after the next write.
