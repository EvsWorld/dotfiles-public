# ***** python *****
# alias scce='source venv/bin/activate'

# TODO: consider running/using sysreset on a schedule or when certain
# conditions are met (like high memory usage or too many tmux sessions). could
# be a cron job that runs every hour or so, or a function that checks memory
# and tmux sessions and prompts to reset if thresholds are exceeded.

pre-heavy() {   # check memory state before running heavy tasks (ghostty, tmux, nvim)
    echo "=== Current Memory State ==="
    echo "Ghostty: $(ps -o rss= -p $(pgrep Ghostty) 2>/dev/null | awk '{sum+=$1} END {print sum/1024}')MB"
    echo "Gemini: $(ps -o rss= -p $(pgrep -i gemini) 2>/dev/null | awk '{sum+=$1} END {print sum/1024}')MB"
    echo "Tmux sessions: $(tmux ls 2>/dev/null | wc -l)"
    echo "Nvim instances: $(pgrep nvim | wc -l)"
    echo "==========================="
}

# Warn on startup if tmux sessions are excessive or unhealthy
_tmux_startup_check() {
    # Guard against double-sourcing (oh-my-zsh + explicit source in .zshrc)
    (( ${_TMUX_CHECK_RAN:-0} )) && return
    _TMUX_CHECK_RAN=1

    # Inside a pane you already know you are in tmux, and the shell that
    # started the server has normally shown this warning already. Panes are the
    # common case, so returning here keeps the cost off most shells entirely.
    [[ -n "$TMUX" ]] && return

    # One tmux call supplies all three numbers. This used to make four
    # subprocesses: `tmux ls`, `list-panes -a`, `tmux ls` again, and
    # `list-panes -a -F pane_dead`. The second `tmux ls` fed an `extras`
    # counter whose only consumer was a commented-out echo, so it ran purely
    # to produce a value that was always discarded.
    local -a panes names dead
    panes=( ${(f)"$(tmux list-panes -a -F '#{session_name} #{pane_dead}' 2>/dev/null)"} )
    (( $#panes )) || return

    names=( ${(u)${panes%% *}} )   # unique session names
    dead=( ${(M)panes:#* 1} )      # panes whose pane_dead flag is 1

    local session_count=$#names pane_count=$#panes dead_panes=$#dead

    [[ $session_count -le 10 && $pane_count -le 40 ]] && return

    [[ $session_count -gt 10 ]] && echo "🚨 $session_count tmux sessions active."
    [[ $pane_count -gt 40 ]] && echo "🚨 $pane_count tmux panes open — consider running tmux-prune."
    [[ $dead_panes -gt 0 ]] && echo "  ↳ ⚠️  $dead_panes dead pane(s) — a process may have crashed"
}
_tmux_startup_check

# Kill non-core tmux sessions interactively (fzf multi-select)
# Core sessions (ConfigGeneral, Nvim, tmux, Claude) are pre-filtered out.
# Usage: tmux-prune
tmux-prune() {   # kill non-core tmux sessions interactively (fzf, cleanup)
  local -a core_sessions=(ConfigGeneral Nvim tmux Claude)
  local core_pattern
  core_pattern=$(IFS='|'; echo "${core_sessions[*]}")

  local selected
  selected=$(tmux list-sessions -F '#{session_name}: #{session_windows}w / #{session_attached} attached' 2>/dev/null \
    | grep -vE "^(${core_pattern}):" \
    | fzf --multi --prompt="Kill sessions (TAB to multi-select): " --height=40% --reverse)

  [[ -z "$selected" ]] && return 0

  echo "$selected" | awk -F: '{print $1}' | while read -r name; do
    tmux kill-session -t "$name" && echo "Killed: $name"
  done
}

# Kill all nvim processes whose parent shell is dead (PPID=1 = reparented to launchd)
# These are the orphans that accumulate after closing panes without exiting nvim.
nvim-prune() {   # kill orphaned nvim processes (cleanup, memory)
  local orphans
  orphans=$(ps -eo pid=,ppid=,comm= | awk '$3~/^n?vim/ && $2==1 {print $1}')
  if [[ -z "$orphans" ]]; then
    echo "No orphaned nvim processes found."
    return 0
  fi
  local count
  count=$(echo "$orphans" | wc -l | tr -d ' ')
  echo "Found $count orphaned nvim process(es) (PPID=1):"
  ps -p $(echo "$orphans" | paste -sd,) -o pid,rss,comm 2>/dev/null
  echo ""
  read -rk1 "REPLY?Kill all $count? [y/N] "
  echo ""
  [[ "$REPLY" =~ ^[Yy]$ ]] && echo "$orphans" | xargs kill && echo "Done."
}

# Close every tmux-agent-sidebar pane. Each open sidebar polls once a second by
# forking tmux/git/lsof, even in hidden windows, and the forks queue on the
# single-threaded tmux server until redraws lag. Agent panes are untouched;
# reopen a sidebar with prefix f. Runbook: ~/.config/tmux/docs/TROUBLESHOOTING.md
# Usage: sidebar-prune
sidebar-prune() {   # close all agent-sidebar panes (fixes tmux redraw lag)
  local -a sidebars
  # pane_current_command truncates to 15 chars, so match the truncated name.
  sidebars=( ${(f)"$(tmux list-panes -a -F '#{pane_current_command} #{pane_id} #{session_name}:#{window_index}' 2>/dev/null \
    | awk '$1=="tmux-agent-side" {print $2, $3}')"} )
  if (( ${#sidebars} == 0 )); then
    echo "No agent sidebars open."
    return 0
  fi
  local entry
  for entry in $sidebars; do
    tmux kill-pane -t "${entry%% *}" && echo "Closed sidebar in ${entry#* }"
  done
}

# Kill git-over-SSH fetches stuck for more than 5 minutes. Lazygit fetches in
# the background every 60s; if the Mac sleeps mid-connection, ssh can wait
# forever and lazygit spins "Fetching" at 20fps into tmux, lagging redraws.
# Killing the ssh makes the fetch fail cleanly (fetches are read-only).
# Pushes (git-receive-pack) are spared; a clone over 5 minutes would be caught.
# Runbook: ~/.config/tmux/docs/TROUBLESHOOTING.md
# Usage: fetch-prune
fetch-prune() {   # kill git fetches stuck >5m (fixes lazygit "Fetching" lag)
  local stuck
  stuck=$(ps -Ao pid=,etime=,command= | awk '
    /[g]it-upload-pack/ {
      e = $2; d = 0
      if (e ~ /-/) { split(e, p, "-"); d = p[1]; e = p[2] }
      n = split(e, t, ":")
      s = d * 86400 + (n == 3 ? t[1] * 3600 + t[2] * 60 + t[3] : t[1] * 60 + t[2])
      if (s > 300) print $1, $2, $NF
    }')
  if [[ -z "$stuck" ]]; then
    echo "No stuck git fetches."
    return 0
  fi
  local pid age repo
  echo "$stuck" | while read -r pid age repo; do
    kill "$pid" && echo "Killed fetch of $repo (stuck $age)"
  done
}

# One command for the tmux redraw-lag symptom: runs the fix for every known
# cause, so you don't have to work out which one it is first.
# Usage: unlag
unlag() {   # fix tmux redraw lag: close agent sidebars, kill stuck git fetches
  sidebar-prune
  fetch-prune
}

tmux-sessions() {   # list tmux sessions, highlighting non-core project sessions
    tmux ls 2>/dev/null || { echo "No tmux sessions running."; return 0; }

    local -a core_sessions=(ConfigGeneral Nvim tmux Claude)
    local -a extras=()

    while IFS= read -r line; do
        local name="${line%%:*}"
        local is_core=false
        for k in "${core_sessions[@]}"; do
            [[ "$name" == "$k" ]] && is_core=true && break
        done
        [[ "$is_core" == false ]] && extras+=("$name")
    done < <(tmux ls)

    if [[ ${#extras[@]} -gt 0 ]]; then
        print "\nProject sessions: ${extras[*]}"
    fi
}


sl() {   # fzf shell definition/script search -> jump to source in nvim
  local -a shell_files=(
    "$HOME/.config/oh-my-zsh/custom/aliases.zsh"
    "$HOME/.zshrc"
    "$HOME/.oh-my-zsh/plugins/git/git.plugin.zsh"
  )
  local -a script_roots=(
    "$HOME/scripts"
    "$HOME"/Projects/*/bin(N/)
  )

  local selection file line
  selection=$(
    {
      for file in "${shell_files[@]}"; do
        [[ -r "$file" ]] || continue
        perl -ne '
          next if /^\s*#/;
          chomp(my $source = $_);
          if (/^\s*alias\s+([^=\s]+)=/) {
            printf "alias    %-28s %s\t%s\t%d\n", $1, $source, $ARGV, $.;
          } elsif (/^\s*function\s+([A-Za-z_][A-Za-z0-9_-]*)\s*(?:\(\))?\s*\{/) {
            printf "function %-28s %s\t%s\t%d\n", $1, $source, $ARGV, $.;
          } elsif (/^\s*([A-Za-z_][A-Za-z0-9_-]*)\s*\(\)\s*\{/) {
            printf "function %-28s %s\t%s\t%d\n", $1, $source, $ARGV, $.;
          }
        ' "$file"
      done

      find "${script_roots[@]}" -type f -perm +111 \
        -not -path '*/node_modules/*' -not -path '*/venv/*' -not -path '*/.venv/*' \
        -not -path '*/archive/*' -not -path '*/.git/*' -print0 2>/dev/null |
        while IFS= read -r -d '' file; do
          local source_path="${file:A}"
          printf "script   %-28s %s\t%s\t1\n" "${file:t}" "$file" "$source_path"
        done
    } | fzf --height 50% --reverse --border --prompt="Shell source: " --delimiter=$'\t' --with-nth=1
  )
  [[ -z "$selection" ]] && return 0

  local -a fields=("${(@ps:\t:)selection}")
  file="${fields[2]}"
  line="${fields[3]}"
  echo "Found: $file:$line"
  nvim +"$line" "$file"
}

# fzf keybinding search → jump to definition in nvim
# Searches across Neovim, Tmux, and Ghostty keybindings
# Usage: skb
#   - Opens FZF to search all keybindings
#   - Select a keybinding to jump to its definition in nvim
#   - If definition not found, copies keybinding to clipboard
skb() {   # fzf keybinding search across nvim, tmux, ghostty -> jump to definition
  # Parse Neovim keybindings from keyremaps.lua
  _skb_parse_nvim() {
    local file="$HOME/.config/nvim/lua/keyremaps.lua"
    [[ ! -f "$file" ]] && return

    # Use perl for more reliable parsing of vim.keymap.set() calls
    perl -ne '
      if (/vim\.keymap\.set\((.*)\)/) {
        my $params = $1;

        # Extract mode (first param - can be string or table)
        my $mode = "";
        if ($params =~ /^\s*[\{\[]\s*[\x27"]([^\x27"\}]+)[\x27"]/) {
          $mode = $1;
          $mode =~ s/[\x27",\s]+//g;  # Clean up multi-mode
        } elsif ($params =~ /^\s*[\x27"]([^\x27"]+)[\x27"]/) {
          $mode = $1;
        }

        # Extract key (second param)
        my $key = "";
        if ($params =~ /,\s*[\x27"]([^\x27"]+)[\x27"]/) {
          $key = $1;
        }

        # Extract action (third param - string or function)
        my $action = "";
        if ($params =~ /,\s*[\x27"]([^\x27"]+)[\x27"]\s*,\s*[\x27"]([^\x27"]+)[\x27"]/) {
          $action = $2;
        } elsif ($params =~ /,\s*[\x27"]([^\x27"]+)[\x27"]\s*,\s*function/) {
          $action = "function()";
        } elsif ($params =~ /,\s*[\x27"]([^\x27"]+)[\x27"]\s*,\s*[\x27"]([^\x27"]+)[\x27"]/) {
          $action = $1;  # Sometimes the action is the second string param
        }

        # Extract description
        my $desc = "";
        if ($params =~ /desc\s*=\s*[\x27"]([^\x27"]+)[\x27"]/) {
          $desc = $1;
        }

        # Print if we have mode and key
        if ($mode && $key) {
          printf "nvim     | %-15s | %-20s → %-15s | %s\n", $mode, $key, $action, $desc;
        }
      }
    ' "$file"
  }

  # Parse Tmux keybindings (all bindings live in bindings.conf)
  _skb_parse_tmux() {
    local files=("$HOME/.config/tmux/bindings.conf")

    for file in "${files[@]}"; do
      [[ ! -f "$file" ]] && continue

      # Extract bind and bind-key lines, skip comments and unbind
      grep -E "^[[:space:]]*bind(-key)?" "$file" | grep -v "^#" | grep -v "unbind" | while read -r line; do
        # Determine context (key table)
        local context="prefix"
        if echo "$line" | grep -q -- "-n "; then
          context="root"
        elif echo "$line" | grep -q -- "-T"; then
          context=$(echo "$line" | sed -n 's/.*-T[[:space:]]*\([^[:space:]]*\).*/\1/p')
        fi

        # Remove bind command and options to get key and action
        local rest=$(echo "$line" | sed -E 's/^[[:space:]]*bind(-key)?[[:space:]]*(-[nT][[:space:]]+[^[:space:]]+[[:space:]]*)?//')

        # Extract key (first token) and action (rest)
        local key=$(echo "$rest" | awk '{print $1}')
        local action=$(echo "$rest" | cut -d' ' -f2-)

        # Format key modifiers
        key=$(echo "$key" | sed 's/^C-/Ctrl+/; s/^M-/Alt+/')

        [[ -n "$key" ]] && printf "tmux     | %-15s | %-20s → %s\n" "$context" "$key" "$action"
      done
    done
  }

  # Parse Ghostty keybindings
  _skb_parse_ghostty() {
    local file="$HOME/.config/ghostty/config"
    [[ ! -f "$file" ]] && return

    # Extract keybind lines (simple format: keybind = key=action)
    grep "^keybind" "$file" | while read -r line; do
      # Remove "keybind = " prefix
      local binding=$(echo "$line" | sed 's/^keybind[[:space:]]*=[[:space:]]*//')

      # Check for global prefix
      local context=""
      if echo "$binding" | grep -q "^global:"; then
        context="global"
        binding=$(echo "$binding" | sed 's/^global://')
      fi

      # Split on = to get key and action
      local key=$(echo "$binding" | cut -d'=' -f1)
      local action=$(echo "$binding" | cut -d'=' -f2-)

      [[ -n "$key" ]] && printf "ghostty  | %-15s | %-20s → %s\n" "$context" "$key" "$action"
    done
  }

  # Search for keybinding definition in a file
  _skb_search_and_open() {
    local file="$1"
    local key="$2"
    local escaped_key line match

    # Escape special regex characters in the key
    escaped_key=$(echo "$key" | sed 's/[]\/$*.^[]/\\&/g')

    # Search for the keybinding definition
    match=$(grep -n "$escaped_key" "$file" 2>/dev/null | head -1)

    if [[ -n "$match" ]]; then
      line="${match%%:*}"
      echo "Found: $file:$line"
      nvim +"$line" "$file"
      return 0
    fi
    return 1
  }

  # Main function
  local all_bindings selection tool context key

  # Collect all keybindings
  all_bindings=$(_skb_parse_nvim; _skb_parse_tmux; _skb_parse_ghostty)

  # Let user select with fzf
  selection=$(echo "$all_bindings" | fzf --height 50% --reverse --border --prompt="Keybinding: " --delimiter ' | ')

  [[ -z "$selection" ]] && return 0

  # Extract tool, context, and key from selection
  tool=$(echo "$selection" | cut -d'|' -f1 | xargs)
  key=$(echo "$selection" | cut -d'|' -f3 | cut -d'→' -f1 | xargs)

  # Search for definition in appropriate file(s)
  local found=false
  case "$tool" in
    nvim)
      if _skb_search_and_open "$HOME/.config/nvim/lua/keyremaps.lua" "$key"; then
        found=true
      fi
      ;;
    tmux)
      # All tmux keybindings live in bindings.conf
      if _skb_search_and_open "$HOME/.config/tmux/bindings.conf" "$key"; then
        found=true
      fi
      ;;
    ghostty)
      if _skb_search_and_open "$HOME/.config/ghostty/config" "$key"; then
        found=true
      fi
      ;;
  esac

  # Fallback: copy to clipboard if not found
  if [[ "$found" == false ]]; then
    echo "$selection" | pbcopy
    echo "Definition not found in source files. Keybinding copied to clipboard."
  fi
}

# search available make commands in current project
# TODO:make this look recursively up for Makefile? right now i get thhis error if im not
# in the current dir where the Makefile is:
# 30 18:19➜scripts(feature/test-zip-upload)✗ m
# grep: Makefile: No such file or directory
# >
#   0/0 ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#   Select make target

 m() {   # fzf search make targets in Makefile and run (build)
      local target
      target=$(grep -E '^[a-zA-Z_-]+:.*?## .*$' Makefile | \
        sort | \
        awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $1,
    $2}' | \
        fzf --ansi --height 40% --reverse --header "Select make target" | \
        awk '{print $1}')

      if [[ -n "$target" ]]; then
        make "$target"
      fi
    }

# *********** pgadmin *********************
alias pgadmin='docker run \
  -p 5050:80 \
  -e "PGADMIN_DEFAULT_EMAIL=name@example.com" \
  -e "PGADMIN_DEFAULT_PASSWORD=admin" \
  -d dpage/pgadmin4'


# ***** Tmux + Vim session management ***************
alias tmux='tmux -f $TMUX_CONF'       # tmux with custom config file
alias tmnew='tmux new-session -s'    # Create new tmux session: tnew project-name
alias tmls='tmux list-sessions'       # List all tmux sessions
alias tmatt='tmux attach-session -t'  # Attach to session: tatt session-name
alias tmkill='tmux kill-session -t'   # Kill session: tkill session-name
# TODO: alias for detach/kill current session (ie Stop being in tmux and just convert the
# current ghostty terminal window to be a non-tmux terminal instance)

alias tms="~/.config/tmux/scripts/tmux-sessionizer"   # tmux sessionizer (fzf project session switcher)
# alias tmw="~/.config/tmux/scripts/tmux-windowizer.sh"

# Project session shortcuts
# TODO:  tmux session for editing .config files
# It should save the vim session info to a vim session file called "Config.vim"
alias session-config='tmux new-session -s config -c ~/.config \; split-window -v -c ~/.config \; select-pane -t 0'   # tmux session for editing ~/.config
# TODO:  tmux session for writing scripts
# It Should save the vim session info to a vim session file called "Scratch.vim"
alias session-scratch='tmux new-session -s scratch -c ~/scratch'   # tmux session in ~/scratch
# TODO:  tmux session for writing scripts.
# It Should save the vim session info to a vim session file called "Scripts.vim"
alias session-scripts='tmux new-session -s scripts -c ~/scripts'   # tmux session in ~/scripts
# TODO:  tmux session for configuring tmux and nvim. It should:
# - [ ] save the vim session info to a vim session file called "TmuxAndVim.vim"
# - [ ]  open an existing session by the name "tmux-vim" if it exists
# - [ ] If it doesnt exist, it should create it
alias session-tmux-vim='if tmux has-session -t tmux-vim 2>/dev/null; then
    tmux attach-session -t tmux-vim
else
    mkdir -p ~/.config/sessions
    tmux new-session -s tmux-vim -c ~/.config \; \
    split-window -v -c ~/.config \; \
    select-pane -t 0 \; \
    send-keys "nvim -S ~/.config/sessions/TmuxAndVim.vim 2>/dev/null || nvim -c \":mksession ~/.config/sessions/TmuxAndVim.vim\"" Enter
fi'
# *********** End Tmux + Vim session management ***************

# ************** Misc *****************************
alias mkdir='mkdir -pv'   # create parent directories by default, verbose

# Show the three most recently active visible applications, front-to-back.
recent-apps() {
    /usr/bin/lsappinfo visibleProcessList \
        | sed -n 's/.*: "\([^"]*\)".*/\1/p' \
        | tr '_' ' ' \
        | head -n 3
}

mcd() {   # make directory and move into it (mkdir, cd, folder)
    if [ -z "$1" ]; then
        echo "Error: No directory name provided."
        return 1
    fi
    mkdir -p "$1" && builtin cd -- "$1"
}
# ************** End Misc *************************

# ******* Programs ********
alias vimp='NVIM_APPNAME="nvim-theprimeagen" nvim'   # nvim with theprimeagen config
alias vm=nvim                          # nvim
alias vim=nvim                         # nvim

alias cc='claude'
alias ccr='claude --resume'   # claude plan mode, resume session
alias cci='CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 claude'  # claude session w/ memory off

alias gmm='gemini'                     # gemini
# alias oca='opencode'                   # opencode
# alias occ='opencode --pure -c'         # opencode pure, continue last session
# alias oc='opencode --pure'             # opencode pure
alias co='codex'                       # codex
alias cor='codex resume'               # codex resume session

coi() {  # codex session w/ memory off
    codex \
      -c memories.generate_memories=false \
      -c memories.use_memories=false \
      "$@"
}

cojobsearch() {   # codex in personal-project project (hermes dirs included)
  codex \
    --cd $HOME/Projects/personal-project \
    --add-dir $HOME/Projects/hermes \
    --add-dir $HOME/.hermes-docker \
    --add-dir $HOME/Projects/hermes-email-intake \
    --add-dir $HOME/Projects/learning \
    "$@"
}

cohermescox() {   # codex in hermes project (personal-project dirs included)
  codex \
    --cd $HOME/Projects/hermes \
    --add-dir $HOME/.hermes-docker \
    --add-dir $HOME/Projects/hermes-email-intake \
    --add-dir $HOME/Projects/house-project \
    "$@"
}

cohermes() {   # codex in hermes project (personal-project dirs included)
  codex \
    --cd $HOME/Projects/hermes \
    --add-dir $HOME/.hermes-docker \
    --add-dir $HOME/Projects/personal-project \
    --add-dir $HOME/Projects/hermes-email-intake \
    --add-dir $HOME/Projects/house-project \
    --add-dir $HOME/Projects/learning \
    "$@"
}

cosecondbrain()  { # codex with all second brain dirs
  codex \
    --cd $HOME/Projects/storage-strategy \
    --add-dir $HOME/.hermes-docker \
    --add-dir $HOME/Projects/hermes \
    --add-dir $HOME/Projects/things-migration-data \
    --add-dir $HOME/Projects/obsidian/ \
    "$@"
}

alias gy='agy'   # antigravity

# ********* Hermes **************

# Hermes: the Dockerized container is the only install (the native ~/.hermes was deleted).
# Bare `hermes` (and `he`/`jsh`) route into the `hermes` container. TTY-aware so interactive
# sessions get -it while `-z`/piped use still works.
hermes() {   # run hermes CLI in docker container (chat, ai)
  local -a tty
  [ -t 0 ] && tty=(-it)
  $HOME/.orbstack/bin/docker exec $tty hermes hermes "$@"
}

alias hh='hermes'                      # hermes shortcut
alias hhjob='hermes -p personal-project chat'  # hermes personal-project chat
alias hhjobr='hermes sessions list -p personal-project'  # list hermes personal-project sessions
alias hhjobz='hermes -p personal-project -z'    # hermes personal-project headless one-shot: hhjobz "triage <url>"
alias hhlearn='hermes -p learning chat'    # hermes learning chat
alias hhjlearnr='hermes sessions list -p learning'  # list hermes learning sessions
alias hhcox='hermes -p cox-ave chat'     # hermes cox-ave chat
alias hhcoxz='hermes -p cox-ave -z'     # hermes cox-ave headless one-shot

# ********* Hermes End **************

# ********** Programs End **************


# ******* Utility ********
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
alias jb='popd'                        # go back in directory stack (popd) (like my old bk, but feels more like zoxide j command)
alias flip='pushd'                     # swap to previous directory (pushd)
alias clc='clear'                        # clear screen
# TODO: make this output an error if theres a problem.
# TODO: how to speed up starting new terminal
alias rp='source ~/.zshrc'   # Reloads profile
alias rj='source ~/.zshrc'   # Reloads profile
# ******* End Utility ********

# ********* Searching/Finding/Grepping ************
alias histgrep='history | grep'   # grep shell history

ffv() { local f="$(fzf)"; [[ -n "$f" ]] && realpath "$f" | pbcopy && nvim "$f" }   # fzf file, copy path, open in nvim
fcp() { local f="$(fzf)"; [[ -n "$f" ]] && realpath "$f" | pbcopy }   # fzf file, copy full path to clipboard

# Fuzzy-find and edit any script from ~/scripts or ~/Projects/*/bin
# Usage: editscript         → opens fzf with all scripts
#        editscript sys     → pre-fills "sys" in fzf search
editscript() {   # fzf find and edit script from ~/scripts or Projects/*/bin
  local match
  match=$(find ~/scripts ~/Projects/*/bin -type f -perm +111 \
    -not -path '*/node_modules/*' -not -path '*/venv/*' -not -path '*/.venv/*' \
    -not -path '*/archive/*' -not -path '*/.git/*' 2>/dev/null | \
    fzf --query="$1" --select-1 --exit-0 --preview 'head -40 {}')
  [[ -n "$match" ]] && ${EDITOR:-vim} "$match"
}

# TODO hook up to control+r
ffhist() {   # fzf search shell history and run selection
  eval $(fc -l 1 | fzf --tac | sed 's/ *[0-9]* *//')
}

# ********* Searching/Finding/Grepping ************

# *************** Edit/Go To ***************************

scratchn() { command mkdir -p "$HOME/Projects/scratch" && ${EDITOR:-nvim} "$HOME/Projects/scratch/$(date +%Y-%m-%d-%H%M)-scratch.txt"; } # Scratch with time: edit/go to/open a new timestamped scratch note.
# Delegates to the TmuxLauncher app (~/Projects/nvim-in-ghostty), which
# reuses the single `scratch` tmux window. scratchn stays local on purpose: its
# file is timestamped but the launcher's window name is not.
scratchp() { /usr/bin/open 'tmuxlauncher://launch/sp'; }   # edit/go to/open the reusable scratch note

# Delegates to the TmuxLauncher app (~/Projects/nvim-in-ghostty), matching
# the Alfred "on" keyword's Run Script. Naming the note here rather than inside
# Neovim means it is created already titled, in its own tmux window.
# Usage: vmon Grocery List   → uses the arguments as the title
#        vmon                → prompts; empty input falls back to :Obsidian new

vmon() {  # Open a new note in the personal Obsidian vault
  local title encoded
  if (( $# )); then
    title="$*"
  else
    read -r "title?Note title: "
  fi
  encoded=$(/usr/bin/python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$title")
  /usr/bin/open "tmuxlauncher://launch/on?title=$encoded"
}

# Opens today's obsidian daily note directly in the current terminal's
# Neovim session (unlike vmot, which routes through a dedicated tmux window).
vmotn() {
  /opt/homebrew/bin/nvim --cmd 'let g:auto_session_enabled = v:false' \
    -c "silent lua require('lazy').load({ plugins = { 'obsidian.nvim' } })" \
    -c 'silent Obsidian workspace personal' \
    -c 'silent Obsidian today' \
    -c 'silent lua vim.schedule(function() vim.cmd("normal! G") end)'
}

vmonn() {  # Opens a new obsidian note directly in the current terminal's Neovim session (unlike vmon, which routes through a dedicated tmux window).
  local title createNote
  if (( $# )); then
    title="$*"
  else
    read -r "title?Note title: "
  fi
  if [[ -n "$title" ]]; then
    createNote="silent Obsidian new $title"
  else
    createNote="silent Obsidian new"
  fi
  /opt/homebrew/bin/nvim --cmd 'let g:auto_session_enabled = v:false' \
    -c "silent lua require('lazy').load({ plugins = { 'obsidian.nvim' } })" \
    -c 'silent Obsidian workspace personal' \
    -c "$createNote"
}

# Delegates to the TmuxLauncher app so the Alfred keyword and this
# function share one definition of "open today's note" (~/Projects/nvim-in-ghostty).
# Opens/reuses the dated obsidian-today tmux window rather than this pane.
vmot() {  # Open the obsidian today note in the personal Obsidian vault
  /usr/bin/open 'tmuxlauncher://launch/ot'
}

alias jv='cd "$HOME/Documents/ObsidianVault"'  # jump to the personal Obsidian vault

# Delegates to the TmuxLauncher app so the Alfred keyword and these functions
# share one definition of "open Telescope" (~/Projects/nvim-in-ghostty).
# With no argument, reuses the dedicated telescope-find-files/telescope-live-grep
# window. With an argument, always opens a new window prefilled with the query.
ff() {  # Open Telescope find_files, rooted in the current directory
  if [[ $# -eq 0 ]]; then
    /usr/bin/open 'tmuxlauncher://launch/ff'
  else
    local encoded
    encoded=$(/usr/bin/python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$*")
    /usr/bin/open "tmuxlauncher://launch/ff?query=$encoded"
  fi
}

ss() {  # Open Telescope live_grep, rooted in the current directory
  if [[ $# -eq 0 ]]; then
    /usr/bin/open 'tmuxlauncher://launch/ss'
  else
    local encoded
    encoded=$(/usr/bin/python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$*")
    /usr/bin/open "tmuxlauncher://launch/ss?query=$encoded"
  fi
}


# ******  Edit files  *************************
alias editzsh='nvim ~/.zshrc'          # edit/go to ~/.zshrc
alias editgitignore='nvim ~/.gitignore'   # edit/go to ~/.gitignore
alias editgitconfig='nvim ~/.gitconfig'   # edit/go to ~/.gitconfig
alias editaliases='nvim ~/.config/oh-my-zsh/custom/aliases.zsh'   # edit/go to custom aliases (this file)
alias editkarabiner='nvim ~/.config/karabiner.edn'                             # edit/go to karabiner.edn
alias editaliasesdefault='nvim ~/.oh-my-zsh/plugins/git/git.plugin.zsh ~/.oh-my-zsh/plugins/git/README.md ~/.oh-my-zsh/custom/aliases.zsh'   # edit/go to oh-my-zsh git plugin aliases
alias editvim='nvim ~/.config/nvim'   # edit/go to nvim config
alias editka='nvim ~/.config/karabiner.edn'   # edit/go to karabiner.edn (keyboard remaps)
alias editgitignorecfg='nvim ~/.cfg/todo'     # edit/go to cfg bare repo todo file
alias editgitconfigcfg='nvim ~/.cfg/config'   # edit/go to cfg bare repo git config
alias editsuperwhisper='nvim ~/Documents/superwhisper/settings/vocabulary.json'   # edit/go to superwhisper  speech to text vocabulary
unalias edithandy 2>/dev/null
edithandy() {
  nvim '+/custom_words' '$HOME/Library/Application Support/com.pais.handy/settings_store.json'
} # edit/go to Handy speech-to-text vocabulary
alias editstt='edithandy'   # edit/go to speech to text settings/vocabulary
# ******  End Edit/Go To files  *************************

# *************** Viewing/status related ************************
alias hist100='history | tail -n 100'  # last 100 history entries
alias hist40='history | tail -n 40'    # last 40 history entries
alias loghistory='grep "$(date +%Y-%m-%d)" ~/.claude/session_history.log'   # view today's response logs (Claude + Codex)
alias logsessions='grep "$(date +%Y-%m-%d)" ~/.claude/session_end.log'   # view today's session end logs (Claude + Codex)

# Process monitoring
alias hbad="HTOPRC=~/.config/htop/htoprc-bad htop"        # htop with bad-procs profile
alias list-bad-procs="~/.config/scripts/list-bad-procs.sh"   # list problem processes
alias hmem="HTOPRC=~/.config/htop/htoprc-memory htop"     # htop with memory profile
alias horph="HTOPRC=~/.config/htop/htoprc-orphans htop"   # htop with orphans profile
# alias showorph="~/scripts/run_htop_and_orphans.sh"

thidden() {   # toggle hidden files in Finder (show, hide, defaults)
    # Get the current setting
    current_setting=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null)
    if [ "$current_setting" = "1" ]; then
        # Hide hidden files
        defaults write com.apple.finder AppleShowAllFiles -bool FALSE
        echo "Hidden files are now hidden."
    else
        # Show hidden files
        defaults write com.apple.finder AppleShowAllFiles -bool TRUE
        echo "Hidden files are now visible."
    fi
    # Restart Finder to apply changes
    killall Finder
}

ej() {   # eject the Extreme SSD and the Time Machine drive; refuses mid-backup
    if tmutil status 2>/dev/null | grep -q 'Running = 1'; then
        echo "Time Machine is backing up; not ejecting. Check: tmutil status"
        return 1
    fi
    local vol
    for vol in /Volumes/Extreme_SSD /Volumes/seagate-1-tb; do
        if [[ -d $vol ]]; then
            [[ $PWD == $vol || $PWD == $vol/* ]] && cd ~
            diskutil eject "$vol"
        else
            echo "Not mounted: $vol"
        fi
    done
}

# Shows folders first and in color. required I run ""> brew install coreutils" first
# alias ls='/usr/local/bin/gls --color -h --group-directories-first'
## Use a long listing format ##
alias lp='ls -lAhog'                   # long listing, compact
alias ll='eza -a --long --no-permissions --no-user --time modified --icons --time-style=relative'   # eza long listing with icons
alias ftree='tree -v -L 2 --charset utf-8 --filelimit 400'   # tree view, 2 levels
alias cp='cp -i'                       # cp with overwrite confirm
alias ln='ln -i'                       # ln with overwrite confirm
alias lsl='ls -1hFA | less'            # list files piped to less
alias pwdc='pwd|pbcopy'                # copy current path to clipboard
# ***************End Viewing/status related ******************************

alias pp='pnpm'                        # pnpm


# ************************************************************
# ************************* git ******************************
# ************************************************************

alias gsll='lazygit'      # git status lazygit
alias csll="lazygit --git-dir=$HOME/.cfg --work-tree=$HOME"    # cfg git status lazygit bare repo dotfiles

alias ldd='lazydocker'

#  TODO: move all these to the git.plugin.zsh file?
# and just delete the existing aliases instead of unaliasing them??

alias gtag="git tag | sort -V"         # git tags sorted by version

unalias gcm 2>/dev/null
# TODO: assign gcm to something?
alias gcm='git commit -m'

alias gcom='git checkout $(git_main_branch)'   # git checkout main branch

unalias gcm! 2>/dev/null
alias gcm!='git commit --amend -m'     # git amend last commit with new message

unalias gcam! 2>/dev/null
alias gcam!='git add -A && git commit --amend -m'   # git add all + amend with new message

unalias gcam 2>/dev/null
alias gcam='git add -A && git commit -m'   # git add all + commit with message

# these cant be fundtions so will accept options at the end like -n
unalias gcan! 2>/dev/null
# TODO: QUESTION: remove the add all?
alias gcan!='git add -A && git commit --verbose --all --no-edit --amend'   # git add all + amend, keep message

# # git
#
unalias glog 2>/dev/null

unalias gca 2>/dev/null
alias gca='git add -A && git commit --verbose --all'   # git add all + commit verbose

unalias gca! 2>/dev/null
alias gca!='git add -A && git commit --verbose --all --amend'   # git add all + amend verbose

# Unalias the commands if they exist to avoid conflicts
unalias gs 2>/dev/null
unalias gss 2>/dev/null
unalias g: 2>/dev/null
unalias gloc 2>/dev/null
unalias glo 2>/dev/null
unalias gst 2>/dev/null

gstt() {   # git stash changes
echo "+ git stash (Stash changes)"
echo ""
git stash
}

gs() {   # git status short
    echo "+ git status --short (Show git status in short format)"
    echo ""
    git status --short
}

gss() {   # git status full
    echo "+ git status (Show git status)"
    echo ""
    git status
}

g:() {   # git checkout - (switch to previous branch)
    echo "+ git checkout - (Switch to the previous branch)"
    echo ""
    git checkout -
}


# ******* glog **********
alias glog='git log --oneline --decorate --graph'   # git log oneline graph

#  TODO: doesnt work at all
alias glog0='git log --oneline --decorate --graph --date=format:"%a %Y-%m-%d %H:%M:%S"  --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'   # git log graph with dates (broken, see TODO)

#  TODO: put dates on these. the formating and colors is good
glog1() {   # git log graph with relative date and author
    echo " "
    git log --oneline --decorate --graph --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(blue)<%an>%Creset"
}

# ******* glol ********
# the standard glol is: # git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"
# the information is perfect almost. i like that in has the person who
# commited it, how long ago relative, however i want it to also have the
# absolute day, date, and time at the beginning in green like

#  TODO: put dates on these. the formating and colors is good.
# the information is perfect almost. i like that in has the person who
# commited it, how long ago relative, however i want it to also have the
# absolute day, date, and time at the beginning in green like
glol1() {   # git log graph pretty (relative date, author)
    git log --graph --color=always --date=format:'%a %Y-%m-%d %H:%M:%S'  --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"
}

#  TODO: make the formating and colors like glol1 and glol:
# (with the person who commited it, how long ago relative,).
# right now,  the commit message is in blue. i guess thats fine.
#  the the dates display the right information.
glol2() {   # git log graph with absolute dates
    git log --graph --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(blue)%s%C(reset)%C(auto)%d%C(reset)'
}

# ******* gloc ************
#  the dates are good.
# NOTE: it needs this to do the date formatting: --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)'
gloc() {   # git log graph, last 15, stays in scrollback
    echo "+ git log --oneline --decorate --graph (Stays in scroll back history)"
    echo ""
    git log --oneline --decorate --graph --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)' | head -n 15 | tee /dev/tty
}

# ******* glo ************
#  the dates are good.
glo() {   # git log oneline, last 15, stays in scrollback
    echo "+ git log --oneline --decorate (Stays in scroll back history)"
    echo ""
    git log --oneline --decorate --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)'   | head -n 15 | tee /dev/tty
}

# ******* glf ************
#  TODO: put header at the top of the output: "glft: git log --oneline --decorate --stat"
gloltt() {   # git log with stat, last 35, stays in scrollback
    echo "+ git log --oneline --decorate --stat (Stays in scroll back history)"
    echo ""
    git log --oneline --decorate --stat --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)' | head -n 35 | tee /dev/tty
}

#  the dates are good. color good. the solid blue for the commit message
#  works for this. bc the file data is black
glolt() {   # git log with stat (files changed)
    echo "+ git log --oneline --decorate --stat"
    echo ""
    # git log --oneline --decorate --stat
    # git log --oneline --decorate --stat --name-status
    # git log --oneline --decorate --stat --date=short --pretty=format:"%h (%ad) %s%d" --date=short
    git log --oneline --decorate --stat --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)'
}

# Safer staging options
alias gau='git add -u'                     # Stage all modified tracked files
alias gap='git add -p'                     # Interactive patch mode (stage parts of files)
alias ga='git add'                     # cfg add

# ********** review staged changes **********
alias gdcs='git diff --cached --stat'      # Quick overview of staged files
alias gdcss='git diff --cached'            # Full diff (gdca exists, but adding for consistency)

# ********** safe commit pattern **********
# Recommended workflow: gss → gau → gdcs → gcum "msg" → ggp
alias gcum='git add -u && git commit -m'   # Stage tracked + commit (mirrors cccum)

# ********** unstaging/discarding **********
alias grs='git restore --staged'           # Unstage files (keep changes)
alias grs!='git restore'                   # DANGER: Discard uncommitted changes
# ************************************************************



# ************************************************************
# ************** dot files bare-repo-- (~/.cfg) ****************
# ************************************************************
alias cfg="/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME"   # git for dotfiles bare repo

# TODO: 2026_05_05 change all "cfg bare repo" aliases somehow more
# distiguishable from git alias counterparts to make it harder to accidentally
# mix up with similar git aliases.
# maybe just add an extra 'c' to beginning?
# ccum -> cccum ?
# ccm  -> cccm  ?
# cca! -> ccca! ?
# ccan! -> cccan! ?

# ********** logging **********
alias clg='cfg log --stat'             # cfg log with stat
alias clol='cfg log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'   # cfg log graph pretty
alias clols='clol --stat'              # cfg log graph pretty with stat

#  the dates are good. color good. the solid blue for the commit message
#  works for this. bc the file data is black
alias clolt="cfg log --oneline --decorate --stat --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)'" # cfg log with stat (files changed)
alias clog='cfg log --oneline --decorate --graph'   # cfg log oneline graph

# Recommended workflow: cs → cau → cdcs → ccum "msg" → cfp
# (check status → stage updates → review staged → commit → push)

# ********** status **********
# List NEW (untracked) files in the allowlisted docs dirs (see _cfg_docs_dirs).
# The pathspec-restricted -uall pass overrides showUntrackedFiles=no for
# those dirs only, so pending docs show as ?? file lines. Display-only, never stages.
# :(top) anchors the pathspecs to the worktree root, so this runs from the
# current directory and prints cwd-relative paths, same as `cfg status`.
csdocs() {   # list new untracked docs files in cfg repo
  local g=(/usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME")
  "${g[@]}" status --short -uall -- "${_cfg_docs_dirs[@]/#/:(top)}" | grep '^??' || true
}
alias cs='cfg status --short && csdocs && csskills'   # cfg status short + new docs + skills
alias css='cfg status && csdocs && csskills'          # cfg status full + new docs + skills

cstatus() {   # cfg status as table (staged/worktree columns)
  local line staged worktree path

  printf "%-7s %-8s %s\n" "STAGED" "WORKTREE" "PATH"
  cfg status --porcelain=v1 | while IFS= read -r line; do
    staged="${line[1,1]}"
    worktree="${line[2,2]}"
    path="${line[4,-1]}"

    [[ "$staged" == " " ]] && staged="-"
    [[ "$worktree" == " " ]] && worktree="-"

    printf "%-7s %-8s %s\n" "$staged" "$worktree" "$path"
  done
}

# Safer staging options
alias cau='cfg add -u'                     # Stage all modified tracked files
alias cap='cfg add -p'                     # Interactive patch mode (stage parts of files)
alias ca='cfg add'                     # cfg add

# ********** docs auto-tracking **********
# The bare repo hides untracked files (status.showUntrackedFiles=no) and the
# staging aliases use `add -u`, which skips NEW files — so new notes/ADRs under
# config docs dirs can be missed. cadocs explicitly stages new files only in the
# dirs listed below; broad workflows cwip and cccum call it, while ccm commits
# exactly the existing index. Status helpers remain display-only.
# ADD NEW DOCS DIRS HERE (paths relative to $HOME; nothing else is ever swept):
_cfg_docs_dirs=(
  .config/docs
  .config/karabiner/docs
  .config/nvim/docs
  .config/oh-my-zsh/docs
  .config/opencode/docs
  .config/tmux/docs
)

cadocs() {   # stage new untracked docs files in cfg repo
  local g=(/usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME")
  local -a files=()
  while IFS= read -r -d '' file; do
    files+=("$file")
  done < <("${g[@]}" ls-files -z --others --exclude-standard -- "${_cfg_docs_dirs[@]/#/:(top)}")
  (( ${#files[@]} )) && "${g[@]}" add -- "${files[@]}"
  "${g[@]}" status --short -- "${_cfg_docs_dirs[@]/#/:(top)}"
}

# ********** skills and Claude commands auto-tracking **********
# Codex puts system-managed skills under the hidden .system directory. Discover
# every other directory containing SKILL.md so new personal or installed skills
# are tracked automatically without maintaining a per-skill allowlist.
_cfg_codex_skill_root=".codex/skills"

# Emit (NUL-delimited) worktree-relative Codex skill directories. Hidden path
# components are excluded so .system and any future runtime dotdirs stay local.
_cfg_codex_skill_dirs() {
  local root="$HOME/$_cfg_codex_skill_root"
  local skill_md dir rel
  for skill_md in "$root"/**/SKILL.md(N.); do
    dir=${skill_md:h}
    rel=${dir#$root/}
    [[ $rel == .* || $rel == */.* ]] && continue
    printf '%s\0' "${dir#$HOME/}"
  done
}

# Claude commands and shared skill entry points are user-authored config and
# should be tracked as a group.
_cfg_claude_workflow_dirs=(
  .claude/commands
  .claude/skills
)

# Hermes skills are the tricky group: my custom skills live intermixed with ~72
# bundled/generic skills (airtable, github-*, etc.) and runtime state (.hub,
# .curator_*, .usage.json) under one root, and ~/.gitignore blanket-ignores the whole
# .hermes-docker tree as a secrets safety net. A hand-listed dir allowlist silently
# missed every new custom skill (that's how personal-project/-scout/linkedin-profile fell
# through). Instead, track by RULE: a skill dir is BUNDLED iff its SKILL.md `name:`
# appears in .bundled_manifest — the dir basename is NOT reliable (e.g.
# mlops/models/audiocraft has `name: audiocraft-audio-generation`). Everything else
# with a SKILL.md is custom. This catches new custom skills recursively across every
# profile, never sweeps bundled ones, and scoping to skill dirs skips category
# DESCRIPTION.md and .runtime dotpaths.
_cfg_hermes_skill_dirs() {
  local dir
  for dir in "$HOME"/.hermes-docker/profiles/*/skills(N/); do
    printf '%s\0' "${dir#$HOME/}"
  done
}

# Emit (NUL-delimited) untracked files belonging to CUSTOM Hermes skills only.
# Raw `ls-files --others` (no --exclude-standard): the tree is blanket-ignored,
# so ignore-aware listing would return nothing; caskills force-adds instead.
_cfg_hermes_custom_others() {
  local g=(/usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME")
  local root_rel root manifest name skill_md dir f rel
  while IFS= read -r -d '' root_rel; do
    root="$HOME/$root_rel"
    manifest="$root/.bundled_manifest"
    local -A bundled=()
    [[ -f $manifest ]] && while IFS=: read -r name _; do bundled[$name]=1; done < "$manifest"
    local -a custom_dirs=()
    for skill_md in "$root"/**/SKILL.md(N.); do
      dir=${skill_md:h}
      [[ ${dir#$root} == */.* ]] && continue                # skip .hub etc.
      name=$(sed -n 's/^name:[[:space:]]*//p' "$skill_md" | head -n1)
      [[ -n $name && -z ${bundled[$name]} ]] && custom_dirs+=("${dir#$HOME/}")
    done
    (( ${#custom_dirs[@]} )) || continue
    # -C $HOME keeps emitted paths work-tree-relative without invoking shell cd aliases.
    while IFS= read -r -d '' f; do
      rel=${f#$root_rel/}
      [[ $rel == .* || $rel == */.* ]] && continue          # skip dotpath state files
      printf '%s\0' "$f"
    done < <("${g[@]}" -C "$HOME" ls-files -z --others -- "${custom_dirs[@]/#/:(top)}")
  done < <(_cfg_hermes_skill_dirs)
}

# Emit untracked, non-ignored files belonging to discovered Codex skills.
_cfg_codex_others() {
  local g=(/usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME")
  local -a dirs=()
  local dir
  while IFS= read -r -d '' dir; do dirs+=("$dir"); done < <(_cfg_codex_skill_dirs)
  (( ${#dirs[@]} )) || return 0
  "${g[@]}" -C "$HOME" ls-files -z --others --exclude-standard -- "${dirs[@]/#/:(top)}"
}

# Emit untracked, non-ignored files for user-authored Claude workflows.
_cfg_claude_workflow_others() {
  local g=(/usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME")
  # -C $HOME keeps emitted paths work-tree-relative, same base as the Hermes helper.
  "${g[@]}" -C "$HOME" ls-files -z --others --exclude-standard -- "${_cfg_claude_workflow_dirs[@]/#/:(top)}"
}

# Global third-party skills vendored by the skills CLI (see ADR 013):
# canonical content under .agents/skills plus the .skill-lock.json inventory.
_cfg_agents_skill_root=".agents"

# Emit untracked, non-ignored files for vendored global skills: the lockfile
# and non-hidden files under .agents/skills (dotpaths stay local, like Codex).
_cfg_agents_others() {
  local g=(/usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME")
  "${g[@]}" -C "$HOME" ls-files -z --others --exclude-standard -- \
    ":(top)$_cfg_agents_skill_root/.skill-lock.json" \
    ":(top)$_cfg_agents_skill_root/skills" \
  | while IFS= read -r -d '' f; do
      local rel=${f#$_cfg_agents_skill_root/skills/}
      [[ $rel != $f && ( $rel == .* || $rel == */.* ) ]] && continue
      printf '%s\0' "$f"
    done
}

csskills() {   # list untracked custom skills and claude workflow files
  { _cfg_codex_others; _cfg_claude_workflow_others; _cfg_agents_others; _cfg_hermes_custom_others; } \
  | while IFS= read -r -d '' f; do printf '?? %s\n' "$f"; done
}

caskills() {   # stage untracked custom skills and claude workflow files
  local g=(/usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME")
  local -a files=()
  local -a codex_dirs=()
  local -a hermes_dirs=()
  local dir
  while IFS= read -r -d '' dir; do codex_dirs+=("$dir"); done < <(_cfg_codex_skill_dirs)
  while IFS= read -r -d '' dir; do hermes_dirs+=("$dir"); done < <(_cfg_hermes_skill_dirs)
  while IFS= read -r -d '' file; do
    files+=("$file")
  done < <({ _cfg_codex_others; _cfg_claude_workflow_others; _cfg_agents_others; _cfg_hermes_custom_others; })
  # -f: Hermes files are blanket-ignored by design; harmless for the other groups.
  # -C $HOME matches the work-tree-relative paths emitted by the helpers.
  (( ${#files[@]} )) && "${g[@]}" -C "$HOME" add -f -- "${files[@]}"
  "${g[@]}" status --short -- \
    "${codex_dirs[@]/#/:(top)}" "${_cfg_claude_workflow_dirs[@]/#/:(top)}" \
    ":(top)$_cfg_agents_skill_root" "${hermes_dirs[@]/#/:(top)}"
}

# Review staged changes (USE BEFORE COMMITTING!)
# TODO: change names.
alias cfd='cfg diff'                       # cfg diff
alias cfdc='cfg diff --cached'            # Full diff of staged changes
alias cfdcs='cfg diff --cached --stat'      # Quick overview of staged files

# ********** unstaging/discarding **********
alias crs='cfg restore --staged'           # Unstage files (keep changes)
alias crs!='cfg restore'                   # DANGER: Discard uncommitted changes
alias creset='cfg reset HEAD~1'            # Undo last commit (keep changes)

# ******** commit **********
unalias ccam 2>/dev/null
# alias ccam='cfg  commit -a -m'

alias cwip='cadocs && caskills && cfg add -u && cfg commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'   # cfg wip commit (stage docs, skills, tracked)


# TODO: does this match logically with gcum ?
# state all modified tracked files and commit them (seems to work well)
# 3xc at the begining so not to confuse with gcum
# TODO: remove caskills?
alias cccum='cadocs && caskills && cfg add -u && cfg commit -m'   # cfg stage docs, skills, tracked + commit with message

alias ccm='cfg commit -m'              # cfg commit with message (index as-is)
alias ccmv='cfg commit -v'               # cfg verbose commit (diff in editor)
alias ccm!='cfg commit -m --amend'    # cfg commit --ammend with message

alias ccan!='cfg commit -v -a --no-edit --amend'   # cfg amend all tracked changes, keep message


# TODO: ?? change to not -a  ??
alias cca!='cfg add -A && cfg commit --verbose --all --amend'   # cfg add all + amend verbose
alias cca='cfg add -A && cfg commit --verbose --all'   # cfg add all + commit verbose


alias cfp='cfg push'                   # cfg push
alias cfpp='cfg push --force-with-lease'    # cfg push --force-with-lease

alias crbc='cfg rebase --continue'     # cfg rebase continue


clo() {   # cfg log oneline, last 15, stays in scrollback
    echo "+ cfg log --oneline --decorate (Show git log with one line and decoration)"
    echo ""
    cfg log --oneline  --color=always  --decorate | head -n 15 | tee /dev/tty
}

ccump() {   # commit to private cfg repo and sync public dotfiles repo
    if [ -z "$1" ]; then
        echo "Error: Commit message required"
        echo "Usage: ccump \"your commit message\""
        return 1
    fi

    local commit_msg="$1"

    echo "========================================="
    echo "Step 1: Committing to private cfg repo"
    echo "========================================="

    # Stage tracked files and commit to cfg bare repo
    if cfg add -u && cfg commit -m "$commit_msg"; then
        echo "✓ Private repo commit successful"
        echo ""

        echo "========================================="
        echo "Step 2: Syncing to public repo"
        echo "========================================="

        # Run the sync script with the commit message
        # Note: cfg publish-dotfiles is a git alias that runs the script
        # Git aliases starting with '!' pass arguments, so this passes the message
        if cfg publish-dotfiles "$commit_msg"; then
            echo ""
            echo "========================================="
            echo "✓ SUCCESS: Both repos updated!"
            echo "========================================="
            echo ""
            echo "Commit message: $commit_msg"
            echo ""
            echo "Next steps:"
            echo "  • Review private changes: cfg log -1 --stat"
            echo "  • Review public changes: cd ~/Projects/dot-files-publish && git log -1 --stat"
            echo "  • Push private: cfg push"
            echo "  • Push public: cd ~/Projects/dot-files-publish && git push"
        else
            echo ""
            echo "⚠️  WARNING: Private commit succeeded but public sync failed"
            echo "Private repo is updated, but public repo may need manual sync"
            return 1
        fi
    else
        echo ""
        echo "❌ ERROR: Private repo commit failed"
        echo "No changes made to either repository"
        return 1
    fi
}


alias cpub='cfg publish-dotfiles'          # Sync & commit public dotfiles

# ************ Projects ****************************

# Populate Memento .env with Google Photos secrets from 1Password
# Run once after cloning, or after rotating credentials
memento-env() {   # populate Memento .env from 1Password secrets
    local env_file="$HOME/Projects/memento/.env"
    cp "$HOME/Projects/memento/.env.example" "$env_file"
    sed -i "" "s|GOOGLE_PHOTOS_CLIENT_ID=.*|GOOGLE_PHOTOS_CLIENT_ID=$(op read 'op://Private/Memento - Google Photos OAuth/client_id')|" "$env_file"
    sed -i "" "s|GOOGLE_PHOTOS_CLIENT_SECRET=.*|GOOGLE_PHOTOS_CLIENT_SECRET=$(op read 'op://Private/Memento - Google Photos OAuth/client_secret')|" "$env_file"
    echo "✓ .env populated from 1Password"
}

# Usage: askcmd find all markdown files in current directory
_askcmd() {   # generate one terminal command with Claude, copy to clipboard
  if [[ $# -eq 0 ]]; then
    echo "usage: askcmd <describe the command you want>" >&2
    return 2
  fi

  local tmp
  tmp="$(mktemp -t askcmd.XXXXXX)" || return

  claude -p \
    --model haiku \
    --no-session-persistence \
    --tools "Read,Glob,Grep" \
    --output-format text \
    "Generate exactly one zsh terminal command for macOS. Do not run it. Return only plain text as exactly two consecutive nonblank lines: first a line starting with '## ' containing a short explanation of the command, immediately followed by the command line. Do not leave a blank line between those lines, or before or after them. Do not use numbering, bullets, markdown, code fences, or extra text. Task: $*" >"$tmp" 2>/dev/null

  local exit_status=$?
  if [[ $exit_status -eq 0 ]]; then
    cat "$tmp"
    echo

    local command
    command="$(sed -n '/^## /d; /^[^[:space:]]/ { p; q; }' "$tmp")"
    if [[ -n "$command" ]]; then
      if ! print -rn -- "$command" | pbcopy; then
        echo "Failed to copy to clipboard." >&2
      fi
    else
      echo "No command generated to copy." >&2
      exit_status=1
    fi
  fi
  rm -f "$tmp"
  return $exit_status
}
alias askcmd='noglob _askcmd'

# Usage: askcmd find all markdown files in current directory
_askcmds() {   # generate 4 terminal commands with Claude, copy top one
  if [[ $# -eq 0 ]]; then
    echo "usage: askcmds <describe the command you want>" >&2
    return 2
  fi

  local tmp
  tmp="$(mktemp -t askcmds.XXXXXX)" || return

  claude -p \
    --model sonnet \
    --no-session-persistence \
    --tools "Read,Glob,Grep" \
    --output-format text \
    "Generate exactly 4 possible zsh terminal commands for macOS. Do not run them. Return only plain text as 4 repeated entries, each with exactly two consecutive nonblank lines: first a line starting with '## ' containing a short explanation of the command, immediately followed by the command line. Separate entries with exactly one blank line. Do not leave a blank line between an explanation and its command, or before the first entry or after the last one. Do not use numbering, bullets, markdown, code fences, or extra text. Task: $*" >"$tmp" 2>/dev/null

  local exit_status=$?
  if [[ $exit_status -eq 0 ]]; then
    cat "$tmp"
    echo

    local top_command
    top_command="$(sed -n '/^## /d; /^[^[:space:]]/ { p; q; }' "$tmp")"
    if [[ -n "$top_command" ]]; then
      if ! print -rn -- "$top_command" | pbcopy; then
        echo "Failed to copy to clipboard." >&2
      fi
    else
      echo "No command generated to copy." >&2
      exit_status=1
    fi
  fi

  rm -f "$tmp"
  return $exit_status
}
alias askcmds='noglob _askcmds'

# Usage: ask what does the -S flag do in ls
_ask() {   # quick one-shot answer from Claude, no interactive session
  if [[ $# -eq 0 ]]; then
    echo "usage: ask <question>" >&2
    return 2
  fi

  claude -p \
    --model sonnet \
    --no-session-persistence \
    --tools "Read,Glob,Grep" \
    --output-format text \
    "Answer the question below as briefly as possible: a direct answer in one to a few sentences, plain text, no preamble or follow-up offers. If a terminal command is the answer, include it on its own line. You may read files in the current directory if the question is about them. Question: $*"
}
alias ask='noglob _ask'

# ************ Experiments ****************************
# activating venv. (not used)
# alias dl-env='source ~/Venv/dl-env/bin/activate'
