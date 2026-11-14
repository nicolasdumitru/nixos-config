# Read by every zsh instance. Only point zsh at its XDG config directory;
# environment variables live in $ZDOTDIR/.zprofile (mirrors .bash_profile).
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Skip the system-wide /etc/zprofile, /etc/zshrc, /etc/zlogin and /etc/zlogout,
# so the OS cannot inject aliases, prompts, hooks or options. /etc/zshenv has
# already run by now; it only sets up the environment (PATH, fpath, ...).
unsetopt GLOBAL_RCS

# Same for every bash started from here: NixOS's /etc/bashrc returns
# immediately when this is set. Harmless on other systems.
export NOSYSBASHRC=1
