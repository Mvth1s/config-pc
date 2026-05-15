#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/utils.sh"

BACKUP_TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
BACKUP_DIR="$HOME/.dotfiles_backup/$BACKUP_TIMESTAMP"

link_config() {
    local src_rel="$1"
    local dest="$2"
    local src_abs="$REPO_ROOT/$src_rel"

    mkdir -p "$(dirname "$dest")"

    if [[ -e "$dest" ]] && [[ ! -L "$dest" ]]; then
        log_warn "Backup : $dest → $BACKUP_DIR/"
        mkdir -p "$BACKUP_DIR"
        cp -r "$dest" "$BACKUP_DIR/"
    fi

    ln -sf "$src_abs" "$dest"
    log_success "Symlink : $dest"
}

log_step "Création des symlinks de configuration"
link_config "fastfetch"    "$HOME/.config/fastfetch"
link_config "ghostty"      "$HOME/.config/ghostty"
link_config "zed"          "$HOME/.config/zed"
link_config "zsh/.zshrc"   "$HOME/.zshrc"
link_config "zsh/.aliases" "$HOME/.aliases"

log_step "Installation de oh-my-posh"
if ! cmd_exists oh-my-posh; then
    log_info "Installation de oh-my-posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
    log_success "oh-my-posh installé"
else
    log_info "oh-my-posh déjà présent"
fi

log_step "Installation des Nerd Fonts (JetBrainsMono)"
if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
    log_info "Installation de JetBrainsMono Nerd Font via oh-my-posh..."
    oh-my-posh font install JetBrainsMono
    fc-cache -f
    log_success "JetBrainsMono Nerd Font installée"
else
    log_info "JetBrainsMono Nerd Font déjà présente"
fi

log_step "Installation de zinit"
ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
    log_info "Installation de zinit..."
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME"
    log_success "zinit installé"
else
    log_info "zinit déjà présent"
fi

log_step "Shell par défaut"
if [[ "$SHELL" != "$(which zsh 2>/dev/null || true)" ]]; then
    if confirm "Définir zsh comme shell par défaut ?"; then
        chsh -s "$(which zsh)"
        log_success "Shell par défaut changé en zsh (actif à la prochaine connexion)"
    fi
else
    log_info "zsh est déjà le shell par défaut"
fi

log_success "Dotfiles configurés"
