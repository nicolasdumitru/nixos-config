# Read by every zsh instance. Only point zsh at its XDG config directory;
# environment variables live in $ZDOTDIR/.zprofile (mirrors .bash_profile).
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
