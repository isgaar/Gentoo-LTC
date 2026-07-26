#!/usr/bin/env bash
# Termina de aplicar Orizaba cuando ya existe una sesión real de Plasma.

set -Eeuo pipefail
umask 077

THEME_ID="Orizaba"
PROFILE_ROOT="${GENTOO_HP_KDE_PROFILE_ROOT:-/usr/local/share/gentoo-hp/kde/orizaba}"
HOME_TARGET="${HOME:?HOME no está definido}"
DATA_TARGET="${XDG_DATA_HOME:-$HOME_TARGET/.local/share}"
STATE_TARGET="${XDG_STATE_HOME:-$HOME_TARGET/.local/state}"
STATE_DIR="$STATE_TARGET/gentoo-hp"
PROFILE_MARKER="$STATE_DIR/kde-profile.sha256"
FIRST_LOGIN_MARKER="$STATE_DIR/kde-first-login.sha256"
LOCK_FILE="$STATE_DIR/kde-first-login.lock"
THEME_ROOT="$DATA_TARGET/plasma/look-and-feel/$THEME_ID"
WALLPAPER_FILE="$THEME_ROOT/contents/assets/usr/share/wallpapers/Path/contents/images/2560x1600.jpg"

log() {
    printf 'Gentoo-HP KDE: %s\n' "$*"
}

die() {
    log "$*" >&2
    exit 1
}

((EUID != 0)) || exit 0

case "${XDG_CURRENT_DESKTOP:-KDE}" in
    *KDE*|*Plasma*)
        ;;
    *)
        exit 0
        ;;
esac

command -v realpath >/dev/null || die "falta realpath"
command -v sha256sum >/dev/null || die "falta sha256sum"
command -v plasma-apply-lookandfeel >/dev/null \
    || die "falta plasma-apply-lookandfeel"
command -v plasma-apply-wallpaperimage >/dev/null \
    || die "falta plasma-apply-wallpaperimage"

[[ "$DATA_TARGET" == /* && "$STATE_TARGET" == /* ]] \
    || die "las rutas XDG deben ser absolutas"
[[ "$(realpath -m -- "$DATA_TARGET")" != "/" \
    && "$(realpath -m -- "$STATE_TARGET")" != "/" ]] \
    || die "las rutas XDG no pueden apuntar a /"
[[ -f "$PROFILE_ROOT/SHA256SUMS" ]] || exit 0
[[ -f "$PROFILE_MARKER" ]] || exit 0
[[ -f "$THEME_ROOT/metadata.json" ]] \
    || die "el tema Orizaba no está instalado para este usuario"
[[ -f "$WALLPAPER_FILE" ]] \
    || die "el fondo Path no está instalado"
[[ ! -L "$STATE_DIR" && ! -L "$PROFILE_MARKER" \
    && ! -L "$FIRST_LOGIN_MARKER" && ! -L "$LOCK_FILE" \
    && ! -L "$THEME_ROOT" ]] \
    || die "se rechazó un enlace simbólico en una ruta protegida"
[[ ! -e "$LOCK_FILE" || -f "$LOCK_FILE" ]] \
    || die "el bloqueo de primera sesión no es un archivo regular"

expected_digest="$(sha256sum "$PROFILE_ROOT/SHA256SUMS" | awk '{print $1}')"
read -r applied_digest < "$PROFILE_MARKER"
[[ "$applied_digest" == "$expected_digest" ]] || exit 0

previous_digest=""
if [[ -f "$FIRST_LOGIN_MARKER" ]]; then
    read -r previous_digest < "$FIRST_LOGIN_MARKER"
fi
[[ "$previous_digest" != "$expected_digest" ]] || exit 0

mkdir -p -- "$STATE_DIR"
exec 9>>"$LOCK_FILE"
if command -v flock >/dev/null && ! flock -n 9; then
    exit 0
fi

log "aplicando Orizaba y reconstruyendo el diseño de Plasma"
plasma-apply-lookandfeel --apply "$THEME_ID" --resetLayout \
    || die "Plasma no pudo aplicar el tema global"
plasma-apply-wallpaperimage \
    --fill-mode preserveAspectCrop \
    "$WALLPAPER_FILE" \
    || die "Plasma no pudo aplicar el fondo"

marker_tmp="$(mktemp "$STATE_DIR/.kde-first-login.XXXXXX")"
trap 'rm -f -- "${marker_tmp-}"' EXIT
printf '%s\n' "$expected_digest" > "$marker_tmp"
chmod 0600 "$marker_tmp"
mv -fT -- "$marker_tmp" "$FIRST_LOGIN_MARKER"
trap - EXIT

log "configuración de la primera sesión completada"
