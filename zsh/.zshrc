fastfetch

############################
# HISTORIQUE
############################

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY

############################
# OPTIONS UTILES
############################

setopt AUTO_CD              # cd automatique
setopt CORRECT              # correction commandes
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

############################
# KEYBINDINGS
############################

bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

############################
# ALIAS
############################

alias ls="ls --color=auto"
alias ll="ls -lah"
alias la="ls -A"
alias ..="cd .."
alias ...="cd ../.."

## Git
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gcam="git commit -am"
alias gp="git push"
alias gpl="git pull"
alias gfp="git fetch --prune"
alias gl="git log --oneline --graph --decorate"
alias gr="git restore"

## Python
alias py="python3"
alias pcs="pycodestyle"

############################
# OH MY POSH
############################

# eval "$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/multiverse-neon.omp.json')"

eval "$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/night-owl.omp.json')"

############################
# PLUGINS (si installés)
############################

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

############################
# ZINIT PLUGINS
############################

zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting

############################
# AUTOCOMPLETION
############################

autoload -Uz compinit
compinit -d ~/.zcompdump
zinit cdreplay -q

# Added by LM Studio CLI tool (lms)
export PATH="$PATH:/home/mathis/.lmstudio/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export DOCKER_BUILDKIT=1

############################
# ALIASES EXTERNES
############################

[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"
