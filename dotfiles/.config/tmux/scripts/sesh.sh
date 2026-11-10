  #!/usr/bin/env bash
  # sesh session picker - bound to prefix+n in bindings.conf
  sesh connect "$( sesh list --icons | fzf-tmux -p 80%,70% \
	  --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
      --header '  ^a all  ^t tmux  ^x zoxide  ^o projects  ^d kill' \
      --bind 'tab:down,btab:up' \
      --bind 'ctrl-a:change-prompt(⚡)+reload(sesh list --icons)' \
      --bind 'ctrl-t:change-prompt(🪟)+reload(sesh list -t --icons)' \
      --bind 'ctrl-x:change-prompt(📁)+reload(sesh list -z --icons)' \
      --bind 'ctrl-o:change-prompt(🔎)+reload(fd -H -d 1 -t d -E .git . $HOME/Projects)' \
      --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡)+reload(sesh list --icons)' \
      --preview-window 'right:55%' \
      --preview 'sesh preview {}'
  )"
