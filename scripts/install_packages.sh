#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
[[ -z "${DISTRO_FAMILY:-}" ]] && source "$SCRIPT_DIR/detect_distro.sh"

log_step "Mise à jour du système"
if [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo apt update 2>&1 | grep -v "^W:" | grep -v "^N:" || true
    sudo apt upgrade -y
else
    eval "$PKG_UPDATE"
fi
log_success "Système à jour"

log_step "Installation des paquets communs"
PACKAGES=(
    zsh curl wget git htop btop tree unzip zip
    ripgrep fzf eza bat tmux neofetch
    xclip wl-clipboard jq neovim ranger rsync
    net-tools nmap pipx imagemagick
)

case "$DISTRO_FAMILY" in
    debian) PACKAGES+=(openssh-client) ;;
    arch)   PACKAGES+=(openssh) ;;
    rhel)   PACKAGES+=(openssh-clients) ;;
    suse)   PACKAGES+=(openssh-clients) ;;
esac

IFS=' ' read -ra _install_cmd <<< "$PKG_INSTALL"
"${_install_cmd[@]}" "${PACKAGES[@]}"
log_success "Paquets communs installés"

# Symlink batcat → bat sur Debian/Ubuntu
if [[ "$DISTRO_FAMILY" == "debian" ]] && cmd_exists batcat && ! cmd_exists bat; then
    log_info "Création du symlink bat → batcat"
    sudo ln -sf "$(which batcat)" /usr/local/bin/bat
    log_success "Symlink /usr/local/bin/bat créé"
fi

# ── Fastfetch ──────────────────────────────────────────────
install_fastfetch() {
    if cmd_exists fastfetch; then
        log_info "fastfetch déjà présent"
        return
    fi

    log_step "Installation de Fastfetch"

    local arch
    case "$(uname -m)" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="aarch64" ;;
        *)       arch="amd64" ;;
    esac

    case "$DISTRO_FAMILY" in
        arch)
            eval "$PKG_INSTALL fastfetch"
            ;;
        debian|rhel|suse)
            local tmp_dir
            tmp_dir=$(mktemp -d)
            local url="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${arch}.tar.gz"
            curl -Lo "$tmp_dir/fastfetch.tar.gz" "$url"
            sudo tar xf "$tmp_dir/fastfetch.tar.gz" \
                --strip-components=3 \
                -C /usr/local/bin \
                "fastfetch-linux-${arch}/usr/bin/fastfetch" 2>/dev/null \
                || sudo tar xf "$tmp_dir/fastfetch.tar.gz" \
                    --wildcards \
                    -O '*/fastfetch' | sudo tee /usr/local/bin/fastfetch > /dev/null
            sudo chmod +x /usr/local/bin/fastfetch
            rm -rf "$tmp_dir"
            ;;
    esac

    cmd_exists fastfetch \
        && log_success "fastfetch installé" \
        || log_warn "fastfetch : échec, installation manuelle requise"
}

# ── Ghostty ────────────────────────────────────────────────
install_ghostty() {
    if cmd_exists ghostty; then
        log_info "ghostty déjà présent"
        return
    fi

    log_step "Installation de Ghostty"

    case "$DISTRO_FAMILY" in
        arch)
            eval "$PKG_INSTALL ghostty"
            ;;
        debian)
            eval "$PKG_INSTALL" ghostty 2>/dev/null \
                && log_success "ghostty installé via apt" \
                || log_warn "ghostty non disponible sur apt — voir https://ghostty.org/docs/install/binary"
            ;;
        rhel)
            eval "$PKG_INSTALL ghostty" 2>/dev/null \
                || log_warn "ghostty non disponible — voir https://ghostty.org/docs/install"
            ;;
        suse)
            eval "$PKG_INSTALL ghostty" 2>/dev/null \
                || log_warn "ghostty non disponible — voir https://ghostty.org/docs/install"
            ;;
    esac

    cmd_exists ghostty \
        && log_success "ghostty installé" \
        || log_warn "ghostty : échec, voir https://ghostty.org/docs/install"
}

install_fastfetch
install_ghostty

log_step "Installation de Brave Browser"
if ! cmd_exists brave-browser; then
    log_info "Installation de Brave via le script officiel..."
    curl -fsS https://dl.brave.com/install.sh | sh
    log_success "Brave Browser installé"
else
    log_info "Brave Browser déjà présent"
fi

log_step "Installation de Spotify"
case "$DISTRO_FAMILY" in
    arch)
        if [[ -n "$AUR_HELPER" ]]; then
            if ! cmd_exists spotify; then
                $AUR_HELPER -S --noconfirm spotify \
                    && log_success "Spotify installé" \
                    || log_warn "Échec installation Spotify via $AUR_HELPER"
            else
                log_info "Spotify déjà présent"
            fi
        else
            log_warn "Aucun AUR helper disponible — Spotify sera installé via Flatpak"
        fi
        ;;
    *)
        log_info "Spotify sera installé via Flatpak (universel et fiable)"
        ;;
esac

log_step "Installation de Flatpak"
if ! cmd_exists flatpak; then
    log_info "Installation de Flatpak..."
    IFS=' ' read -ra _install_cmd <<< "$PKG_INSTALL"
    "${_install_cmd[@]}" flatpak
    log_success "Flatpak installé"
else
    log_info "Flatpak déjà présent"
fi

log_info "Ajout du dépôt Flathub..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
log_success "Flathub configuré"

log_step "Installation des applications Flatpak"
declare -A FLATPAK_APPS=(
    [com.discordapp.Discord]="Discord"
    [com.protonvpn.www]="ProtonVPN"
    [com.spotify.Client]="Spotify"
    [im.riot.Riot]="Element"
    [io.appflowy.AppFlowy]="AppFlowy"
    [me.proton.Mail]="Proton Mail"
    [org.localsend.localsend_app]="LocalSend"
    [org.onlyoffice.desktopeditors]="OnlyOffice"
)

for app_id in "${!FLATPAK_APPS[@]}"; do
    if flatpak list --app | grep -q "$app_id"; then
        log_info "${FLATPAK_APPS[$app_id]} déjà installé"
    else
        log_info "Installation de ${FLATPAK_APPS[$app_id]}..."
        flatpak install -y flathub "$app_id"
        log_success "${FLATPAK_APPS[$app_id]} installé"
    fi
done

log_success "Paquets système et applications installés"
