# Only run brew shellenv once per process tree.
# It unconditionally PREPENDS to PATH/FPATH, so in a nested shell (Ghostty
# login shell -> tmux login shell) it re-promotes its site-functions dir to
# the front of fpath. Everything it sets is exported and therefore already
# inherited, so re-running it only churns ordering - which is enough on its
# own to break oh-my-zsh's $fpath-based completion-cache fingerprint and
# force a full ~460ms compinit rebuild in every nested shell.
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  # Nested login shell. macOS's /etc/zprofile runs path_helper again, which
  # rebuilds PATH with the system dirs first and demotes /opt/homebrew/bin
  # below /usr/local/bin and /usr/bin. brew shellenv used to mask that by
  # re-prepending. Restore the precedence directly, with no subprocess and
  # without touching fpath.
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
fi

# pyenv: put the shims on PATH directly instead of `eval "$(pyenv init --path)"`.
# That eval cost ~150ms because it spawns pyenv plus a nested `bash --norc`
# just to produce this PATH entry. The 65 shims in ~/.pyenv/shims dispatch on
# their own, so python/pip/black/mypy work identically without it.
# The interactive half (completions + `pyenv shell`) is lazy-loaded in .zshrc.
export PYENV_ROOT="$HOME/.pyenv"
export PYENV_SHELL=zsh
path=("$PYENV_ROOT/shims" $path)

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"


# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"
