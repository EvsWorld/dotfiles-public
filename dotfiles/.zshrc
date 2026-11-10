# Profiling - temporary
# zmodload zsh/zprof

# TODO: how to turn this on so it doesnt error, and so it prevents gemini runnaway memory problem
# 1. OS-Level Resource Limits (ulimit)
# You can set a "hard ceiling" on how much memory any single process started from your
# shell can consume. Adding this to your .zshrc prevents a process from ever reaching 41GB:
# ulimit -d 10485760  # Limit process data segment size to 10GB (value in KB)
# ulimit -v 15728640  # Limit virtual memory to 15GB
# * Result: If Gemini tries to balloon to 41GB again, the OS will simply kill it (Crash) instead of
# letting it freeze your Mac.

# Raise the open-file limit for Neovim, LSPs, and dev tools.
ulimit -n 4096

alias cleanup="~/scripts/gemini-cleanup"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# TODO: move this file to ~/.config/.zshrc and make simlink to home dir?

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.config/oh-my-zsh/custom"

#  NOTE: my theme is located here: ~/.config/oh-my-zsh/custom/evan_robbyrussell_theme.zsh-theme
ZSH_THEME="evan_robbyrussell_theme"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(git npm macos aliases zsh-autosuggestions zsh-syntax-highlighting fzf colored-man-pages tldr)

# Skip oh-my-zsh's completion-directory security audit (~40-155ms of compaudit
# calls). Verified clean with `autoload -U compaudit; compaudit` (no output).
ZSH_DISABLE_COMPFIX=true

# Disable the update prompt. This MUST be set before oh-my-zsh is sourced;
# it used to live further down the file, where it had no effect at all.
DISABLE_UPDATE_PROMPT=true

# Source Oh My Zsh configuration.
# This loads all the standard oh-my-zsh functionality, including plugins, themes, and other configurations.
source $ZSH/oh-my-zsh.sh

# Disable fzf's ALT+C directory fuzzy-finder widget.
# Must be placed AFTER sourcing oh-my-zsh, otherwise the fzf plugin overwrites it.
# The fzf plugin binds ALT+C to fzf-cd-widget, but many terminals (including Ghostty)
# send ALT+C as the two-character sequence ESC+C, causing a fuzzy finder to open
# unexpectedly whenever ESC was pressed quickly followed by C.
# Rebind fzf's ALT+C directory cd widget to Ctrl+G (ALT+C removed — see above)
bindkey '^G' fzf-cd-widget

# Make specific letters self-insert when typed after ESC.
# ESC+letter is treated as ALT+letter (meta sequence) by zsh, which either
# triggers a widget or gets swallowed as undefined-key. Binding to self-insert
# makes the letter appear normally.
bindkey '\ea' self-insert-unmeta
bindkey '\eb' backward-word  # i think i still need this for my q mode movement mappings to work?
bindkey '\ec' self-insert-unmeta
bindkey '\ed' self-insert-unmeta
bindkey '\ee' self-insert-unmeta
bindkey '\ef' forward-word  # i think i still need this for my q mode movement mappings to work?
bindkey '\eg' self-insert-unmeta
bindkey '\eh' self-insert-unmeta
bindkey '\ei' self-insert-unmeta
bindkey '\ej' self-insert-unmeta
bindkey '\ek' self-insert-unmeta
bindkey '\el' self-insert-unmeta
bindkey '\em' self-insert-unmeta
bindkey '\en' self-insert-unmeta
bindkey '\eo' self-insert-unmeta
bindkey '\ep' self-insert-unmeta
bindkey '\eq' self-insert-unmeta
bindkey '\er' self-insert-unmeta
bindkey '\es' self-insert-unmeta
bindkey '\et' self-insert-unmeta
bindkey '\eu' self-insert-unmeta
bindkey '\ev' self-insert-unmeta
bindkey '\ew' self-insert-unmeta
bindkey '\ex' self-insert-unmeta
bindkey '\ey' self-insert-unmeta
bindkey '\ez' self-insert-unmeta


# source $ZSH/plugins/git/git.plugin.zsh
# source $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
# source $ZSH/plugins/npm/npm.plugin.zsh
# (~/.zshenv is sourced automatically by zsh for every shell before this file
# runs, so re-sourcing it here was redundant and has been removed.)
# [ -f ~/.config/.zshenv.local ] && source ~/.config/.zshenv.local

#  NOTE:  which aliases.zsh file should i source? # Source your custom aliases.
# By sourcing it here, all your custom aliases will be available after oh-my-zsh is initialized.
source $ZSH_CUSTOM/aliases.zsh

