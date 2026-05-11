# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Objectif

Créer un système de scripts bash de configuration automatisée pour Linux.
Les scripts doivent permettre de configurer n'importe quelle nouvelle machine Linux en une seule commande.

---

## État actuel du dépôt

### Fichiers déjà présents (ne pas modifier)

```
fastfetch/config.jsonc          ← chemin logo hardcodé /home/mathis/... à garder tel quel
fastfetch/Chibi-Anime-PNG-Transparent-Image.png
ghostty/config.ghostty
zed/settings.json
zed/themes/
zsh/.zshrc                      ← utilise oh-my-posh + zinit (voir note ci-dessous)
zsh/.aliases                    ← déjà créé
```

### Note importante sur zsh/.zshrc

Le `.zshrc` existant utilise **oh-my-posh** (pas starship) et **zinit** (qui gère automatiquement les plugins zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions). Il inclut aussi `PATH lmstudio` et `DOCKER_BUILDKIT=1`. **Ne pas écraser ce fichier.**

### Fichiers à créer ou mettre à jour

```
setup.sh
scripts/utils.sh
scripts/detect_distro.sh
scripts/install_packages.sh     ← voir corrections ci-dessous
scripts/setup_dotfiles.sh       ← voir corrections ci-dessous
scripts/setup_git_ssh.sh
scripts/setup_security.sh
scripts/setup_dev_tools.sh      ← voir corrections ci-dessous
.gitignore
README.md
```

---

## Architecture et dépendances entre scripts

```
setup.sh
 ├── source scripts/utils.sh
 ├── source scripts/detect_distro.sh
 └── bash scripts/<module>.sh

scripts/utils.sh          ← aucune dépendance
scripts/detect_distro.sh  ← dépend de utils.sh
scripts/install_packages.sh  ← dépend de detect_distro.sh
scripts/setup_dotfiles.sh    ← indépendant
scripts/setup_git_ssh.sh     ← indépendant
scripts/setup_security.sh    ← dépend de detect_distro.sh
scripts/setup_dev_tools.sh   ← dépend de detect_distro.sh
```

Chaque sous-script recharge `detect_distro.sh` si `DISTRO_FAMILY` n'est pas défini :
```bash
[[ -z "${DISTRO_FAMILY:-}" ]] && source "$(dirname "$0")/detect_distro.sh"
```

---

## Règles communes à tous les scripts

- Shebang : `#!/usr/bin/env bash`
- `set -euo pipefail` dans chaque script
- Toujours vérifier si un outil est déjà installé avant de l'installer (`cmd_exists`)
- Jamais d'`echo` brut : tous les messages passent par les fonctions de `utils.sh`
- Permissions finales : `setup.sh` et `scripts/*.sh` → `755`, dotfiles → `644`

---

## scripts/utils.sh

| Fonction | Comportement |
|---|---|
| `log_info <msg>` | `[INFO]` en bleu |
| `log_success <msg>` | `[OK]` en vert |
| `log_warn <msg>` | `[WARN]` en jaune |
| `log_error <msg>` | `[ERROR]` en rouge sur stderr |
| `log_step <msg>` | séparateur visuel bold/cyan |
| `cmd_exists <cmd>` | `command -v "$1" &>/dev/null` |
| `confirm <prompt>` | demande `[y/N]`, retourne 0 si oui |

Variables couleurs ANSI : `RED GREEN YELLOW BLUE CYAN BOLD RESET`

---

## scripts/detect_distro.sh

Détection via `/etc/os-release` (`ID` puis `ID_LIKE` en fallback).

| Famille | Distros reconnues | Package manager |
|---|---|---|
| `arch` | arch, endeavouros, manjaro, garuda, cachyos | pacman |
| `debian` | debian, ubuntu, pop, linuxmint, elementary, kali, zorin | apt |
| `rhel` | fedora | dnf |
| `suse` | opensuse*, sles, sled | zypper |

Variables exportées : `DISTRO_ID`, `DISTRO_FAMILY`, `PKG_MANAGER`, `PKG_INSTALL`, `PKG_UPDATE`, `AUR_HELPER`

