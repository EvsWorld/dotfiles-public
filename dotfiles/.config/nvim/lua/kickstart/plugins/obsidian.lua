return {
  'obsidian-nvim/obsidian.nvim',
  version = '*', -- Use latest release instead of latest commit
  lazy = true, -- Enable lazy loading
  ft = 'markdown', -- Only load for markdown files
  event = { 'BufReadPre *.md', 'BufNewFile *.md' }, -- Load on markdown file events
  dependencies = {
    'nvim-lua/plenary.nvim',
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

    -- Completion settings - works with blink-cmp
    completion = {
      nvim_cmp = false, -- Disable nvim-cmp (you're using blink)
      min_chars = 2, -- Trigger completion after typing 2 chars
    },

    -- Use telescope for pickers
    ui = {
      enable = false, -- Disable built-in UI (use Telescope instead)
    },

    frontmatter = {
      func = function(note)
        local out = { id = note.id }

        -- Add title if provided
        if note.title then
          out.title = note.title
        end

        -- Preserve aliases and tags from note object
        if note.aliases and #note.aliases > 0 then
          out.aliases = note.aliases
        end
        if note.tags and #note.tags > 0 then
          out.tags = note.tags
        end

        -- -- Only set created timestamp if it doesn't already exist (preserve existing value)
        -- if note.metadata and note.metadata.created then
        --   out.created = note.metadata.created
        -- else
        --   -- Only add created for new notes (not in Bear folder)
        --   local bear_path =
        --     vim.fn.expand '~/Documents/ObsidianVault'
        --   local note_path = tostring(note.path)
        --   if not note_path:match('^' .. bear_path) then
        --     out.created = os.date '%Y-%m-%d %H:%M'
        --   end
        -- end

        -- Preserve all other metadata fields
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            -- Don't override fields we've already explicitly set
            if k ~= 'created' and k ~= 'title' then
              out[k] = v
            end
          end
        end

        return out
      end,
    },

    -- Optional: Configure note frontmatter
    -- Disable frontmatter handling to prevent modifying existing notes
    -- disable_frontmatter = true,

    -- Optional: Templates folder
    templates = {
      folder = 'templates',
      date_format = '%Y-%m-%d',
      time_format = '%H:%M',
    },

    -- Follow link behavior
    follow_url_func = function(url)
      -- Open URLs in default browser
      vim.fn.jobstart { 'open', url }
    end,

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
    { '<leader>oo', '<cmd>Obsidian quick-switch<cr>', desc = '[O]bsidian [O]pen note' },
    -- { '<leader>os', '<cmd>Obsidian search<cr>', desc = '[O]bsidian [S]earch' },
    { '<leader>so', '<cmd>Obsidian search<cr>', desc = '[O]bsidian [S]earch' },
    { '<leader>ot', '<cmd>Obsidian today<cr>', desc = '[O]bsidian [T]oday' },
    { '<leader>oy', '<cmd>Obsidian yesterday<cr>', desc = '[O]bsidian [Y]esterday' },
    { '<leader>ob', '<cmd>Obsidian backlinks<cr>', desc = '[O]bsidian [B]acklinks' },
    { '<leader>ol', '<cmd>Obsidian links<cr>', desc = '[O]bsidian [L]inks' },
    -- TODO: how to search by tags?
    -- TODO: how to exclude some things?
    {
      'gf',
      '<cmd>Obsidian follow<cr>',
      desc = 'Follow Obsidian link under cursor',
      ft = 'markdown',
    },
    {
      '<leader>op',
      '<cmd>Obsidian paste-img<cr>',
      desc = '[O]bsidian [P]aste image from clipboard',
    },
    {
      '<leader>oe',
      '<cmd>Obsidian extract-note<cr>',
      mode = 'v',
      desc = '[O]bsidian [E]xtract note (Create new note from visual selection)',
    },
    {
      '<leader>oi',
      '<cmd>Obsidian link<cr>',
      mode = 'v',
      desc = '[O]bsidian [I]nsert link',
    },
    -- TODO: make this work
    -- {
    --   '<leader>oa',
    --   function()
    --     local filepath = vim.fn.expand '%:p'
    --     vim.fn.jobstart { 'open', '-a', 'Obsidian', filepath }
    --   end,
    --   desc = '[O]bsidian open in [A]pp',
    --   ft = 'markdown',
    -- },
  },
}
