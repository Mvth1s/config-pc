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
alias ls="ls --color=auto"   # liste les fichiers avec couleurs
alias ll="ls -lah"           # liste détaillée (permissions, taille, cachés)
alias la="ls -A"             # liste tous les fichiers dont les cachés
alias ..="cd .."             # remonte d'un répertoire
alias ...="cd ../.."         # remonte de deux répertoires

## Git
alias gs="git status"                      # état du dépôt (modifs, staged, untracked)
alias ga="git add"                         # ajoute un fichier au staging
alias gc="git commit"                      # ouvre l'éditeur pour commiter
alias gcm="git commit -m"                  # commit avec message inline
alias gcam="git commit -am"                # stage + commit tous les fichiers suivis
alias gp="git push"                        # pousse les commits vers le remote
alias gpl="git pull"                       # récupère et fusionne les commits du remote
alias gfp="git fetch --prune"              # récupère les refs et supprime les branches distantes supprimées
alias gl="git log --oneline --graph --decorate"  # log compact avec arbre des branches
alias gr="git restore"                     # annule les modifs d'un fichier (working tree)
alias gco="git checkout"                   # change de branche ou restaure des fichiers
alias gcob="git checkout -b"               # crée et bascule sur une nouvelle branche
alias gcod="git checkout dev"              # bascule sur la branche dev
alias gcom="git checkout main"             # bascule sur la branche main
alias gb="git branch"                      # liste les branches locales
alias gbr="git branch -r"                  # liste les branches distantes
alias gba="git branch -a"                  # liste toutes les branches (locales + distantes)
alias gbd="git branch -d"                  # supprime une branche (safe, refus si non fusionnée)
alias gbD="git branch -D"                  # supprime une branche de force
alias gbm="git branch -m"                  # renomme une branche  →  gbm <ancien> <nouveau>
alias gbmm="git branch -m main"            # renomme la branche courante en main
alias gst="git stash"                      # met de côté les modifs non commitées
alias gstp="git stash pop"                 # réapplique le dernier stash et le supprime
alias gstl="git stash list"                # liste tous les stashs
alias gd="git diff"                        # diff des modifs non stagées
alias gds="git diff --staged"              # diff des modifs stagées (avant commit)
alias grs="git restore --staged"           # retire un fichier du staging (unstage)
alias grb="git rebase"                     # rejoue les commits sur une autre base
alias gm="git merge"                       # fusionne une branche dans la branche courante
alias gsw="git switch"                     # bascule sur une branche (alternative moderne à gco)
alias gswc="git switch -c"                 # crée et bascule sur une nouvelle branche (alternative moderne à gcob)

## Python
alias py="python3"           # lance Python 3
alias pcs="pycodestyle"      # vérifie le style PEP8 d'un fichier Python

## Docker
alias d="docker"                    # raccourci docker
alias dc="docker compose"           # raccourci docker compose
alias dcu="docker compose up -d"    # démarre les services en arrière-plan
alias dcd="docker compose down"     # arrête et supprime les conteneurs
alias dps="docker ps"               # liste les conteneurs actifs
alias dlogs="docker logs -f"        # suit les logs d'un conteneur en temps réel

alias ssh='TERM=xterm-256color ssh'

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
export PATH="$PATH:$HOME/.lmstudio/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export DOCKER_BUILDKIT=1

############################
# ALIASES EXTERNES
############################

[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"
