#!/bin/bash

# Environment variables

# XDG Base Directory Specification user directories
export XDG_CONFIG_HOME="$HOME/.config"
mkdir -p "$XDG_CONFIG_HOME"
export XDG_DATA_HOME="$HOME/.local/share"
mkdir -p "$XDG_DATA_HOME"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$XDG_STATE_HOME"
export XDG_CACHE_HOME="$HOME/.cache"
mkdir -p "$XDG_CACHE_HOME"

# Readline
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
# Ripgrep
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
# Wget
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"

# Doom Emacs: Add `doom` to $PATH
export PATH="$PATH:$XDG_CONFIG_HOME/emacs/bin"

# Default programs
EDITOR="$(command -v nvim)"
export EDITOR
TERMINAL="$(command -v alacritty)"
export TERMINAL
BROWSER="$(command -v brave)"
export BROWSER
# if bat is installed, use it to display man pages
if command -v bat 1>/dev/null 2>&1; then
	export MANPAGER="sh -c 'col -bx | command bat -l man -p'"
	export MANROFFOPT="-c"
fi

# Load bashrc
if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
fi
