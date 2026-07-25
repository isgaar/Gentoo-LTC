#!/usr/bin/env bash
set -u

# Perfil de entorno exclusivo de MySway. SDDM ejecuta este archivo mediante
# /usr/local/bin/mysway-session; Plasma nunca lo carga.
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=mysway
export XDG_SESSION_TYPE=wayland
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM='wayland;xcb'
export MOZ_ENABLE_WAYLAND=1
export SDL_VIDEODRIVER=wayland
export TERMINAL=kitty
export XCURSOR_THEME=breeze_cursors
export XCURSOR_SIZE=24

# No heredar datos de una sesión KDE ni el display del greeter.
unset KDE_FULL_SESSION KDE_SESSION_UID KDE_SESSION_VERSION
unset KDED_FIRST_STARTUP QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE
unset DISPLAY WAYLAND_DISPLAY SWAYSOCK

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/mysway"
log_file="$state_dir/sway-session.log"
mkdir -p "$state_dir"

cleanup_session() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user stop xdg-desktop-portal-wlr.service >/dev/null 2>&1 || true
        systemctl --user unset-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK \
            XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
            >/dev/null 2>&1 || true
    fi
}
trap cleanup_session EXIT HUP INT TERM

{
    printf '\n[%s] MySway session start\n' "$(date --iso-8601=seconds)"
    printf 'Sway: '
    sway --version
    printf 'Desktop: %s / %s\n' "$XDG_CURRENT_DESKTOP" "$XDG_SESSION_DESKTOP"
} >>"$log_file" 2>&1

sway "$@" >>"$log_file" 2>&1
status=$?
printf '[%s] MySway session exit: %s\n' "$(date --iso-8601=seconds)" "$status" >>"$log_file"
exit "$status"
