# Keep PATH and fpath free of duplicates, at every nesting level.
#
# `brew shellenv` (.zprofile) does `export FPATH`, so a nested shell
# (Ghostty login shell -> tmux login shell) inherits an already-populated
# FPATH and oh-my-zsh then prepends its plugin dirs a second time.
# Oh My Zsh fingerprints its completion cache with the literal $fpath, so
# without this the fingerprint differs between nesting levels, the shells
# invalidate each other's cache forever, and every single shell pays a full
# ~460ms compinit rebuild instead of a ~27ms cached load.
#
# Must run before .zprofile and .zshrc, which is why it lives here.
typeset -gU path fpath PATH FPATH

# ($alfred_workflow_name is only populated by shell processes that called by Alfred)
if [[ "$alfred_workflow_name" == "GitFred" ]] ; then
	# export GITHUB_TOKEN="TODO"
	# if using a password manager, you can do something like this 
	# (`op` being the CLI for 1Password)
	# export GITHUB_TOKEN=$(op plugin run -- gh auth token)
fi

# GitHub token pulled securely from gh CLI keychain (no plaintext stored)
# export GITHUB_TOKEN=$(gh auth token 2>/dev/null)
# export GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_TOKEN
. "$HOME/.cargo/env"

# Machine-local secrets and overrides. This file is gitignored; .zshenv itself
# is tracked, so anything that must not be committed goes here.
[ -f "$HOME/.zshenv.local" ] && . "$HOME/.zshenv.local"
