#!/usr/bin/env bash
# Aplica el perfil KDE portable y saneado de Gentoo-HP.

set -Eeuo pipefail
umask 077

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

THEME_ID="Orizaba"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -d "$SCRIPT_DIR/snapshot" ]]; then
    SOURCE_DIR="$SCRIPT_DIR/snapshot"
else
    SOURCE_DIR="${GENTOO_HP_KDE_SOURCE:-/usr/local/share/gentoo-hp/kde/orizaba}"
fi
HOME_TARGET="${ORIZABA_HOME_TARGET:-$HOME}"
CONFIG_TARGET="${XDG_CONFIG_HOME:-$HOME_TARGET/.config}"
DATA_TARGET="${XDG_DATA_HOME:-$HOME_TARGET/.local/share}"
STATE_TARGET="${XDG_STATE_HOME:-$HOME_TARGET/.local/state}"
RESTART_PLASMA=true
PROFILE_DIGEST=""
SKIP_IF_APPLIED=false
PLASMA_WAS_STOPPED=false
PLASMA_STOP_METHOD=""

usage() {
    cat <<'EOF'
Uso: gentoo-hp-apply-kde [opciones]

Opciones:
  --source RUTA     Usa otro snapshot.
  --no-restart      Copia todo sin reiniciar plasmashell; exige cerrar sesión.
  --profile-digest SHA256
                    Registra el digest aplicado como el usuario actual.
  --skip-if-applied Omite la importación si ese digest ya está registrado.
  -h, --help        Muestra esta ayuda.

Antes de sobrescribir se crea un respaldo de reversión en:
~/.local/state/gentoo-hp/kde-restore/
EOF
}

log() {
    printf '%b→%b %s\n' "$BLUE" "$NC" "$*"
}

ok() {
    printf '  [%bOK%b] %s\n' "$GREEN" "$NC" "$*"
}

warn() {
    printf '  [%bAVISO%b] %s\n' "$YELLOW" "$NC" "$*" >&2
}

die() {
    printf '%b✘%b %s\n' "$RED" "$NC" "$*" >&2
    exit 1
}

