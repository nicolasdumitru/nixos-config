#!/bin/bash

# === Interactive shell config ===
# If not running interactively, don't do anything else
if [[ $- != *i* ]]; then
	return 0
fi

umask 077

# History configuration
HISTFILE="$XDG_STATE_HOME"/bash_history

# file manager (quick navigation)
fm () {
	cd "$(command lf -print-last-dir "$@")" || return 1
}

# directory fuzzy finder
ff () {
	fm "$(command fd --type directory --color never | command fzf --tiebreak=chunk,begin,length --scheme=path --preview='command ls {}' "$@")" || return 1
}

# file operations
alias cp='command cp -i'
alias mv='command mv -i'

alias eza='command eza --long --header --classify --group-directories-first --git --icons --color=auto --icons=auto'

# date
alias timestamp='command date -u "+%Y-%m-%d-%H-%M-%S"'

# git time-stamped snapshot
alias gtss='command git add . && command git commit -m "$(command date -u)"'
# cd to git repository root
alias cdrr='cd "$(command git rev-parse --show-toplevel)"'

# vi keybindings
set -o vi
set show-mode-in-prompt on
bind 'set vi-ins-mode-string \1\e[5 q\2'
bind 'set vi-cmd-mode-string \1\e[1 q\2'
# ctrl-l clear
bind -m vi-command 'Control-l: clear-screen'
bind -m vi-insert 'Control-l: clear-screen'
eval "$(starship init bash)"
eval "$(direnv hook bash)" # must be the last line of the config
