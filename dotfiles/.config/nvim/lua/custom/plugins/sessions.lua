-- Session persistence and LSP memory hygiene.
-- These replace the homegrown tmux-name-keyed session autocmds (options.lua)
-- and the tmux session-hygiene sleep/wake machinery (custom/session_hygiene.lua).

return {
  -- Auto save/restore sessions, keyed by cwd + git branch.
  {
    'rmagatti/auto-session',
    lazy = false, -- must be loaded before VimEnter for auto-restore
    opts = {
      suppressed_dirs = { '~/', '~/Downloads', '/', '/tmp' },
      -- NOTE: args_allow_files_auto_save is deliberately left at its default (false).
      -- It only affects saving, never restoring, so enabling it means a throwaway
      -- `nvim foo.md` quits into a single-file save that overwrites the multi-pane
      -- layout saved by an earlier `nvim .` in the same dir. See docs/2026-09-20.

      -- Without this, "did a session restore?" has to be inferred from whether the
      -- alpha dashboard appeared, which is ambiguous when launched with file args.
      show_auto_restore_notif = true,
      -- Key sessions by cwd + branch. The branch is recomputed at save time, so the
      -- watcher below is required to keep on-screen state and the save key in sync.
      git_use_branch_name = true,
      git_auto_restore_on_branch_change = true,
    },
  },

  -- Stop LSP clients after nvim has been unfocused for grace_period seconds;
  -- restart them on FocusGained. Requires tmux `focus-events on` (already set).
  {
    'zeioth/garbage-day.nvim',
    dependencies = 'neovim/nvim-lspconfig',
    event = 'VeryLazy',
    opts = {
      grace_period = 900, -- 15 minutes unfocused before LSPs are stopped
      notifications = true,
    },
  },
}
