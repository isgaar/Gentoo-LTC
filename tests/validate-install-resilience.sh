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

dependency_function="$(sed -n '/^function install_initramfs_dependencies()/,/^}/p' "$installer")"
grep -Fq 'sys-kernel/linux-firmware' <<<"$dependency_function"
grep -Fq 'sys-fs/cryptsetup' <<<"$dependency_function"
grep -Fq 'sys-fs/btrfs-progs' <<<"$dependency_function"

kernel_call_line="$(grep -n 'install_initramfs_dependencies' "$installer" | tail -n 1 | cut -d: -f1)"
kernel_emerge_line="$(grep -n 'sys-kernel/dracut sys-kernel/gentoo-kernel app-arch/zstd' "$installer" | cut -d: -f1)"
[[ "$kernel_call_line" -lt "$kernel_emerge_line" ]]
grep -Fq -- '--update --newuse --autounmask-continue=y' "$installer"

after_install="$(sed -n '/^function after_install()/,/^}/p' "$profile")"
for unit in \
	'pipewire.socket' \
	'pipewire-pulse.socket' \
	'wireplumber.service' \
	'bluetooth.service' \
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

printf 'Resiliencia de instalación de Gentoo-HP validada correctamente.\n'
