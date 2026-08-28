#!/usr/bin/env bash
# ~/.config/sway/wallpaper-picker.sh
# Выбор обоев из нескольких папок + выбор монитора (или все) -> применение через awww.
# Требует: awww (или swww), fuzzel, imagemagick (миниатюры), jq (список выходов).
# Использование:
#   wallpaper-picker.sh                  # папки из DIRS, спросит монитор
#   wallpaper-picker.sh ~/dir1 ~/dir2    # папки аргументами

set -euo pipefail

# --- папки с обоями ---
DIRS=(
    "$HOME/Pictures/Wallpapers"
    "/usr/share/backgrounds/nordic-wallpapers-git"
)
[ "$#" -gt 0 ] && DIRS=("$@")

CACHE="$HOME/.cache/wallpaper-thumbs"
mkdir -p "$CACHE"

die() { command -v notify-send >/dev/null && notify-send "wallpaper" "$1"; printf '%s\n' "$1" >&2; exit 1; }

EXISTING=()
for d in "${DIRS[@]}"; do [ -d "$d" ] && EXISTING+=("$d"); done
[ "${#EXISTING[@]}" -gt 0 ] || die "Нет ни одной валидной папки с обоями"

# Бэкенд awww/swww + демон.
if   command -v awww >/dev/null; then WP=awww
elif command -v swww >/dev/null; then WP=swww
else die "Не найден ни awww, ни swww"
fi
pgrep -x "${WP}-daemon" >/dev/null || { "${WP}-daemon" >/dev/null 2>&1 & sleep 0.5; }

# --- 1. Выбор монитора ---
# Список активных выходов; добавляем псевдо-вариант "все".
OUT_ARGS=()   # аргументы для awww: пусто = все, иначе -o NAME
if command -v jq >/dev/null; then
    mapfile -t OUTPUTS < <(hyprctl monitors -j | jq -r '.[].name')
    if [ "${#OUTPUTS[@]}" -gt 1 ]; then
        choice=$(printf 'все мониторы\n%s\n' "$(printf '%s\n' "${OUTPUTS[@]}")" \
                 | fuzzel --dmenu --prompt 'output> ') || exit 0
        [ -z "${choice:-}" ] && exit 0
        [ "$choice" != "все мониторы" ] && OUT_ARGS=(-o "$choice")
    fi
fi

# --- 2. ImageMagick для миниатюр ---
if   command -v magick  >/dev/null; then IM=(magick);
elif command -v convert >/dev/null; then IM=(convert);
else IM=(); fi

icon_for() {
    local src="$1"
    [ "${#IM[@]}" -eq 0 ] && { printf '%s' "$src"; return; }
    local key thumb
    key="$(printf '%s' "$src" | md5sum | cut -d' ' -f1)"
    thumb="$CACHE/$key.png"
    if [ ! -f "$thumb" ] || [ "$src" -nt "$thumb" ]; then
        "${IM[@]}" "$src" -thumbnail 256x256 "$thumb" 2>/dev/null || { printf '%s' "$src"; return; }
    fi
    printf '%s' "$thumb"
}

# --- 3. Сбор картинок и выбор обоев ---
mapfile -d '' -t FILES < <(
    find "${EXISTING[@]}" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) \
        -print0 | sort -z
)
[ "${#FILES[@]}" -gt 0 ] || die "В папках нет картинок"

declare -A SEEN=()
for f in "${FILES[@]}"; do b="$(basename "$f")"; SEEN[$b]=$(( ${SEEN[$b]:-0} + 1 )); done

idx=$(
    for f in "${FILES[@]}"; do
        b="$(basename "$f")"
        label="$b"
        [ "${SEEN[$b]}" -gt 1 ] && label="$b  ($(basename "$(dirname "$f")"))"
        printf '%s\0icon\x1f%s\n' "$label" "$(icon_for "$f")"
    done | fuzzel --dmenu --index --prompt 'wallpaper> '
) || exit 0
[ -z "${idx:-}" ] && exit 0

# --- 4. Применение (OUT_ARGS пуст = все мониторы) ---
"$WP" img "${OUT_ARGS[@]}" "${FILES[$idx]}" \
    --transition-type center \
    --transition-fps 60 \
    --transition-duration 1
