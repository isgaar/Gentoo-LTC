#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
PROFILE="$REPO_ROOT/contrib/kde/orizaba/snapshot"
IMPORTER="$REPO_ROOT/contrib/kde/orizaba/import_kde.sh"
FIRST_LOGIN="$REPO_ROOT/contrib/kde/orizaba/first_login.sh"
AUTOSTART="$REPO_ROOT/contrib/kde/orizaba/gentoo-hp-kde-first-login.desktop"
FONTS="$REPO_ROOT/contrib/fonts/inter"
TEST_HOME="$(mktemp -d /tmp/gentoo-hp-kde-profile.XXXXXX)"

cleanup() {
	if [[ "$TEST_HOME" == /tmp/gentoo-hp-kde-profile.* ]]; then
		rm -rf -- "$TEST_HOME"
	fi
}
trap cleanup EXIT

fail() {
	printf 'KDE profile validation failed: %s\n' "$*" >&2
	exit 1
}

((EUID != 0)) || fail "run this validation as a normal user, without sudo"

validate_manifest_exact() {
	local asset_root="$1"
	local description="$2"
	local declared_files actual_files

	declared_files="$(
		sed -n 's/^[[:xdigit:]]\{64\}  //p' "$asset_root/SHA256SUMS" \
			| LC_ALL=C sort
	)"
	actual_files="$(
		cd -- "$asset_root" || fail "cannot enter $description asset directory"
		find . -type f ! -path './SHA256SUMS' -print | LC_ALL=C sort
	)"
	[[ "$declared_files" == "$actual_files" ]] \
		|| fail "$description manifest does not cover the exact file set"
	(
		cd -- "$asset_root" || exit 1
		sha256sum --check --quiet --strict SHA256SUMS
	) || fail "$description checksum mismatch"
}

bash -n "$IMPORTER" "$FIRST_LOGIN" "$REPO_ROOT/gentoo.conf"
[[ "$(grep -c -- '--no-owner' "$IMPORTER")" -eq 4 ]] \
	|| fail "every rsync into HOME must disable owner preservation"
[[ "$(grep -c -- '--no-group' "$IMPORTER")" -eq 4 ]] \
	|| fail "every rsync into HOME must disable group preservation"
grep -Fq 'cp -a --no-preserve=ownership' "$IMPORTER" \
	|| fail "top-level KDE configuration must not preserve root ownership"
grep -Fq -- '--remove-destination' "$IMPORTER" \
	|| fail "top-level KDE configuration must replace destination symlinks"
grep -Fq '((EUID != 0))' "$IMPORTER" \
	|| fail "the importer must reject sudo/root execution"

validate_manifest_exact "$PROFILE" "snapshot"
validate_manifest_exact "$FONTS" "font"

[[ -z "$(find "$PROFILE" "$FONTS" -type l -print -quit)" ]] \
	|| fail "symbolic links are not allowed in vendored assets"

mapfile -d '' -t font_files \
	< <(find "$FONTS" -maxdepth 1 -type f -name 'Inter*.ttf' -print0)
font_count="${#font_files[@]}"
[[ "$font_count" -eq 36 ]] \
	|| fail "expected 36 Inter/Inter Display files, found $font_count"
[[ -f "$FONTS/LICENSE-Inter.txt" ]] \
	|| fail "Inter OFL license is missing"

if command -v fc-scan >/dev/null 2>&1; then
	inter_family_count=0
	inter_display_family_count=0
	for font_file in "${font_files[@]}"; do
		fc-scan "$font_file" >/dev/null \
			|| fail "invalid font: ${font_file##*/}"
		font_family="$(fc-scan --format '%{family[0]}\n' "$font_file")"
		case "$font_family" in
			Inter)
				((inter_family_count += 1))
				;;
			"Inter Display")
				((inter_display_family_count += 1))
				;;
			*)
				fail "unexpected font family in ${font_file##*/}: $font_family"
				;;
		esac
	done
	[[ "$inter_family_count" -eq 18 && "$inter_display_family_count" -eq 18 ]] \
		|| fail "expected 18 Inter and 18 Inter Display files"
