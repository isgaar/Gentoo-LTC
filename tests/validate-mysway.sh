#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
profile="$repo_dir/contrib/mysway/rootfs"
sway_conf="$profile/.config/sway"

[[ -f "$sway_conf/config" ]]
[[ -f "$profile/.config/waybar/config.jsonc" ]]
[[ -f "$profile/.config/kitty/kitty.conf" ]]
[[ -f "$sway_conf/conf.d/15-outputs.conf" ]]
[[ -x "$sway_conf/session.sh" ]]
[[ -x "$repo_dir/contrib/mysway/session/mysway-session" ]]
[[ -x "$profile/.local/bin/mysway-clock" ]]

if find "$profile" -path '*/quickshell/*' -print -quit | grep -q .; then
	printf 'Error: el perfil MySway contiene Quickshell.\n' >&2
	exit 1
fi

if grep -RInE '(^|[^[:alnum:]_])foot([^[:alnum:]_]|$)' "$profile"; then
	printf 'Error: Foot reapareció en el perfil que debe usar Kitty.\n' >&2
	exit 1
fi

if grep -RInE '^[[:space:]]*exec(_always)?[[:space:]].*swayidle' "$sway_conf"; then
	printf 'Error: el bloqueo automático volvió a habilitarse.\n' >&2
	exit 1
fi

grep -Fqx 'set $term kitty' "$sway_conf/conf.d/00-session.conf"
grep -Fqx 'output HDMI-A-1 mode 1920x1080@75Hz position 0 0' \
	"$sway_conf/conf.d/15-outputs.conf"
grep -Fqx 'bindswitch --reload lid:on output eDP-1 disable' \
	"$sway_conf/conf.d/15-outputs.conf"
grep -Fqx 'bindswitch --reload lid:off output eDP-1 enable' \
	"$sway_conf/conf.d/15-outputs.conf"
grep -Fqx 'bindsym $mod+Left exec ~/.local/bin/mysway-workspace prev' \
	"$sway_conf/conf.d/30-bindings.conf"
grep -Fqx 'bindsym $mod+Right exec ~/.local/bin/mysway-workspace next' \
	"$sway_conf/conf.d/30-bindings.conf"
[[ -x "$profile/.local/bin/mysway-workspace" ]]
grep -Fq 'x11-terms/kitty' "$repo_dir/gentoo.conf"
grep -Fq 'media-fonts/fontawesome' "$repo_dir/gentoo.conf"
grep -Fq 'media-fonts/jetbrains-mono' "$repo_dir/gentoo.conf"
grep -Eq '^font_family[[:space:]]+JetBrains Mono$' \
	"$profile/.config/kitty/kitty.conf"
if grep -Fq 'gui-apps/foot' "$repo_dir/gentoo.conf"; then
	printf 'Error: el instalador todavía incluye Foot.\n' >&2
	exit 1
fi
if grep -Fq 'gui-apps/swayidle' "$repo_dir/gentoo.conf"; then
	printf 'Error: el instalador todavía incluye swayidle.\n' >&2
	exit 1
fi

session_file="$repo_dir/contrib/mysway/session/mysway.desktop"
grep -Fqx '[Desktop Entry]' "$session_file"
grep -Fqx 'Exec=/usr/local/bin/mysway-session' "$session_file"
grep -Fqx 'TryExec=/usr/local/bin/mysway-session' "$session_file"
grep -Fqx 'Type=Application' "$session_file"
grep -Fqx 'DesktopNames=sway;wlroots;MySway' "$session_file"

duplicates="$(
	grep -h '^bindsym ' "$sway_conf"/conf.d/*.conf |
		awk '$2 == "--locked" {print $3; next} {print $2}' |
		sort |
		uniq -d
)"
if [[ -n "$duplicates" ]]; then
	printf 'Error: atajos globales duplicados:\n%s\n' "$duplicates" >&2
	exit 1
fi

python3 -m json.tool "$profile/.config/waybar/config.jsonc" >/dev/null
bash -n \
	"$repo_dir/gentoo.conf" \
	"$sway_conf/session.sh" \
	"$profile"/.local/bin/mysway-*
sh -n "$repo_dir/contrib/mysway/session/mysway-session"

printf 'MySway para Gentoo-HP validado correctamente.\n'
