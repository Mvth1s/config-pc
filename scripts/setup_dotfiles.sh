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