fi

unsafe_files=(
	config/bluedevilglobalrc
	config/kwinoutputconfig.json
	config/kscreenlockerrc
	config/ksmserverrc
	config/plasmaparc
	config/powerdevilrc
	config/powermanagementprofilesrc
	config.d/kdedefaults/ksplashrc
)
for unsafe_file in "${unsafe_files[@]}"; do
	[[ ! -e "$PROFILE/$unsafe_file" ]] \
		|| fail "unsafe or incomplete host-specific file was included: $unsafe_file"
done
[[ ! -e "$PROFILE/local/share/kscreen" ]] \
	|| fail "host-specific KScreen state was included"
[[ ! -e "$PROFILE/config.d/gtk-3.0/window_decorations.css" \
	&& ! -e "$PROFILE/config.d/gtk-4.0/window_decorations.css" ]] \
	|| fail "generated Breeze decoration code must not be vendored"
[[ -z "$(find "$PROFILE/config.d" -path '*/assets/*.svg' -print -quit)" ]] \
	|| fail "generated Breeze SVG decorations must not be vendored"

for gtk_version in gtk-3.0 gtk-4.0; do
	while IFS= read -r imported_file; do
		[[ -f "$PROFILE/config.d/$gtk_version/$imported_file" ]] \
			|| fail "$gtk_version references a missing import: $imported_file"
	done < <(
		sed -n "s/^@import ['\"]\\([^'\"]*\\)['\"];$/\\1/p" \
			"$PROFILE/config.d/$gtk_version/gtk.css"
	)
done

if grep -RIEq \
		'bluetoothBlocked|GlobalMuteSinksMutedDevices|Autolock=false|PowerProfile=performance|connectorName|clientId|firefox-esr|lastScreen=' \
		"$PROFILE"; then
	fail "unsafe or host-specific setting remains in the portable profile"
fi
if grep -RIEq \
		'/home/ismael|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|gh[pousr]_[[:alnum:]_]{20,}' \
		"$PROFILE"; then
	fail "private or user-specific data remains in the portable profile"
fi
mapfile -t home_placeholder_files < <(grep -RIl '@HOME@' "$PROFILE" || true)
[[ "${#home_placeholder_files[@]}" -eq 1 ]] \
	|| fail "the portable HOME placeholder must occur in exactly one config file"
grep -Fq 'ColorScheme=Orizaba' "$PROFILE/config/kdeglobals" \
	|| fail "Orizaba is not the selected KDE color scheme"
grep -Fq 'DefaultProfile=Perfil 1.profile' "$PROFILE/config/konsolerc" \
	|| fail "the imported Konsole profile is not selected by default"
grep -Fq 'License": "Custom' "$PROFILE/Orizaba/metadata.json" \
	|| fail "the composite theme license declaration changed unexpectedly"
[[ -f "$PROFILE/Orizaba/LICENSES/MIT-Orizaba.txt" \
	&& -f "$PROFILE/Orizaba/THIRD-PARTY-NOTICES.md" ]] \
	|| fail "Orizaba component licenses are incomplete"
[[ -f "$PROFILE/Orizaba/contents/assets/usr/share/wallpapers/Path/LICENSE-LGPL-3.txt" \
	&& -f "$PROFILE/Orizaba/contents/assets/usr/share/wallpapers/Path/LICENSE-GPL-3.txt" ]] \
	|| fail "the Path wallpaper license texts are incomplete"
[[ ! -e "$PROFILE/local/share/konsole/Breeze.colorscheme" ]] \
	|| fail "the upstream Breeze Konsole scheme must come from kde-apps/konsole"

grep -Fq 'net-misc/rsync' "$REPO_ROOT/gentoo.conf" \
	|| fail "net-misc/rsync is not installed"
grep -Eq 'kde-plasma/plasma-meta .*crypt' "$REPO_ROOT/gentoo.conf" \
	|| fail "Plasma Vault support required by the panel is not enabled"
