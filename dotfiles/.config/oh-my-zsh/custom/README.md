# Oh My Zsh Custom Configuration

This directory contains custom scripts for [Oh My Zsh](https://ohmyz.sh/).

## `aliases.zsh`

This file contains a large collection of custom shell aliases and functions to streamline command-line workflows.

### Key Alias Categories:

*   **Tmux & Vim Session Management:** Aliases for creating, listing, attaching to, and killing `tmux` sessions (e.g., `tmnew`, `tmls`, `tmatt`). It also includes aliases for starting specific project sessions.
*   **Navigation:** `gt` (go to) aliases for quickly jumping to frequently used directories (e.g., `gtpr` for Projects, `gtvm` for nvim config).
*   **File Editing:** `ed` aliases for opening specific configuration files in `nvim` (e.g., `edzsh` for `.zshrc`, `edinitvim` for nvim config).
*   **Git:** A comprehensive set of `g` aliases to simplify `git` commands, including logging (`glog`, `glol`), status (`gs`, `gss`), and committing (`gcam`, `gcan!`). It also includes `cfg` aliases for managing dotfiles with a bare repository.
*   **General Utilities:** Aliases for common commands like `c` (clear), `rp` (reload zsh profile), and `h` (history).

## `evan_robbyrussell_theme.zsh-theme`

This is a custom Zsh theme that modifies the shell prompt.

### Prompt Features:

*   **Truncated Directory Path:** The current working directory name is truncated if it's too long, with special shortening for project-specific directory names (e.g., `shipper-integrations-` becomes `si-`).
*   **Git Status:** Integrates with `git` to show the current branch and status (clean or dirty).
*   **Timestamp:** The prompt includes the current date and time.
*   **Status Indicator:** Shows a green arrow (`➜`) for a successful previous command and a red one for a failed command.
