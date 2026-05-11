#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
[[ -z "${DISTRO_FAMILY:-}" ]] && source "$SCRIPT_DIR/detect_distro.sh"

log_step "Installation de nvm + Node.js LTS"

if [[ ! -d "$HOME/.nvm" ]]; then
    log_info "Récupération de la dernière version de nvm..."
    nvm_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    log_info "Installation de nvm $nvm_version..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
    log_success "nvm installé"
else
    log_info "nvm déjà présent"
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

if ! nvm ls --no-colors lts/* &>/dev/null 2>&1; then
    log_info "Installation de Node.js LTS..."
    nvm install --lts
    nvm use --lts
    log_success "Node.js LTS installé : $(node --version)"
else
    log_info "Node.js LTS déjà installé"
fi

log_step "Installation de pnpm"
if ! cmd_exists pnpm; then
    log_info "Installation de pnpm..."
    npm install -g pnpm
    log_success "pnpm installé : $(pnpm --version)"
else
    log_info "pnpm déjà présent"
fi

log_step "Installation de Docker"

if ! cmd_exists docker; then
    log_info "Installation de Docker..."
    case "$DISTRO_FAMILY" in
        arch)
            IFS=' ' read -ra _install_cmd <<< "$PKG_INSTALL"
            "${_install_cmd[@]}" docker docker-compose
            ;;
        debian)
            curl -fsSL https://get.docker.com | sudo sh
            sudo apt install -y docker-compose-plugin
            ;;
        rhel)
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        suse)
            sudo zypper install -y docker docker-compose
            ;;
    esac
    log_success "Docker installé"
else
    log_info "Docker déjà présent"
fi

sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
log_success "Docker activé — re-login requis pour l'utiliser sans sudo"

log_step "Installation d'Ollama"
if ! cmd_exists ollama; then
    log_info "Installation d'Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    log_success "Ollama installé"
else
    log_info "Ollama déjà présent"
fi

log_step "Installation de Zed"
if ! cmd_exists zed; then
    log_info "Installation de Zed..."
    curl -fsSL https://zed.dev/install.sh | sh
    log_success "Zed installé"
else
    log_info "Zed déjà présent"
fi

log_success "Outils de développement installés"
