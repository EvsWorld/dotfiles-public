# Profiling - temporary
# zmodload zsh/zprof

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
plugins=(git npm macos aliases zsh-autosuggestions zsh-syntax-highlighting fzf)

# Source Oh My Zsh configuration.
# This loads all the standard oh-my-zsh functionality, including plugins, themes, and other configurations.
source $ZSH/oh-my-zsh.sh
# source $ZSH/plugins/git/git.plugin.zsh
# source $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
# source $ZSH/plugins/npm/npm.plugin.zsh
source $HOME/.zshenv
# [ -f ~/.config/.zshenv.local ] && source ~/.config/.zshenv.local

#  NOTE:  which aliases.zsh file should i source? # Source your custom aliases.
# By sourcing it here, all your custom aliases will be available after oh-my-zsh is initialized.
source $ZSH_CUSTOM/aliases.zsh

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

# TODO: set up the fzf args eval thing

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

bindkey "^R" history-incremental-search-backward

#zsh autosuggestions
bindkey '^ ' autosuggest-accept

if [[ $(hostname) = "YOUR-HOSTNAME.local" ]]; then
	# Add TeX binaries to PATH
	export PATH="/Library/TeX/texbin:$PATH"
	# put path to scripts on PATH
	export PATH="$PATH:$HOME/scripts"
	#  TODO: make sure all scripts in the child directory are also callable from anywhere
	export PATH="$PATH:$HOME/.config/scripts"
	# Add OrbStack binaries to PATH (for docker, docker-compose, kubectl)
	export PATH="$HOME/.orbstack/bin:$PATH"
	# Claude Code native installation
	export PATH="$HOME/.local/bin:$PATH"
	export TMUX_CONF="$HOME/.config/tmux/tmux.conf"
	# export XDG_CONFIG_HOME="$HOME/.config"
fi

# examples and ideas:
 # https://github.com/codingjerk/dotfiles/blob/main/config/zsh/zshrc