- `PKG_INSTALL` inclut les flags silencieux (`--noconfirm`, `-y`, etc.)
- `AUR_HELPER` : détecter `yay` puis `paru` (Arch uniquement)
- Distribution non reconnue → `log_error` explicite + `exit 1`

---

## scripts/install_packages.sh

### Étape 1 — Mise à jour système
```bash
eval "$PKG_UPDATE"
```

### Étape 2 — Paquets communs
```
zsh curl wget git htop btop tree unzip zip
ripgrep fzf eza bat tmux neofetch openssh
xclip wl-clipboard jq neovim ranger rsync
net-tools nmap pipx imagemagick
```

Cas particulier Debian/Ubuntu : `bat` s'appelle `batcat` → créer un lien `/usr/local/bin/bat → batcat` si `bat` n'existe pas déjà.

### Étape 3 — Brave Browser (⚠️ PAS via Flatpak)

Brave s'installe via son script officiel (fonctionne sur toutes les familles) :
```bash
if ! cmd_exists brave-browser; then
  curl -fsS https://dl.brave.com/install.sh | sh
fi
```

### Étape 4 — Spotify

- **Debian/Ubuntu** :
  ```bash
  curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg \
    | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  echo "deb http://repository.spotify.com stable non-free" \
    | sudo tee /etc/apt/sources.list.d/spotify.list
  sudo apt update && sudo apt install -y spotify-client
  ```
- **Arch** : `$AUR_HELPER -S spotify` (si AUR_HELPER disponible, sinon `log_warn`)
- **Autres familles** : `log_warn "Spotify non disponible nativement sur cette distribution"`

### Étape 5 — Flatpak

1. Installer Flatpak si absent (via le package manager natif)
2. Ajouter Flathub : `flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`
3. Installer chaque app seulement si absente (`flatpak list --app | grep -q <id>`)

**Liste des apps Flatpak :**
```
com.discordapp.Discord          # Discord
com.protonvpn.www               # ProtonVPN
im.riot.Riot                    # Element (client Matrix)
io.appflowy.AppFlowy            # AppFlowy (notes / gestion de projets)
me.proton.Mail                  # Proton Mail
org.localsend.localsend_app     # LocalSend (partage fichiers local)
org.onlyoffice.desktopeditors   # OnlyOffice
```

> ⚠️ VSCodium n'est PAS à installer — Zed est l'éditeur principal.

---

## scripts/setup_dotfiles.sh

**Fonction `link_config <src> <dest>`** :
1. Créer le répertoire parent si nécessaire
2. Si `<dest>` existe et n'est pas un symlink → backup dans `~/.dotfiles_backup/<timestamp>/`
3. `ln -sf "<src_absolu>" "<dest>"`

**Symlinks à créer** :

| Source (dans le repo) | Destination |
|---|---|
| `fastfetch/` | `~/.config/fastfetch` |
| `ghostty/` | `~/.config/ghostty` |
| `zed/` | `~/.config/zed` |
| `zsh/.zshrc` | `~/.zshrc` |
| `zsh/.aliases` | `~/.aliases` |

> ⚠️ Ne PAS cloner manuellement zsh-autosuggestions, zsh-syntax-highlighting ou zsh-completions.
> Zinit les gère automatiquement au premier lancement de zsh.

**oh-my-posh** — installer si absent :
```bash
if ! cmd_exists oh-my-posh; then
  curl -s https://ohmyposh.dev/install.sh | bash -s
  log_success "oh-my-posh installé"
fi
```

> ⚠️ Ne PAS installer Starship — oh-my-posh est utilisé.

