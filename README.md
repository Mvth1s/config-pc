# linux-setup

Configuration automatisée d'une nouvelle machine Linux en une seule commande.

## Distributions supportées

| Distribution | Famille | Package manager |
|---|---|---|
| Arch, EndeavourOS, Manjaro, Garuda, CachyOS | arch | pacman |
| Debian, Ubuntu, Pop!_OS, Linux Mint, Elementary, Kali, Zorin | debian | apt |
| Fedora | rhel | dnf |
| openSUSE, SLES, SLED | suse | zypper |

## Arborescence

```
linux-setup/
├── setup.sh                  # Point d'entrée principal
├── scripts/
│   ├── utils.sh              # Fonctions log_*, cmd_exists, confirm
│   ├── detect_distro.sh      # Détection distro + variables PKG_*
│   ├── install_packages.sh   # Paquets système + Brave + Spotify + Flatpak
│   ├── setup_dotfiles.sh     # Symlinks config + zinit + oh-my-posh
│   ├── setup_git_ssh.sh      # Git global + clé SSH ed25519
│   ├── setup_security.sh     # UFW + DNS Quad9
│   └── setup_dev_tools.sh    # nvm/Node, pnpm, Docker, Ollama, Zed
├── fastfetch/                # Config fastfetch
├── ghostty/                  # Config terminal Ghostty
├── zed/                      # Config éditeur Zed
└── zsh/
    ├── .zshrc                # Config zsh (zinit + oh-my-posh)
    └── .aliases              # Aliases shell
```

## Démarrage rapide

```bash
git clone https://github.com/Mvth1s/linux-setup.git
chmod +x linux-setup/setup.sh linux-setup/scripts/*.sh
./linux-setup/setup.sh
```

## Ce qui est installé

### Paquets système
`zsh` `curl` `wget` `git` `htop` `btop` `tree` `ripgrep` `fzf` `eza` `bat` `tmux` `neofetch` `jq` `neovim` `ranger` `rsync` `nmap` `pipx` `imagemagick`

### Applications natives
- **Brave Browser** — navigateur axé vie privée (script officiel)
- **Spotify** — musique (dépôt officiel sur Debian/Ubuntu, AUR sur Arch)

### Applications Flatpak
| Application | Description |
|---|---|
| **Discord** | Messagerie communautaire |
| **ProtonVPN** | VPN chiffré |
| **Element** | Client Matrix (messagerie chiffrée) |
| **AppFlowy** | Notes et gestion de projets |
| **Proton Mail** | Messagerie chiffrée |
| **LocalSend** | Partage de fichiers en réseau local |
| **OnlyOffice** | Suite bureautique compatible Office |

### Outils développeur
- **nvm** + Node.js LTS + **pnpm**
- **Docker** + Compose
- **Ollama** — modèles LLM en local
- **Zed** — éditeur de code performant

### Shell & terminal
- **zinit** — gestionnaire de plugins zsh
- **oh-my-posh** — prompt configurable
- **zsh-autosuggestions**, **zsh-syntax-highlighting**, **zsh-completions** (via zinit)

### Sécurité
- **UFW** — pare-feu (entrée bloquée, SSH autorisé)
- **DNS Quad9** — résolveur sécurisé avec DNSSEC

## Personnalisation

**Ajouter un paquet système** : modifier le tableau `PACKAGES` dans `scripts/install_packages.sh`.

**Ajouter une application Flatpak** : ajouter l'ID dans le tableau `FLATPAK_APPS` de `scripts/install_packages.sh`.

**Modifier les aliases** : éditer `zsh/.aliases` — le symlink `~/.aliases` sera mis à jour automatiquement.
