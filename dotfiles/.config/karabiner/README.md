# Karabiner Configuration

This document outlines the setup for Karabiner-Elements, which uses a customized workflow involving `karabiner.edn` and `goku`.

## Overview

This configuration relies on three main components:

1.  **`karabiner.edn`**: This is the core configuration file where all key mappings and rules are defined using edn format. It is located in `~/.config/karabiner.edn` after being synced from this repository.
2.  **`goku`**: A command-line tool that acts as a transpiler. It reads the `karabiner.edn` file and converts it into the `karabiner.json` format that Karabiner-Elements can understand.
3.  **Karabiner-Elements**: The macOS application that reads the generated `karabiner.json` and applies the specified key modifications.

## Workflow

The typical workflow for modifying key mappings is as follows:

1.  **Edit Key Mappings**: Make changes to your keybindings in the `karabiner.edn` file located in this directory.
2.  **Transpile Configuration**: Run `goku` (or have it run automatically via its daemon) to transpile the `.edn` file into `~/.config/karabiner/karabiner.json`.
3.  **Apply Changes**: Karabiner-Elements automatically detects changes to `karabiner.json` and applies the new configuration.