**zinit** — pré-installer si absent (s'auto-installe aussi via .zshrc au premier lancement) :
```bash
ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME"
  log_success "zinit installé"
fi
```

**Shell par défaut** : si `$SHELL` n'est pas zsh, proposer via `confirm` de lancer `chsh -s "$(which zsh)"`

---

## scripts/setup_git_ssh.sh

**Configuration Git (interactive)**
- Lire les valeurs actuelles (les afficher comme défaut)
- Configurer : `user.name`, `user.email`, `init.defaultBranch=main`, `pull.rebase=false`, `color.ui=auto`

**Clé SSH**
- Type : `ed25519`, chemin : `~/.ssh/id_ed25519`
- Si la clé existe → `log_warn` + `confirm` avant d'écraser
- Permissions : `700` sur `~/.ssh/`, `600` clé privée, `644` clé publique
- Ajouter au ssh-agent
- Copier dans le presse-papiers : priorité `wl-copy` (Wayland), sinon `xclip`
- Afficher le lien : `https://github.com/settings/ssh/new`

---

## scripts/setup_security.sh

**UFW**
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable
```
Installer UFW si absent via `$PKG_INSTALL`.

**DNS Quad9**
- Si `systemd-resolved` actif → créer `/etc/systemd/resolved.conf.d/quad9.conf` :
  ```ini
  [Resolve]
  DNS=9.9.9.9 149.112.112.112
  FallbackDNS=1.1.1.1 1.0.0.1
  DNSSEC=yes
  DNSOverTLS=opportunistic
  ```
  Puis `sudo systemctl restart systemd-resolved`
- Sinon → backup + écriture directe dans `/etc/resolv.conf`

**Services crash-report** (avec `|| true`) :
```bash
sudo systemctl disable --now apport.service  2>/dev/null || true
sudo systemctl disable --now whoopsie.service 2>/dev/null || true
```

---

## scripts/setup_dev_tools.sh

### nvm + Node LTS
```bash
nvm_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4)
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install --lts && nvm use --lts
```

### pnpm (après Node, obligatoire)
```bash
if ! cmd_exists pnpm; then
  npm install -g pnpm
  log_success "pnpm installé : $(pnpm --version)"
fi
```

### Docker

| Famille | Commande |
|---|---|
| arch | `pacman -S docker docker-compose` |
| debian | `curl -fsSL https://get.docker.com \| sudo sh` + `apt install docker-compose-plugin` |
| rhel | `dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin` |
| suse | `zypper install docker docker-compose` |

Puis : `sudo systemctl enable --now docker` + `sudo usermod -aG docker "$USER"`

### Ollama
```bash
if ! cmd_exists ollama; then
  curl -fsSL https://ollama.com/install.sh | sh
fi
```

### Zed
```bash
if ! cmd_exists zed; then
  curl -fsSL https://zed.dev/install.sh | sh
fi
```

---

## zsh/.aliases

Le fichier existe déjà — ne pas l'écraser. S'assurer qu'il contient :
- Navigation : `..`, `...`
- ls → eza avec fallback ls classique
- cat → bat avec fallback
- Git : `g, gs, ga, gc, gp, gl, gd, glog, gco, gb`
- Docker : `d, dc, dps, dpsa, dclean`
- Système : `myip, ports, df, du, free`
- Misc : `reload`, `please`, `mkcd`

---

## setup.sh (menu principal)

1. Sourcer `scripts/utils.sh` puis `scripts/detect_distro.sh`
2. Afficher une bannière ASCII avec le nom du projet et la date
3. Menu interactif :
   ```
   [1] Tout installer
   [2] Paquets système + Flatpak
   [3] Dotfiles
   [4] Git & SSH
   [5] Sécurité
   [6] Outils dev
   [q] Quitter
   ```
4. Option 1 : enchaîner dans l'ordre `install → dotfiles → git_ssh → security → dev_tools`
5. Options 2-6 : lancer via `bash "$SCRIPT_DIR/scripts/<script>.sh"`
6. Message de fin avec rappel des actions manuelles :
   - Re-login pour Docker (`newgrp docker`)
   - Ajouter la clé SSH sur GitHub
   - Redémarrer le terminal pour zsh (zinit télécharge les plugins au premier lancement)

---

## .gitignore

```
.env
*.pem
*.key
*.log
.dotfiles_backup/
```

---

## README.md

Sections :
1. Description courte (une ligne)
2. Tableau des distributions supportées
3. Arborescence du projet
4. Démarrage rapide (3 commandes : clone, chmod, ./setup.sh)
5. Ce qui est installé (paquets système, Brave, Spotify, apps Flatpak, outils dev, sécurité)
6. Personnalisation (modifier les dotfiles, ajouter un paquet ou une app Flatpak)