while (($# > 0)); do
    case "$1" in
        --source)
            (($# >= 2)) || die "Falta la ruta después de --source."
            SOURCE_DIR="$2"
            shift 2
            ;;
        --no-restart)
            RESTART_PLASMA=false
            shift
            ;;
        --profile-digest)
            (($# >= 2)) || die "Falta el SHA-256 después de --profile-digest."
            PROFILE_DIGEST="$2"
            shift 2
            ;;
        --skip-if-applied)
            SKIP_IF_APPLIED=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Opción desconocida: $1"
            ;;
    esac
done

command -v realpath >/dev/null || die "Se requiere el comando realpath."
command -v rsync >/dev/null || die "Se requiere el comando rsync."
((EUID != 0)) || die "Ejecuta este importador como el usuario de KDE, sin sudo."
if [[ -n "$PROFILE_DIGEST" ]]; then
    [[ "$PROFILE_DIGEST" =~ ^[[:xdigit:]]{64}$ ]] \
        || die "--profile-digest exige exactamente 64 dígitos hexadecimales."
    PROFILE_DIGEST="${PROFILE_DIGEST,,}"
elif [[ "$SKIP_IF_APPLIED" == true ]]; then
    die "--skip-if-applied exige --profile-digest."
fi

validate_target_root() {
    local variable_name="$1"
    local target_path="$2"
    local canonical_path

    [[ -n "$target_path" ]] || die "$variable_name no puede estar vacío."
    [[ "$target_path" == /* ]] || die "$variable_name debe ser una ruta absoluta."
    [[ "$target_path" != *$'\n'* && "$target_path" != *$'\r'* ]] \
        || die "$variable_name no puede contener saltos de línea."
    canonical_path="$(realpath -m -- "$target_path")"
    [[ "$canonical_path" != "/" ]] || die "$variable_name no puede apuntar a /."
}

paths_overlap() {
    local first_path="${1%/}"
    local second_path="${2%/}"

    [[ "$first_path" == "$second_path" \
        || "$first_path" == "$second_path/"* \
        || "$second_path" == "$first_path/"* ]]
}

path_is_at_or_below() {
    local child_path="${1%/}"
    local parent_path="${2%/}"

    [[ "$child_path" == "$parent_path" || "$child_path" == "$parent_path/"* ]]
}

validate_target_root HOME_TARGET "$HOME_TARGET"
validate_target_root CONFIG_TARGET "$CONFIG_TARGET"
validate_target_root DATA_TARGET "$DATA_TARGET"
validate_target_root STATE_TARGET "$STATE_TARGET"

SOURCE_DIR="$(realpath -m -- "$SOURCE_DIR")"
[[ -d "$SOURCE_DIR" ]] || die "No se encontró el snapshot $SOURCE_DIR"
[[ "$SOURCE_DIR" != "/" ]] || die "El snapshot no puede ser el directorio raíz."
if find "$SOURCE_DIR" -type l -print -quit | grep -q .; then
    die "El perfil contiene enlaces simbólicos; se rechaza por seguridad."
fi

if [[ -f "$SOURCE_DIR/SHA256SUMS" ]]; then
    command -v sha256sum >/dev/null || die "Se requiere el comando sha256sum."
    log "Verificando la integridad del snapshot..."
    declared_files="$(
        sed -n 's/^[[:xdigit:]]\{64\}  //p' "$SOURCE_DIR/SHA256SUMS" \
            | LC_ALL=C sort
    )"
    actual_files="$(
        cd -- "$SOURCE_DIR" || die "No se pudo abrir el snapshot."
        find . -type f ! -path './SHA256SUMS' -print | LC_ALL=C sort
    )"
    [[ "$declared_files" == "$actual_files" ]] \
        || die "SHA256SUMS no cubre exactamente los archivos del snapshot."
    if (
        cd -- "$SOURCE_DIR" || exit 1
        sha256sum --check --quiet --strict SHA256SUMS
    ); then
        ok "sumas SHA-256 correctas"
    else
        die "El snapshot está incompleto o fue modificado."
    fi
fi

if [[ -d "$SOURCE_DIR/config" ]]; then
    CONFIG_SOURCE="$SOURCE_DIR/config"
else
    # Compatibilidad con los snapshots antiguos de cuatro archivos.
    CONFIG_SOURCE="$SOURCE_DIR"
fi

THEME_SOURCE="$SOURCE_DIR/$THEME_ID"
THEME_TARGET="$DATA_TARGET/plasma/look-and-feel/$THEME_ID"
RESTORE_ROOT="$STATE_TARGET/gentoo-hp/kde-restore"
PROFILE_MARKER="$STATE_TARGET/gentoo-hp/kde-profile.sha256"
FIRST_LOGIN_MARKER="$STATE_TARGET/gentoo-hp/kde-first-login.sha256"
SOURCE_CANONICAL="$(realpath -m -- "$THEME_SOURCE")"
THEME_TARGET_CANONICAL="$(realpath -m -- "$THEME_TARGET")"
RESTORE_ROOT_CANONICAL="$(realpath -m -- "$RESTORE_ROOT")"
HOME_TARGET_CANONICAL="$(realpath -m -- "$HOME_TARGET")"
CONFIG_TARGET_CANONICAL="$(realpath -m -- "$CONFIG_TARGET")"
STATE_TARGET_CANONICAL="$(realpath -m -- "$STATE_TARGET")"

if [[ -f "$THEME_SOURCE/metadata.json" ]]; then
    [[ ! -L "$THEME_TARGET" ]] \
        || die "Se rechaza el destino del tema porque es un enlace simbólico: $THEME_TARGET"
    [[ ! -e "$THEME_TARGET" || -d "$THEME_TARGET" ]] \
        || die "El destino del tema existe y no es un directorio: $THEME_TARGET"
    paths_overlap "$SOURCE_CANONICAL" "$THEME_TARGET_CANONICAL" \
        && die "El origen y el destino del tema no pueden solaparse."
    paths_overlap "$THEME_TARGET_CANONICAL" "$RESTORE_ROOT_CANONICAL" \
        && die "El tema y su respaldo de reversión no pueden solaparse."
    path_is_at_or_below "$HOME_TARGET_CANONICAL" "$THEME_TARGET_CANONICAL" \
        && die "HOME no puede estar dentro del destino reemplazable del tema."
    path_is_at_or_below "$CONFIG_TARGET_CANONICAL" "$THEME_TARGET_CANONICAL" \
        && die "XDG_CONFIG_HOME no puede estar dentro del destino del tema."
    path_is_at_or_below "$STATE_TARGET_CANONICAL" "$THEME_TARGET_CANONICAL" \
        && die "XDG_STATE_HOME no puede estar dentro del destino del tema."
fi
[[ ! -L "$STATE_TARGET/gentoo-hp" ]] \
    || die "Se rechaza el estado Gentoo-HP porque es un enlace simbólico."
[[ ! -L "$RESTORE_ROOT" ]] \
    || die "Se rechaza el directorio de reversión porque es un enlace simbólico."
[[ ! -L "$PROFILE_MARKER" ]] \
    || die "Se rechaza el marcador del perfil porque es un enlace simbólico."
[[ ! -e "$PROFILE_MARKER" || -f "$PROFILE_MARKER" ]] \
    || die "El marcador del perfil no es un archivo regular."
[[ ! -L "$FIRST_LOGIN_MARKER" ]] \
    || die "Se rechaza el marcador de primera sesión porque es un enlace simbólico."
[[ ! -e "$FIRST_LOGIN_MARKER" || -f "$FIRST_LOGIN_MARKER" ]] \
    || die "El marcador de primera sesión no es un archivo regular."

if [[ "$SKIP_IF_APPLIED" == true && -f "$PROFILE_MARKER" ]]; then
    previous_digest=""
    IFS= read -r previous_digest < "$PROFILE_MARKER" || true
    if [[ "${previous_digest,,}" == "$PROFILE_DIGEST" ]]; then
        ok "El perfil KDE ya está aplicado; se conservan los cambios del usuario."
        exit 0
    fi
fi

ROLLBACK_DIR="$RESTORE_ROOT/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p -- \
    "$ROLLBACK_DIR/config" \
    "$ROLLBACK_DIR/config.d" \
    "$ROLLBACK_DIR/local-share-overwritten" \
    "$ROLLBACK_DIR/theme-overwritten" \
    "$ROLLBACK_DIR/home-overwritten" \
    "$CONFIG_TARGET" \
    "$DATA_TARGET"

log "Creando respaldo de reversión..."
while IFS= read -r -d '' source_file; do
    file_name="$(basename -- "$source_file")"
    if [[ -e "$CONFIG_TARGET/$file_name" || -L "$CONFIG_TARGET/$file_name" ]]; then
        cp -a --no-preserve=ownership -- \
            "$CONFIG_TARGET/$file_name" "$ROLLBACK_DIR/config/"
    fi
done < <(find "$CONFIG_SOURCE" -maxdepth 1 -type f -print0)
ok "$ROLLBACK_DIR"

stop_plasma() {
    [[ "$RESTART_PLASMA" == true ]] || return 0

    if command -v systemctl >/dev/null && \
        systemctl --user --quiet is-active plasma-plasmashell.service; then
        systemctl --user stop plasma-plasmashell.service
        PLASMA_WAS_STOPPED=true
        PLASMA_STOP_METHOD="systemd"
        return 0
    fi

    if command -v kquitapp6 >/dev/null && \
        kquitapp6 plasmashell >/dev/null 2>&1; then
        PLASMA_WAS_STOPPED=true
        PLASMA_STOP_METHOD="kquitapp6"
        return 0
    fi

    warn "No se pudo detener plasmashell; el diseño terminará de aplicarse al cerrar sesión."
}

start_plasma() {
    [[ "$PLASMA_WAS_STOPPED" == true ]] || return 0

    if [[ "$PLASMA_STOP_METHOD" == "systemd" ]]; then
        systemctl --user start plasma-plasmashell.service
    elif command -v kstart >/dev/null; then
        kstart plasmashell >/dev/null 2>&1 &
    elif command -v plasmashell >/dev/null; then
        plasmashell >/dev/null 2>&1 &
    fi
}

trap start_plasma EXIT
stop_plasma

log "Restaurando recursos y configuraciones..."

if [[ -d "$SOURCE_DIR/local/share" ]]; then
    rsync -a \
        --no-owner \
        --no-group \
        --no-devices \
        --no-specials \
        --exclude='plasma/look-and-feel/Orizaba/' \
        --backup \
        --backup-dir="$ROLLBACK_DIR/local-share-overwritten" \
        "$SOURCE_DIR/local/share/" "$DATA_TARGET/"
    ok "esquema de color y perfil de Konsole"
fi

if [[ -d "$SOURCE_DIR/home" ]]; then
    rsync -a \
        --no-owner \
        --no-group \
        --no-devices \
        --no-specials \
        --backup \
        --backup-dir="$ROLLBACK_DIR/home-overwritten" \
        "$SOURCE_DIR/home/" "$HOME_TARGET/"
    ok "recursos heredados de HOME"
fi

if [[ -d "$SOURCE_DIR/config.d" ]]; then
    rsync -a \
        --no-owner \
        --no-group \
        --no-devices \
        --no-specials \
        --backup \
        --backup-dir="$ROLLBACK_DIR/config.d" \
        "$SOURCE_DIR/config.d/" "$CONFIG_TARGET/"
    ok "configuración GTK y valores predeterminados de KDE"
fi

while IFS= read -r -d '' source_file; do
    cp -a --no-preserve=ownership --remove-destination -- \
        "$source_file" "$CONFIG_TARGET/"
done < <(find "$CONFIG_SOURCE" -maxdepth 1 -type f -print0)

# Ajusta rutas absolutas al usuario y a la ubicación actual del paquete.
ORIGINAL_CONFIG_PATH="$(
    sed -n 's/^Origen config: //p' "$SOURCE_DIR/SNAPSHOT-INFO.txt" 2>/dev/null \
        | head -n 1
)"
ORIGINAL_HOME=""
if [[ -n "$ORIGINAL_CONFIG_PATH" ]]; then
    ORIGINAL_HOME="$(dirname -- "$ORIGINAL_CONFIG_PATH")"
fi
PORTABLE_WALLPAPER_PATH="$DATA_TARGET/plasma/look-and-feel/$THEME_ID/contents/assets/usr/share/wallpapers"
while IFS= read -r -d '' restored_source; do
    restored_config="$CONFIG_TARGET/$(basename -- "$restored_source")"
    sed -i \
        "s#@HOME@#${HOME_TARGET//\#/\\#}#g" \
        "$restored_config"
    if [[ -n "$ORIGINAL_HOME" && "$ORIGINAL_HOME" != "$HOME_TARGET" ]]; then
        sed -i \
            "s#${ORIGINAL_HOME//\#/\\#}#${HOME_TARGET//\#/\\#}#g" \
            "$restored_config"
    fi
    if [[ -d "$THEME_SOURCE/contents/assets/usr/share/wallpapers" ]]; then
        sed -i \
            "s#/usr/share/wallpapers#${PORTABLE_WALLPAPER_PATH//\#/\\#}#g" \
            "$restored_config"
    fi
done < <(find "$CONFIG_SOURCE" -maxdepth 1 -type f -print0)
ok "configuración de Plasma, KWin, atajos y aplicaciones KDE"

if [[ -f "$THEME_SOURCE/metadata.json" ]]; then
    mkdir -p -- "$THEME_TARGET"
    rsync -a --delete \
        --no-owner \
        --no-group \
        --no-devices \
        --no-specials \
        --backup \
        --backup-dir="$ROLLBACK_DIR/theme-overwritten" \
        "$THEME_SOURCE/" \
        "$THEME_TARGET/"
    ok "Tema global $THEME_ID"
fi

start_plasma
PLASMA_WAS_STOPPED=false
trap - EXIT

if command -v qdbus6 >/dev/null; then
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
elif command -v qdbus >/dev/null; then
    qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi

rm -f -- "$FIRST_LOGIN_MARKER"

if [[ -n "$PROFILE_DIGEST" ]]; then
    marker_tmp="$(mktemp "$STATE_TARGET/gentoo-hp/.kde-profile.XXXXXX")"
    trap 'rm -f -- "${marker_tmp-}"' EXIT
    printf '%s\n' "$PROFILE_DIGEST" > "$marker_tmp"
    chmod 0600 "$marker_tmp"
    mv -fT -- "$marker_tmp" "$PROFILE_MARKER"
    trap - EXIT
fi

printf '\n%b✔ Perfil KDE Orizaba de Gentoo-HP aplicado correctamente.%b\n' "$GREEN" "$NC"
printf '  Reversión: %s\n' "$ROLLBACK_DIR"
if [[ "$RESTART_PLASMA" == false ]]; then
    warn "Cierra la sesión para cargar el diseño exacto de paneles y widgets."
else
    printf '  Plasma se reinició para cargar paneles y widgets.\n'
fi