# FIX: supposed to help with navigating between prompts
# OSC 133 prompt marking for tmux navigation
# Using hook system to avoid conflicts with oh-my-zsh theme
# osc133_precmd() {
#   if [[ -n "$TMUX" ]]; then
#     print -Pn "\ePtmux;\e\e]133;A\e\e\\\\"
#   else
#     print -Pn "\e]133;A\e\\"
#   fi
# }
# osc133_precmd_end() {
#   if [[ -n "$TMUX" ]]; then
#     print -Pn "\ePtmux;\e\e]133;B\e\e\\\\"
#   else
#     print -Pn "\e]133;B\e\\"
#   fi
# }
# osc133_preexec() {
#   if [[ -n "$TMUX" ]]; then
#     print -Pn "\ePtmux;\e\e]133;C\e\e\\\\"
#   else
#     print -Pn "\e]133;C\e\\"
#   fi
# }
# precmd_functions+=(osc133_precmd osc133_precmd_end)
# preexec_functions+=(osc133_preexec)

# python env pyenv setup.
# PYENV_ROOT / PYENV_SHELL / the shims PATH entry are set statically in
# .zprofile, so python, pip and the other 65 shims already work here.
# `pyenv init -` only adds completions and the `pyenv shell` builtin, and it
# costs ~90-150ms (it spawns a nested bash plus `pyenv rehash` every startup),
# so load it on first use instead.
# Note: rehash no longer runs automatically. After a pip install that adds a
# new console script, run `pyenv rehash` once.
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init - zsh)"
  pyenv "$@"
}

# Initialize zoxide  and map to key j (must come after oh-my-zsh)
eval "$(zoxide init zsh --cmd j)"
alias jj='__zoxide_zi'

# Enhanced completion system
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' verbose true

# Colorize kill command process list
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"
HISTTIMEFORMAT="%F %T.%3N "  # include miliseconds in history
HISTSIZE=25000 # Sets the number of commands to remember in the command history
HISTFILESIZE=100000     # Store the last 10000 commands in the history file

# Remove duplicate entries from history
setopt histignorealldups

# Share history between all terminal sessions in real-time
setopt sharehistory

#  ****************************** User configuration ****************************************
#  *****************************************************************************************
# User configurations: These are placed after sourcing to allow customization and override of settings.

# Prevent Control+D from exiting the shell
export IGNOREEOF=999

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"

# (DISABLE_UPDATE_PROMPT moved above the oh-my-zsh source line; setting it
# here was dead code, since oh-my-zsh had already read it 150 lines earlier.)

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

export NVM_DIR="$HOME/.nvm"

# Put the default Node on PATH directly rather than sourcing nvm.sh.
# Sourcing it costs ~790ms, because nvm.sh ends by running `nvm use default`
# (resolve the `stable` alias, scan versions on disk, validate, rewrite PATH)
# on every single shell.
#
# This is a static PATH entry rather than a node/npm/npx shim function on
# purpose: Homebrew has node v26 on PATH, so if nvm's bin dir were absent
# until a shim fired, any script resolving `node` straight from PATH would
# silently get v26 instead of v24. Pinning the directory keeps v24 the real
# answer for everything, exactly as before.
#
# Update this path after changing the default with `nvm alias default`.
path=("$NVM_DIR/versions/node/v24.13.0/bin" $path)

# Load nvm itself only when it is actually invoked. Sourcing bash_completion
# here rather than at startup also removes a second, redundant `compinit`
# (it called compinit with no -d, targeting ~/.zcompdump instead of
# oh-my-zsh's dump, rebuilding the same 1757-entry table twice per shell).
nvm() {
  unfunction nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}

# fzf handles CTRL+R (fuzzy history search) via the fzf plugin — don't override it here
# bindkey "^R" history-incremental-search-backward

#zsh autosuggestions
# DELETE:
# bindkey '^ ' autosuggest-accept
bindkey '\e;' autosuggest-accept

if [[ $(hostname) = "YOUR-HOSTNAME.local" ]]; then
	# Add TeX binaries to PATH
	export PATH="/Library/TeX/texbin:$PATH"
	# Add OrbStack binaries to PATH (for docker, docker-compose, kubectl)
	export PATH="$HOME/.orbstack/bin:$PATH"
	# ~/.local/bin contains script symlinks managed by ~/scripts/sync-scripts.
	export PATH="$HOME/.local/bin:$PATH"
	export TMUX_CONF="$HOME/.config/tmux/tmux.conf"
	# export XDG_CONFIG_HOME="$HOME/.config"
	export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
fi

# examples and ideas:
 # https://github.com/codingjerk/dotfiles/blob/main/config/zsh/zshrc

# 1Password shell plugins (injects credentials via Touch ID instead of env vars)
source ~/.config/op/plugins.sh

# Ensure GitHub CLI resolves to the real binary even if a restored shell
# session or external startup hook reintroduces a stale 1Password alias.
unalias gh 2>/dev/null

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# PATH is deduplicated by `typeset -gU path fpath PATH FPATH` in ~/.zshenv.

# (The Antigravity CLI installer appended another "$HOME/.local/bin" PATH
# export here. It was the third copy - .zprofile and the block above already
# add it - so it has been removed.)



