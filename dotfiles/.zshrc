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
source $HOME/.zshenv
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

# python env pyenv setup
eval "$(pyenv init -)"

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

export DISABLE_UPDATE_PROMPT=true

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# fzf handles CTRL+R (fuzzy history search) via the fzf plugin — don't override it here
# bindkey "^R" history-incremental-search-backward

#zsh autosuggestions
# DELETE:
# bindkey '^ ' autosuggest-accept

# TODO: move scripts directory into projects/ directory
# Auto-sync all executable scripts to ~/.local/bin for global access.
# Update SCRIPTS_DIR if you move your scripts elsewhere.
SCRIPTS_DIR="$HOME/scripts"
_sync_scripts() {
  local bin_dir="$HOME/.local/bin"
  find "$SCRIPTS_DIR" -type f -perm +111 \
    -not -path '*/archive/*' \
    -not -path '*/.git/*' -exec sh -c '
    bin_dir="$1"
    shift
    for script in "$@"; do
      name=$(basename "$script" | sed "s/\.[^.]*$//")
      ln -sf "$script" "$bin_dir/$name" 2>/dev/null
    done
  ' _ "$bin_dir" {} + 2>/dev/null
}
_sync_scripts

if [[ $(hostname) = "YOUR-HOSTNAME.local" ]]; then
	# Add TeX binaries to PATH
	export PATH="/Library/TeX/texbin:$PATH"
	# Add OrbStack binaries to PATH (for docker, docker-compose, kubectl)
	export PATH="$HOME/.orbstack/bin:$PATH"
	# ~/.local/bin contains auto-synced script symlinks (see _sync_scripts above)
	export PATH="$HOME/.local/bin:$PATH"
	export TMUX_CONF="$HOME/.config/tmux/tmux.conf"
	# export XDG_CONFIG_HOME="$HOME/.config"
fi

# examples and ideas:
 # https://github.com/codingjerk/dotfiles/blob/main/config/zsh/zshrc

# 1Password shell plugins (injects credentials via Touch ID instead of env vars)
source ~/.config/op/plugins.sh

