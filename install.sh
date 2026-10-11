#!/usr/bin/env bash
# Bootstrap свежего Arch: пакеты, AUR, dotfiles, сервисы.
# Запускать от обычного пользователя (с sudo) из корня репозитория: ./install.sh
set -euo pipefail

cd "$(dirname "$0")"
REPO=$PWD

[[ $EUID -eq 0 ]] && { echo "запускай не от root"; exit 1; }

# --- pacman.conf: multilib, цвет, параллельная загрузка ---
sudo sed -i \
    -e 's/^#Color/Color/' \
    -e 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' \
    -e '/^#\[multilib\]/,/^#Include/ s/^#//' \
    /etc/pacman.conf
sudo pacman -Syu --noconfirm

# --- железо: микрокод и vulkan-драйвер ---
HW=()
grep -q AuthenticAMD /proc/cpuinfo && HW+=(amd-ucode)
grep -q GenuineIntel /proc/cpuinfo && HW+=(intel-ucode)
GPU=$(lspci | grep -iE 'vga|3d|display' || true)
grep -qi amd    <<<"$GPU" && HW+=(vulkan-radeon lib32-vulkan-radeon amdgpu_top)
grep -qi intel  <<<"$GPU" && HW+=(vulkan-intel lib32-vulkan-intel intel-media-driver)
grep -qi nvidia <<<"$GPU" && HW+=(nvidia-open nvidia-utils lib32-nvidia-utils)

# --- пакеты из официальных репо ---
mapfile -t NATIVE < pkglist/native.txt
sudo pacman -S --needed "${HW[@]}" "${NATIVE[@]}"

# --- toolchains ---
rustup default stable
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
cargo install asm-lsp protols || true

# --- dotfiles ---
rsync -a \
    --exclude .git --exclude .gitignore --exclude pkglist --exclude etc \
    --exclude install.sh --exclude install-aur.sh \
    "$REPO"/ "$HOME"/
xdg-user-dirs-update

# автологин-подсказка в tty1 (имя пользователя подставляем текущее)
sudo install -Dm644 /dev/stdin /etc/systemd/system/getty@tty1.service.d/skip-username.conf \
    < <(sed "s/blackbloodredkiss/$USER/" etc/systemd/system/getty@tty1.service.d/skip-username.conf)

# --- shell и группы ---
[[ $(getent passwd "$USER" | cut -d: -f7) == /usr/bin/fish ]] || chsh -s /usr/bin/fish
for g in wheel docker wireshark vboxusers uucp kvm; do
    getent group "$g" >/dev/null && sudo usermod -aG "$g" "$USER"
done

# --- сервисы ---
sudo systemctl enable NetworkManager bluetooth tlp docker.socket tailscaled
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket  # требование tlp

cat <<'EOF'

Готово. Дальше:
  1. ./install-aur.sh (AUR-пакеты, можно под VPN)
  2. reboot, логин в tty1 -> fish сам запустит Hyprland через uwsm
  3. внутри Hyprland:
       hyprpm update
       hyprpm add https://github.com/kociap/hy3
       hyprpm enable hy3
       hyprctl reload
  4. поправить мониторы в ~/.config/hypr/hyprland.lua (hl.monitor)
EOF
