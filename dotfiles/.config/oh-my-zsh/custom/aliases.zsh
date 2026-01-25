# ***** python *****
# alias scce='source venv/bin/activate'
# TEST: cwip alias test comment

# *********** pgadmin *********************
alias pgadmin='docker run \
  -p 5050:80 \
  -e "PGADMIN_DEFAULT_EMAIL=name@example.com" \
  -e "PGADMIN_DEFAULT_PASSWORD=admin" \
  -d dpage/pgadmin4'


# ***** Tmux + Vim session management ***************
alias tmux='tmux -f $TMUX_CONF'
alias tmnew='tmux new-session -s'    # Create new tmux session: tnew project-name
alias tmls='tmux list-sessions'       # List all tmux sessions
alias tmatt='tmux attach-session -t'  # Attach to session: tatt session-name
alias tmkill='tmux kill-session -t'   # Kill session: tkill session-name
# TODO: alias for detach/kill current session (ie Stop being in tmux and just convert the 
# current ghostty terminal window to be a non-tmux terminal instance)

alias tms="~/.config/tmux/scripts/tmux-sessionizer"
# alias tmw="~/.config/tmux/scripts/tmux-windowizer.sh"

# Project session shortcuts
# TODO:  tmux session for editing .config files
# It should save the vim session info to a vim session file called "Config.vim"
alias session-config='tmux new-session -s config -c ~/.config \; split-window -v -c ~/.config \; select-pane -t 0'
# TODO:  tmux session for writing scripts
# It Should save the vim session info to a vim session file called "Scratch.vim"
alias session-scratch='tmux new-session -s scratch -c ~/scratch'
# TODO:  tmux session for writing scripts.
# It Should save the vim session info to a vim session file called "Scripts.vim"
alias session-scripts='tmux new-session -s scripts -c ~/scripts'
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
# create parent directories by default with mkdir
alias mkdir='mkdir -pv'
# make directory and then move into it
mcd() {
    if [ -z "$1" ]; then
        echo "Error: No directory name provided."
        return 1
    fi
    mkdir -p "$1" && pushd "$1"
}
# ************** End Misc *************************

# ******* Programs ********
alias vimp='NVIM_APPNAME="nvim-theprimeagen" nvim'
alias vm=nvim
alias vim=nvim
alias cco='claude'
alias ccr='claude --resume'
alias gmm='gemini --sandbox'
alias oc='opencode'

alias gk='goku'
# ******* End programs ********


# ******* Utility ********
alias cd='pushd'
alias bk='popd'
alias flip='pushd_builtin'
alias c='clear'
# TODO: make this output an error if theres a problem
alias rp='source ~/.zshrc'   # Reloads profile
# ******* End Utility ********

# ********* Searching/Finding/Grepping ************
alias histgrep='history | grep'
# ********* Searching/Finding/Grepping ************

# *************** Go To ***************************
alias gtpr='cd ~/Projects/'
alias gtcl='gtpr && cd ClaudeMeta'
alias gtco='cd ~/code'
alias gtex='gtco && cd experiments'
alias gtzsh='cd ~/.zshrc'
alias gtcf='cd ~/.config'
alias gtscrii='cd ~/.config/scripts'
alias gtscri='cd ~/scripts'
alias gtscra='cd ~/scratch'

# alias gtvm='cd ~/.config/nvim'
unalias gtv 2>/dev/null
alias gtv='gtcf && cd nvim'
alias gttm='gtcf && cd tmux'
# ************* End Go To ***************************

# ******  Edit files  *************************
alias edzsh='nvim ~/.zshrc'
alias edgitignore='nvim ~/.gitignore'
alias edgitconfig='nvim ~/.gitconfig'
alias edaliascustom='nvim ~/.config/oh-my-zsh/custom/aliases.zsh'
alias edaliasdefault='nvim ~/.oh-my-zsh/plugins/git/git.plugin.zsh ~/.oh-my-zsh/plugins/git/README.md ~/.oh-my-zsh/custom/aliases.zsh'
alias edinitvim='nvim ~/.config/nvim'
alias edka='nvim ~/.config/karabiner.edn'
alias edgitignorecfg='nvim ~/.cfg/todo'
alias edgitconfigcfg='nvim ~/.cfg/config'
alias edsuperwhisper='nvim ~/Documents/superwhisper/settings/vocabulary.json'
# ******  End Edit files  *************************


# *************** Viewing/status related ************************
alias hist100='history | tail -n 100'
alias hist40='history | tail -n 40'