grep -Fq '<family>Inter</family>' "$REPO_ROOT/gentoo.conf" \
	|| fail "Inter is not configured in system Fontconfig"
grep -Fq '<family>JetBrains Mono</family>' "$REPO_ROOT/gentoo.conf" \
	|| fail "JetBrains Mono is not configured in system Fontconfig"
grep -Fq 'gentoo-hp-kde-first-login' "$REPO_ROOT/gentoo.conf" \
	|| fail "the first-login helper is not installed"
grep -Fq -- '--profile-digest "$profile_digest"' "$REPO_ROOT/gentoo.conf" \
	|| fail "the profile digest is not recorded by the unprivileged importer"
grep -Fq 'OnlyShowIn=KDE;' "$AUTOSTART" \
	|| fail "the first-login helper is not restricted to KDE"
grep -Fq -- '--resetLayout' "$FIRST_LOGIN" \
	|| fail "the first KDE session does not rebuild the Orizaba layout"
grep -Fq 'plasma-apply-wallpaperimage' "$FIRST_LOGIN" \
	|| fail "the first KDE session does not apply the wallpaper"

after_install_body="$(
	sed -n '/^function after_install()/,/^}/p' "$REPO_ROOT/gentoo.conf"
)"
fonts_line="$(grep -n 'install_gentoo_hp_system_fonts' <<<"$after_install_body" | cut -d: -f1)"
fontconfig_line="$(grep -n 'configure_unicode_fonts' <<<"$after_install_body" | cut -d: -f1)"
kde_line="$(grep -n 'configure_kde_desktop' <<<"$after_install_body" | cut -d: -f1)"
xdg_line="$(grep -n 'configure_xdg_user_directories' <<<"$after_install_body" | cut -d: -f1)"
[[ "$fonts_line" -lt "$fontconfig_line" && "$fontconfig_line" -lt "$kde_line" \
		&& "$kde_line" -lt "$xdg_line" ]] \
	|| fail "fonts, KDE profile and XDG directories run in the wrong order"

mkdir -p -- "$TEST_HOME/.config" "$TEST_HOME/outside"
printf 'sentinel\n' > "$TEST_HOME/outside/kdeglobals"
ln -s "$TEST_HOME/outside/kdeglobals" "$TEST_HOME/.config/kdeglobals"
profile_digest="$(sha256sum "$PROFILE/SHA256SUMS" | awk '{print $1}')"

env \
	HOME="$TEST_HOME" \
	USER=kde-test \
	LOGNAME=kde-test \
	XDG_CONFIG_HOME="$TEST_HOME/.config" \
	XDG_DATA_HOME="$TEST_HOME/.local/share" \
	XDG_STATE_HOME="$TEST_HOME/.local/state" \
	"$IMPORTER" \
		--source "$PROFILE" \
		--no-restart \
		--profile-digest "$profile_digest" \
		--skip-if-applied \
		> "$TEST_HOME/import.log" 2>&1

[[ "$(<"$TEST_HOME/outside/kdeglobals")" == "sentinel" ]] \
	|| fail "a top-level destination symlink was followed"
[[ -f "$TEST_HOME/.config/kdeglobals" \
	&& ! -L "$TEST_HOME/.config/kdeglobals" ]] \
	|| fail "kdeglobals was not safely imported"
[[ -n "$(find "$TEST_HOME/.local/state/gentoo-hp/kde-restore" \
		-type l -path '*/config/kdeglobals' -print -quit)" ]] \
	|| fail "the replaced config symlink was not preserved in rollback"
[[ -f "$TEST_HOME/.local/share/plasma/look-and-feel/Orizaba/metadata.json" ]] \
	|| fail "Orizaba look-and-feel package was not imported"
[[ "$(<"$TEST_HOME/.local/state/gentoo-hp/kde-profile.sha256")" \
	== "$profile_digest" ]] \
	|| fail "the unprivileged importer did not record the profile digest"
