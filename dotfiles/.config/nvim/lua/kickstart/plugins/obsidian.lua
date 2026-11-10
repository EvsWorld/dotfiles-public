return {
  'obsidian-nvim/obsidian.nvim',
  version = '*', -- Use latest release instead of latest commit
  lazy = true, -- Enable lazy loading
  ft = 'markdown', -- Only load for markdown files
  event = { 'BufReadPre *.md', 'BufNewFile *.md' }, -- Load on markdown file events
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  opts = {
    workspaces = {
      {
        name = 'personal',
        path = '~/Documents/ObsidianVault',
      },
      -- You can add multiple vaults:
      -- {
      --   name = "work",
      --   path = "~/Documents/Work",
      -- },
    },

    notes_subdir = 'inbox',
    new_notes_location = 'notes_subdir',

    link = {
      style = 'markdown',
    },

    attachments = {
      folder = 'attachments',
    },

    -- Optional: Specify how to name new notes
    note_id_func = function(title)
      -- If title is given, use it as the note ID
      -- Otherwise generate timestamp-based ID
      if title ~= nil then
        return title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
      else
        return tostring(os.time())
      end
    end,

    -- Daily notes configuration
    daily_notes = {
      folder = 'daily',
      date_format = '%Y-%m-%d',
      alias_format = '%B %-d, %Y',
      -- Optional: Use a template
      -- template = "daily-template.md",
    },

    -- Completion settings
    completion = {
      min_chars = 2, -- Trigger completion after typing 2 chars
    },

    picker = {
      name = 'telescope.nvim',
    },

    -- Keep Obsidian's conceal/highlight UI disabled.
    ui = {
      enable = false,
    },

    -- Preserve existing metadata without adding or rewriting frontmatter on save.
    frontmatter = {
      enabled = false,
    },

    -- Optional: Templates folder
    templates = {
      folder = 'templates',
      date_format = '%Y-%m-%d',
      time_format = '%H:%M',
    },

    -- Disable legacy commands (use new lowercase format)
    legacy_commands = false,

    -- Disable footer to fix "backlinks on bad self" error
    footer = {
      enabled = false,
    },
  },

  keys = {
    -- Note navigation
    { '<leader>on', '<cmd>Obsidian new<cr>', desc = '[O]bsidian [N]ew note' },
    { '<leader>oo', '<cmd>Obsidian quick_switch<cr>', desc = '[O]bsidian [O]pen note' },
    { '<leader>od', '<cmd>Obsidian dailies<cr>', desc = '[O]bsidian [D]aily notes' },
    { '<leader>ot', '<cmd>Obsidian today<cr>', desc = '[O]bsidian [T]oday' },
    { '<leader>oy', '<cmd>Obsidian yesterday<cr>', desc = '[O]bsidian [Y]esterday' },
    { '<leader>ob', '<cmd>Obsidian backlinks<cr>', desc = '[O]bsidian [B]acklinks' },
    { '<leader>ol', '<cmd>Obsidian links<cr>', desc = '[O]bsidian [L]inks' },
    { '<leader>og', '<cmd>Obsidian tags<cr>', desc = '[O]bsidian ta[G]s' },
    { '<leader>or', '<cmd>Obsidian rename<cr>', desc = '[O]bsidian [R]ename note' },
    { '<leader>om', '<cmd>Obsidian template<cr>', desc = '[O]bsidian te[M]plate' },
    { '<leader>oa', '<cmd>Obsidian open<cr>', desc = '[O]bsidian open in [A]pp' },
    -- TODO: how to exclude some things?
    {
      'gf',
      '<cmd>Obsidian follow_link<cr>',
      desc = 'Follow Obsidian link under cursor',
      ft = 'markdown',
    },
    {
      '<leader>op',
      '<cmd>Obsidian paste_img<cr>',
      desc = '[O]bsidian [P]aste image from clipboard',
    },
    {
      '<leader>oe',
      '<cmd>Obsidian extract_note<cr>',
      mode = 'v',
      desc = '[O]bsidian [E]xtract note (Create new note from visual selection)',
    },
    {
      '<leader>oi',
      '<cmd>Obsidian link<cr>',
      mode = 'v',
      desc = '[O]bsidian [I]nsert link',
    },
  },
}