# Process monitoring
alias hbad="HTOPRC=~/.config/htop/htoprc-bad htop"
alias list-bad-procs="~/.config/scripts/list-bad-procs.sh"
alias hmem="HTOPRC=~/.config/htop/htoprc-memory htop"
alias horph="HTOPRC=~/.config/htop/htoprc-orphans htop"
# alias showorph="~/scripts/run_htop_and_orphans.sh"

# Toggle hidden files in Finder
thidden() {
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

# Shows folders first and in color. required I run ""> brew install coreutils" first
# alias ls='/usr/local/bin/gls --color -h --group-directories-first'
## Use a long listing format ##
alias lp='ls -lAhog'
alias ll='eza -a --long --no-permissions --no-user --time modified --icons --time-style=relative'
alias ftree='tree -v -L 2 --charset utf-8 --filelimit 400'
alias cp='cp -i'
alias ln='ln -i'
alias lsl='ls -1hFA | less'
alias ccp='pwd|pbcopy'
# ***************End Viewing/status related ******************************



# ************************************************************
# ************************* git ******************************
# ************************************************************
#  TODO: move all these to the git.plugin.zsh file?
# and just delete the existing aliases instead of unaliasing them??

alias gtag="git tag | sort -V"

unalias gcm 2>/dev/null
alias gcom='git checkout $(git_main_branch)'

unalias gcm! 2>/dev/null
alias gcm!='git commit --amend -m'

unalias gcam! 2>/dev/null
alias gcam!='git add -A && git commit --amend -m'

unalias gcam 2>/dev/null
alias gcam='git add -A && git commit -m'

# these cant be fundtions so will accept options at the end like -n
unalias gcan! 2>/dev/null
alias gcan!='git add -A && git commit --verbose --all --no-edit --amend'

# # git
#
unalias glog 2>/dev/null

unalias gca 2>/dev/null
alias gca='git add -A && git commit --verbose --all'

unalias gca! 2>/dev/null
alias gca!='git add -A && git commit --verbose --all --amend'

# Unalias the commands if they exist to avoid conflicts
unalias gs 2>/dev/null
unalias gss 2>/dev/null
unalias g: 2>/dev/null
unalias gloc 2>/dev/null
unalias glo 2>/dev/null
unalias gst 2>/dev/null

# // IMP: git stash
gstt() {
echo "+ git stash (Stash changes)"
echo ""
git stash
}

gss() {
    echo "+ git status --short (Show git status in short format)"
    echo ""
    git status --short
}

gs() {
    echo "+ git status (Show git status)"
    echo ""
    git status
}

g:() {
    echo "+ git checkout - (Switch to the previous branch)"
    echo ""
    git checkout -
}


# ******* glog **********
alias glog='git log --oneline --decorate --graph'

#  TODO: doesnt work at all
alias glog0='git log --oneline --decorate --graph --date=format:"%a %Y-%m-%d %H:%M:%S"  --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'

#  TODO: put dates on these. the formating and colors is good
glog1() {
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
glol1() {
    git log --graph --color=always --date=format:'%a %Y-%m-%d %H:%M:%S'  --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"
}

#  TODO: make the formating and colors like glol1 and glol:
# (with the person who commited it, how long ago relative,).
# right now,  the commit message is in blue. i guess thats fine.
#  the the dates display the right information.
glol2() {
    git log --graph --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(blue)%s%C(reset)%C(auto)%d%C(reset)'
}

# ******* gloc ************
#  the dates are good.
# NOTE: it needs this to do the date formatting: --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)'
gloc() {
    echo "+ git log --oneline --decorate --graph (Stays in scroll back history)"
    echo ""
    git log --oneline --decorate --graph --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)' | head -n 15 | tee /dev/tty
}

# ******* glo ************
#  the dates are good.
glo() {
    echo "+ git log --oneline --decorate (Stays in scroll back history)"
    echo ""
    git log --oneline --decorate --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)'   | head -n 15 | tee /dev/tty
}

# ******* glf ************
#  TODO: put header at the top of the output: "glft: git log --oneline --decorate --stat"
glft() {
    echo "+ git log --oneline --decorate --stat (Stays in scroll back history)"
    echo ""
    git log --oneline --decorate --stat --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)' | head -n 35 | tee /dev/tty
}