[[ "$(stat -c '%a' "$TEST_HOME/.local/state/gentoo-hp/kde-profile.sha256")" \
	== "600" ]] \
	|| fail "the profile marker mode is not 0600"
grep -Fq 'font=Inter,' "$TEST_HOME/.config/kdeglobals" \
	|| fail "Inter was not selected for Plasma"
grep -Fq 'fixed=JetBrains Mono NL,' "$TEST_HOME/.config/kdeglobals" \
	|| fail "JetBrains Mono NL was not selected for Plasma"
grep -Fq 'ColorScheme=Orizaba' "$TEST_HOME/.config/kdeglobals" \
	|| fail "Orizaba was not selected after import"
grep -Fq 'DefaultProfile=Perfil 1.profile' "$TEST_HOME/.config/konsolerc" \
	|| fail "the Konsole profile was not selected after import"
grep -Fq 'firefox-bin.desktop' "$TEST_HOME/.config/mimeapps.list" \
	|| fail "Firefox binary desktop association is missing"
grep -Fq "icon=$TEST_HOME/Descargas/Gentoo-logo-dark.svg" \
	"$TEST_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" \
	|| fail "the portable HOME placeholder was not expanded"
grep -Fq "$TEST_HOME/.local/share/plasma/look-and-feel/Orizaba/contents/assets/usr/share/wallpapers" \
	"$TEST_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" \
	|| fail "the wallpaper path was not made portable"

if grep -RIEq \
		'/home/ismael|@HOME@|file:///usr/share/wallpapers|firefox-esr|bluetoothBlocked|GlobalMuteSinksMutedDevices|Autolock=false|PowerProfile=performance|connectorName|clientId|lastScreen=' \
		"$TEST_HOME/.config" "$TEST_HOME/.local/share"; then
	fail "host-specific data reached the imported profile"
fi

mapfile -d '' -t rollback_directories < <(
	find "$TEST_HOME/.local/state/gentoo-hp/kde-restore" \
		-mindepth 1 -maxdepth 1 -type d -print0
)
rollback_count="${#rollback_directories[@]}"
printf '\n# preserve-user-change\n' >> "$TEST_HOME/.config/kdeglobals"
env \
	HOME="$TEST_HOME" \
	USER=kde-test \
	LOGNAME=kde-test \
	XDG_CONFIG_HOME="$TEST_HOME/.config" \
	XDG_DATA_HOME="$TEST_HOME/.local/share" \
	XDG_STATE_HOME="$TEST_HOME/.local/state" \
	"$IMPORTER" \
		--source "$PROFILE" \
		--no-restart \
		--profile-digest "$profile_digest" \
		--skip-if-applied \
		>> "$TEST_HOME/import.log" 2>&1
grep -Fq '# preserve-user-change' "$TEST_HOME/.config/kdeglobals" \
	|| fail "an unchanged profile overwrote the user's KDE customization"
mapfile -d '' -t rollback_directories_after_skip < <(
	find "$TEST_HOME/.local/state/gentoo-hp/kde-restore" \
		-mindepth 1 -maxdepth 1 -type d -print0
)
[[ "${#rollback_directories_after_skip[@]}" -eq "$rollback_count" ]] \
	|| fail "an unchanged profile created an unnecessary rollback"

theme_link_home="$TEST_HOME/theme-link-home"
theme_outside="$TEST_HOME/theme-link-outside"
mkdir -p -- \
	"$theme_link_home/.local/share/plasma/look-and-feel" \
	"$theme_outside"
printf 'valuable\n' > "$theme_outside/sentinel"
ln -s "$theme_outside" \
	"$theme_link_home/.local/share/plasma/look-and-feel/Orizaba"
if env \
	HOME="$theme_link_home" \
	XDG_CONFIG_HOME="$theme_link_home/.config" \
	XDG_DATA_HOME="$theme_link_home/.local/share" \
	XDG_STATE_HOME="$theme_link_home/.local/state" \
	"$IMPORTER" --source "$PROFILE" --no-restart \
		> "$TEST_HOME/theme-link.log" 2>&1; then
	fail "a symbolic-link theme target was accepted"
