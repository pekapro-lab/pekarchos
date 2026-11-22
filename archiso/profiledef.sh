#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="pekarchos"
iso_label="PEKARCH_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Pekapro <https://github.com/pekapro-lab/pekarchos>"
iso_application="PekarchOS live DVD"
# La versión sale de VERSION, en la raíz del repositorio. build-iso.sh
# exporta PEKARCHOS_VERSION y copia ese archivo junto al perfil.
if [[ -n "${PEKARCHOS_VERSION:-}" ]]; then
	iso_version="${PEKARCHOS_VERSION}"
else
	_ver_aqui="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	if [[ -f "${_ver_aqui}/VERSION" ]]; then
		iso_version="$(tr -d '[:space:]' < "${_ver_aqui}/VERSION")"
	elif [[ -f "${_ver_aqui}/../VERSION" ]]; then
		iso_version="$(tr -d '[:space:]' < "${_ver_aqui}/../VERSION")"
	else
		echo "profiledef.sh: no encuentro VERSION." >&2
		exit 1
	fi
fi
install_dir="pekarchos"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.grub')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M' '-mem' '1G' '-processors' "$(nproc)")
# Sin consola serie: en algunas placas ralentiza el arranque. quiet y splash
# van en la entrada normal del menú, no aquí, para que «gráficos seguros» no
# arranque Plymouth.
kernel_params_x86_64="console=tty0"
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/pekarchos-export-branding"]="0:0:755"
)
