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
    PACKAGES=("${PACKAGES[@]/bat/batcat}")
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
