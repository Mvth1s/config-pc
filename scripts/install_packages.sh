#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
[[ -z "${DISTRO_FAMILY:-}" ]] && source "$SCRIPT_DIR/detect_distro.sh"

log_step "Mise à jour du système"
eval "$PKG_UPDATE"
log_success "Système à jour"

log_step "Installation des paquets communs"
PACKAGES=(
    zsh curl wget git htop btop tree unzip zip
    ripgrep fzf eza bat tmux neofetch openssh
    xclip wl-clipboard jq neovim ranger rsync
    net-tools nmap pipx imagemagick
)

if [[ "$DISTRO_FAMILY" == "debian" ]]; then
    PACKAGES=("${PACKAGES[@]/openssh/openssh-client}")
fi

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
        debian)
            local url
            url=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
                | grep "browser_download_url.*linux_${arch}\.deb" | cut -d'"' -f4)
            curl -Lo /tmp/fastfetch.deb "$url"
            sudo dpkg -i /tmp/fastfetch.deb
            rm /tmp/fastfetch.deb
            ;;
        rhel)
            local url
            url=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
                | grep "browser_download_url.*linux_${arch}\.rpm" | cut -d'"' -f4)
            curl -Lo /tmp/fastfetch.rpm "$url"
            sudo rpm -i /tmp/fastfetch.rpm
            rm /tmp/fastfetch.rpm
            ;;
        suse)
            eval "$PKG_INSTALL fastfetch" 2>/dev/null || {
                local url
                url=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
                    | grep "browser_download_url.*linux_${arch}\.rpm" | cut -d'"' -f4)
                curl -Lo /tmp/fastfetch.rpm "$url"
                sudo rpm -i /tmp/fastfetch.rpm
                rm /tmp/fastfetch.rpm
            }
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
            sudo apt install -y software-properties-common
            sudo add-apt-repository -y ppa:glasen/ghostty
            sudo apt update && sudo apt install -y ghostty
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
    debian)
        if ! cmd_exists spotify; then
            log_info "Ajout du dépôt Spotify..."
            curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg \
                | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
            echo "deb http://repository.spotify.com stable non-free" \
                | sudo tee /etc/apt/sources.list.d/spotify.list
            sudo apt update && sudo apt install -y spotify-client
            log_success "Spotify installé"
        else
            log_info "Spotify déjà présent"
        fi
        ;;
    arch)
        if [[ -n "$AUR_HELPER" ]]; then
            if ! cmd_exists spotify; then
                log_info "Installation de Spotify via $AUR_HELPER..."
                $AUR_HELPER -S --noconfirm spotify
                log_success "Spotify installé"
            else
                log_info "Spotify déjà présent"
            fi
        else
            log_warn "Aucun AUR helper disponible — installez Spotify manuellement"
        fi
        ;;
    *)
        log_warn "Spotify non disponible nativement sur cette distribution"
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