fi
[[ "$(<"$theme_outside/sentinel")" == "valuable" \
	&& -L "$theme_link_home/.local/share/plasma/look-and-feel/Orizaba" \
	&& ! -e "$theme_link_home/.config/kdeglobals" ]] \
	|| fail "theme symlink preflight modified external or user data"

tampered_profile="$TEST_HOME/tampered-profile"
tampered_home="$TEST_HOME/tampered-home"
cp -a -- "$PROFILE" "$tampered_profile"
printf 'not declared\n' > "$tampered_profile/UNMANIFESTED"
if env \
	HOME="$tampered_home" \
	XDG_CONFIG_HOME="$tampered_home/.config" \
	XDG_DATA_HOME="$tampered_home/.local/share" \
	XDG_STATE_HOME="$tampered_home/.local/state" \
	"$IMPORTER" --source "$tampered_profile" --no-restart \
		> "$TEST_HOME/tampered.log" 2>&1; then
	fail "an unmanifested snapshot file was accepted"
fi
[[ ! -e "$tampered_home/.config/kdeglobals" ]] \
	|| fail "tampered snapshot wrote user configuration"

stub_bin="$TEST_HOME/stub-bin"
first_login_log="$TEST_HOME/first-login.log"
mkdir -p -- "$stub_bin"
printf '%s\n' \
	'#!/usr/bin/env bash' \
	'printf "lookandfeel %s\\n" "$*" >> "$FIRST_LOGIN_LOG"' \
	> "$stub_bin/plasma-apply-lookandfeel"
printf '%s\n' \
	'#!/usr/bin/env bash' \
	'printf "wallpaper %s\\n" "$*" >> "$FIRST_LOGIN_LOG"' \
	> "$stub_bin/plasma-apply-wallpaperimage"
chmod 0755 \
	"$stub_bin/plasma-apply-lookandfeel" \
	"$stub_bin/plasma-apply-wallpaperimage"
run_first_login() {
	env \
		HOME="$TEST_HOME" \
		USER=kde-test \
		LOGNAME=kde-test \
		XDG_CURRENT_DESKTOP=KDE \
		XDG_DATA_HOME="$TEST_HOME/.local/share" \
		XDG_STATE_HOME="$TEST_HOME/.local/state" \
		GENTOO_HP_KDE_PROFILE_ROOT="$PROFILE" \
		FIRST_LOGIN_LOG="$first_login_log" \
		PATH="$stub_bin:$PATH" \
		"$FIRST_LOGIN" > "$TEST_HOME/first-login.stdout" 2>&1
}

printf 'lock-sentinel\n' > "$TEST_HOME/outside/first-login-lock"
ln -s "$TEST_HOME/outside/first-login-lock" \
	"$TEST_HOME/.local/state/gentoo-hp/kde-first-login.lock"
if run_first_login; then
	fail "the first-login helper accepted a symbolic-link lock file"
fi
[[ "$(<"$TEST_HOME/outside/first-login-lock")" == "lock-sentinel" ]] \
	|| fail "the first-login lock followed and modified a symlink"
rm -- "$TEST_HOME/.local/state/gentoo-hp/kde-first-login.lock"

run_first_login
grep -Fq 'lookandfeel --apply Orizaba --resetLayout' "$first_login_log" \
	|| fail "the first-login helper did not apply the Orizaba layout"
grep -Fq 'wallpaper --fill-mode preserveAspectCrop' "$first_login_log" \
	|| fail "the first-login helper did not apply the Path wallpaper"
[[ "$(<"$TEST_HOME/.local/state/gentoo-hp/kde-first-login.sha256")" \
	== "$profile_digest" ]] \
	|| fail "the first-login completion marker is incorrect"
first_login_lines="$(wc -l < "$first_login_log")"
run_first_login
[[ "$(wc -l < "$first_login_log")" -eq "$first_login_lines" ]] \
	|| fail "the first-login helper is not idempotent"

printf 'Gentoo-HP KDE profile validation passed.\n'
