# Interactive zsh config (zsh counterpart of ~/.bashrc).
# zsh only reads this file for interactive shells.

umask 077

# === History ===
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY       # save timestamps and durations
setopt SHARE_HISTORY          # write immediately and share between sessions
setopt HIST_IGNORE_DUPS       # skip consecutive duplicates
setopt HIST_IGNORE_SPACE      # commands starting with a space are not saved
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # show `!!`-style expansions before running them
setopt HIST_FCNTL_LOCK

# === Completion ===
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
(( $+commands[dircolors] )) && eval "$(command dircolors -b)" # sets LS_COLORS
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zmodload zsh/complist

setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# === Functions ===
# file manager (quick navigation)
fm () {
	cd "$(command lf -print-last-dir "$@")" || return 1
}

# directory fuzzy finder
ff () {
	fm "$(command fd --type directory --color never | command fzf --tiebreak=chunk,begin,length --scheme=path --preview='command ls {}' "$@")" || return 1
}

# === Aliases ===
# file operations
alias cp='command cp -i'
alias mv='command mv -i'

alias eza='command eza --long --header --classify --group-directories-first --git --icons --color=auto --icons=auto --hyperlink=auto'
alias ls='eza'

# date
alias timestamp='command date -u "+%Y-%m-%d-%H-%M-%S"'

# git time-stamped snapshot
alias gtss='command git add . && command git commit -m "$(command date -u)"'
# cd to git repository root
alias cdrr='cd "$(command git rev-parse --show-toplevel)"'

# === Vi mode ===
bindkey -v
KEYTIMEOUT=1 # switch to command mode immediately on <Esc>

# Cursor shape: blinking bar in insert mode, blinking block in command mode.
# Defined before `starship init`, which wraps an existing zle-keymap-select.
__zsh_vi_cursor() {
	if [[ $KEYMAP == vicmd ]]; then
		print -n '\e[1 q'
	else
		print -n '\e[5 q'
	fi
}
zle-keymap-select() { __zsh_vi_cursor }
zle-line-init() { __zsh_vi_cursor }
zle -N zle-keymap-select
zle -N zle-line-init
# Reset to the insert cursor before running external programs.
__zsh_vi_cursor_preexec() { print -n '\e[5 q' }
autoload -Uz add-zsh-hook
add-zsh-hook preexec __zsh_vi_cursor_preexec

# Behave like readline in insert mode: delete past the insertion point.
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line

# Home / End / Delete (normally set up by the skipped /etc/zshrc)
for keymap in viins vicmd; do
	[[ -n ${terminfo[khome]} ]] && bindkey -M "$keymap" "${terminfo[khome]}" beginning-of-line
	[[ -n ${terminfo[kend]} ]] && bindkey -M "$keymap" "${terminfo[kend]}" end-of-line
	[[ -n ${terminfo[kdch1]} ]] && bindkey -M "$keymap" "${terminfo[kdch1]}" delete-char
	bindkey -M "$keymap" '^[[H' beginning-of-line
	bindkey -M "$keymap" '^[[F' end-of-line
	bindkey -M "$keymap" '^[[3~' delete-char
done
unset keymap

# ctrl-l clear
bindkey -M viins '^L' clear-screen
bindkey -M vicmd '^L' clear-screen

# History search: ctrl-r / ctrl-s, and up/down (or k/j) search by prefix.
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M viins '^S' history-incremental-search-forward
bindkey -M vicmd '/' history-incremental-search-backward
bindkey -M vicmd '?' history-incremental-search-forward
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
for keymap in viins vicmd; do
	bindkey -M "$keymap" '^[[A' up-line-or-beginning-search
	bindkey -M "$keymap" '^[OA' up-line-or-beginning-search
	bindkey -M "$keymap" '^[[B' down-line-or-beginning-search
	bindkey -M "$keymap" '^[OB' down-line-or-beginning-search
done
unset keymap
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# Edit the current command line in $EDITOR with `v` in command mode.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Shift-Tab goes backwards in the completion menu.
bindkey -M menuselect '^[[Z' reverse-menu-complete

# === Prompt and hooks ===
eval "$(starship init zsh)"
# On <Enter>, redraw the prompt with the current time, so the submitted
# command's prompt shows when it started (see env_var in starship.toml).
zle-line-finish() {
	export PROMPT_CMD_STARTED=${(%):-%D{%H:%M:%S}}
	zle reset-prompt
}
zle -N zle-line-finish
# Keep it out of the command's environment and the next prompt.
__prompt_cmd_started_unset() { unset PROMPT_CMD_STARTED }
add-zsh-hook preexec __prompt_cmd_started_unset
add-zsh-hook precmd __prompt_cmd_started_unset
eval "$(direnv hook zsh)"
eval "$(zoxide init zsh)" # z / zi (interactive, via fzf); after compinit

# === Plugins (generated by Home Manager with Nix store paths) ===
# Autosuggestions: accept with <Right>, ctrl-f, or `l`/`$`/`A` in command mode.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
bindkey -M viins '^F' autosuggest-accept
# Syntax highlighting is sourced last, as it must wrap every ZLE widget.
if [[ -r "$ZDOTDIR/plugins.zsh" ]]; then
	source "$ZDOTDIR/plugins.zsh"
fi
