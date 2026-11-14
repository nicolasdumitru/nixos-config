# Login shell environment (zsh counterpart of ~/.bash_profile).
# zsh reads .zshrc on its own for interactive shells, so it is not sourced here.

# XDG Base Directory Specification user directories
export XDG_CONFIG_HOME="$HOME/.config"
mkdir -p "$XDG_CONFIG_HOME"
export XDG_DATA_HOME="$HOME/.local/share"
mkdir -p "$XDG_DATA_HOME"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$XDG_STATE_HOME"
export XDG_CACHE_HOME="$HOME/.cache"
mkdir -p "$XDG_CACHE_HOME"

# Readline (for programs that use it; zsh itself uses ZLE)
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
# Ripgrep
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
# Wget
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"

# Doom Emacs: Add `doom` to $PATH
export PATH="$PATH:$XDG_CONFIG_HOME/emacs/bin"

# Default programs
export EDITOR="$(command -v nvim)"
export TERMINAL="$(command -v alacritty)"
export BROWSER="$(command -v brave)"
# if bat is installed, use it to display man pages
if command -v bat 1>/dev/null 2>&1; then
	export MANPAGER="sh -c 'col -bx | command bat -l man -p'"
	export MANROFFOPT="-c"
fi
