#!/usr/bin/env bash

set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
profile="$repo_dir/gentoo.conf"
installer="$repo_dir/scripts/main.sh"
chroot_dispatcher="$repo_dir/scripts/dispatch_chroot.sh"
functions="$repo_dir/scripts/functions.sh"

bash -n "$profile" "$installer" "$chroot_dispatcher" "$functions"

grep -Fqx 'SELECT_MIRRORS=false' "$profile"
grep -Fqx 'media-libs/libcanberra alsa' "$profile"
grep -Fqx 'media-libs/freetype harfbuzz' "$profile"
grep -Fqx 'media-libs/libsdl2 gles2' "$profile"
grep -Fqx 'sys-apps/systemd policykit' "$profile"
grep -Fqx 'media-video/pipewire bluetooth dbus extra ffmpeg flatpak liblc3 pipewire-alsa sound-server systemd' "$profile"
grep -Fq 'contrib/kernel/config.d/15-audio-hardware.config' "$repo_dir/docs/KERNEL-PERSONALIZADO.md"
grep -Fq 'default.clock.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]' \
	"$repo_dir/contrib/pipewire/pipewire.conf.d/10-gentoo-ltc-hifi.conf"
grep -Fq 'bluetooth.profile-preference = "quality"' \
	"$repo_dir/contrib/wireplumber/20-gentoo-ltc-hifi-bluetooth.conf"
[[ ! -e "$repo_dir/contrib/wireplumber/15-gentoo-ltc-hifi-alsa.conf" ]]
[[ ! -e "$repo_dir/contrib/kernel/config.d/99-gentoo-hp-localversion.config" ]]
grep -Fqx 'CONFIG_LOCALVERSION="-gentoo4thinkcentre-m75s"' \
	"$repo_dir/contrib/kernel/config.d/99-gentoo-ltc-localversion.config"

dependency_function="$(sed -n '/^function install_initramfs_dependencies()/,/^}/p' "$installer")"
grep -Fq 'sys-kernel/linux-firmware' <<<"$dependency_function"
grep -Fq 'sys-fs/cryptsetup' <<<"$dependency_function"
grep -Fq 'sys-fs/btrfs-progs' <<<"$dependency_function"

kernel_call_line="$(grep -n 'install_initramfs_dependencies' "$installer" | tail -n 1 | cut -d: -f1)"
kernel_emerge_line="$(grep -n 'sys-kernel/dracut sys-kernel/gentoo-kernel app-arch/zstd' "$installer" | cut -d: -f1)"
[[ "$kernel_call_line" -lt "$kernel_emerge_line" ]]
grep -Fq -- '--update --newuse --autounmask-continue=y' "$installer"
grep -Fq -- '--update --deep --newuse @world' "$installer"
grep -Fqx 'PORTAGE_GIT_MIRROR="https://github.com/gentoo-mirror/gentoo.git"' "$profile"
grep -Fqx 'PORTAGE_MAKEOPTS="-j2 -l2"' "$profile"
grep -Fqx 'PORTAGE_EMERGE_DEFAULT_OPTS="--jobs=1 --load-average=2 --with-bdeps=y"' "$profile"
for group in audio video render input plugdev netdev lp lpadmin kvm libvirt vboxusers dialout cdrom usb; do
	grep -Fq "$group" <(sed -n '/^INSTALL_USER_GROUPS=/p' "$profile")
done
grep -Fq 'PORTAGE_MAKEOPTS="-j6 -l6"' "$repo_dir/docs/RAM-16GB-Y-PORTAGE.md"
grep -Fq 'PORTAGE_EMERGE_DEFAULT_OPTS="--jobs=1 --load-average=6 --with-bdeps=y"' "$repo_dir/docs/RAM-16GB-Y-PORTAGE.md"

user_creation_line="$(grep -n "maybe_exec 'ensure_install_user_exists'" "$installer" | cut -d: -f1)"
sync_line="$(grep -n 'Syncing portage tree' "$installer" | cut -d: -f1)"
[[ "$user_creation_line" -lt "$sync_line" ]]
user_creation_function="$(sed -n '/^function ensure_install_user_exists()/,/^}/p' "$profile")"
grep -Fq 'passwd "$INSTALL_USER"' <<<"$user_creation_function"

after_install="$(sed -n '/^function after_install()/,/^}/p' "$profile")"
for unit in \
	'pipewire.socket' \
	'pipewire-pulse.socket' \
	'wireplumber.service' \
	'bluetooth.service' \
	'cups.service' \
	'NetworkManager' \
	'sddm.service'; do
	grep -Fq "$unit" <<<"$after_install"
done

xdg_function="$(sed -n '/^function configure_xdg_user_directories()/,/^}/p' "$profile")"
for directory in Escritorio Descargas Documentos Imágenes Música Vídeos; do
	grep -Fq "$directory" <<<"$xdg_function"
done

grep -Fq 'DEBUGINFOD_IMA_CERT_PATH="${DEBUGINFOD_IMA_CERT_PATH:-}"' "$chroot_dispatcher"
[[ "$(grep -Fc 'DEBUGINFOD_IMA_CERT_PATH="${DEBUGINFOD_IMA_CERT_PATH:-}"' "$functions")" -eq 2 ]]
grep -Fq 'command -v chronyd' "$functions"
grep -Fq -- "--proto '=https' --tlsv1.2" "$functions"
grep -Fq 'Need ntpd, chronyd, or curl to synchronize time' "$functions"

printf 'Resiliencia de instalación de Gentoo-HP validada correctamente.\n'
