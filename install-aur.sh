#!/usr/bin/env bash
# yay + AUR-пакеты. Отдельно от install.sh, чтобы можно было запускать под VPN.
#   ./install-aur.sh                  # всё из pkglist/aur.txt
#   ./install-aur.sh throne-bin ...   # только указанные пакеты
set -euo pipefail

cd "$(dirname "$0")"

[[ $EUID -eq 0 ]] && { echo "запускай не от root"; exit 1; }

# --- yay ---
if ! command -v yay >/dev/null; then
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
fi

# --- AUR ---
if (($#)); then
    AUR=("$@")
else
    mapfile -t AUR < pkglist/aur.txt
fi
yay -S --needed "${AUR[@]}" || echo "!!! часть AUR-пакетов не собралась, см. вывод выше"

# --- сервисы из AUR-пакетов ---
if command -v netbird >/dev/null; then
    sudo netbird service install 2>/dev/null || true
    sudo systemctl enable netbird 2>/dev/null || true
fi