#  the dates are good. color good. the solid blue for the commit message
#  works for this. bc the file data is black
glf() {
    echo "+ git log --oneline --decorate --stat"
    echo ""
    # git log --oneline --decorate --stat
    # git log --oneline --decorate --stat --name-status
    # git log --oneline --decorate --stat --date=short --pretty=format:"%h (%ad) %s%d" --date=short
    git log --oneline --decorate --stat --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)'
}

# ********** review staged changes **********
alias gdcs='git diff --cached --stat'      # Quick overview of staged files
alias gdcss='git diff --cached'            # Full diff (gdca exists, but adding for consistency)

# ********** safe commit pattern **********
# Recommended workflow: gss → gau → gdcs → gcum "msg" → ggp
alias gcum='git add -u && git commit -m'   # Stage tracked + commit (mirrors ccum)

# ********** unstaging/discarding **********
alias grs='git restore --staged'           # Unstage files (keep changes)
alias grs!='git restore'                   # DANGER: Discard uncommitted changes
# ************************************************************



# ************************************************************
# ************** dot files bare-repo-- (~/.cfg) ****************
# ************************************************************
alias cfg="/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME"

# ********** logging **********
alias clg='cfg log --stat'
alias clol='cfg log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias clols='clol --stat'
alias clog='cfg log --oneline --decorate --graph'

# Recommended workflow: cs → cau → cdcs → ccum "msg" → cfp
# (check status → stage updates → review staged → commit → push)

# ********** status **********
alias cs='cfg status --short'
alias css='cfg status'
alias csd='cfg diff'

# Safer staging options
alias cau='cfg add -u'                     # Stage all modified tracked files
alias cap='cfg add -p'                     # Interactive patch mode (stage parts of files)
alias ca='cfg add'

# Review staged changes (USE BEFORE COMMITTING!)
alias cdcs='cfg diff --cached --stat'      # Quick overview of staged files
alias cdcss='cfg diff --cached'            # Full diff of staged changes

# ********** unstaging/discarding **********
alias crs='cfg restore --staged'           # Unstage files (keep changes)
alias crs!='cfg restore'                   # DANGER: Discard uncommitted changes
alias creset='cfg reset HEAD~1'            # Undo last commit (keep changes)

# ******** commit **********
unalias ccam 2>/dev/null
# alias ccam='cfg  commit -a -m'

alias cwip='cfg add -u && cfg commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'

# state all modified tracked files and commit them ( NOTE:  seems to work well)
alias ccum='cfg add -u && cfg commit -m'     

alias ccm='cfg commit -m'

# Amend last commit with all tracked changes (modified/deleted files), keeping existing message
alias ccan!='cfg commit -v -a --no-edit --amend'


# TODO: ?? change to not -a  ?? 
alias cca!='cfg add -A && cfg commit --verbose --all --amend'
alias cca='cfg add -A && cfg commit --verbose --all'

# Verbose commit (shows diff in commit message editor)
alias cc='cfg commit -v'

alias cfp='cfg push'
alias cfpp='cfg push -f'

alias crbc='cfg rebase --continue'


#  stays in scroll back history
clo() {
    echo "+ cfg log --oneline --decorate (Show git log with one line and decoration)"
    echo ""
    cfg log --oneline  --color=always  --decorate | head -n 15 | tee /dev/tty
}

#  the dates are good. color good. the solid blue for the commit message
#  works for this. bc the file data is black
clf() {
    echo "+ git log --oneline --decorate --stat ( git log with one line, decoration, and stat)"
    echo ""
    cfg log --oneline --decorate --stat --color=always --date=format:'%a %Y-%m-%d %H:%M:%S' --pretty=format:'%C(yellow)%h%C(reset) %C(green)(%ad)%C(reset) %C(bold blue)%s%C(reset)%C(auto)%d%C(reset)'
}

# ************ Experiments ****************************
# activating venv. (not used)
# alias dl-env='source ~/Venv/dl-env/bin/activate'
# alias ibrew="arch -x86_64 /usr/local/bin/brew"

# TODO: Make this function available for interactive use
# # Custom function to handle the -p flag for copying output to clipboard
# run_with_pbcopy() {
#     # Check if the last argument is -p
#     if [[ "${@[-1]}" == "-p" ]]; then
#         # Remove the -p from the arguments
#         local cmd=("${(@)@[:-1]}")
#         # Execute the command and pipe the output to pbcopy
#         "${cmd[@]}" | pbcopy
#     else
#         # Execute the command normally
#         "$@"
#     fi
# }
# alias run="run_with_pbcopy"




