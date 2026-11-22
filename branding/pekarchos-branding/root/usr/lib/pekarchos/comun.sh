#!/usr/bin/env bash
# Funciones compartidas por el instalador de terminal y por Calamares.
if ! declare -F fallo >/dev/null 2>&1; then
	fallo() {
		echo
		echo "ERROR: $*"
		exit 1
	}
fi

preparar_cuenta() {
	local usuario="$1"
	if [[ -x /usr/lib/pekarchos/poner-avatar.sh ]]; then
		/usr/lib/pekarchos/poner-avatar.sh "${usuario}"
	fi
	if [[ -x /usr/lib/pekarchos/colocar-lanzadores.sh ]]; then
		/usr/lib/pekarchos/colocar-lanzadores.sh "${usuario}"
	else
		install -d -o "${usuario}" -g "${usuario}" "/home/${usuario}/Escritorio"
	fi
}

anadir_parametros_nucleo() {
	local extra="$1"
	local archivo=/etc/default/grub
	local actual="" palabra
	[[ -f "${archivo}" ]] || return 0
	if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "${archivo}"; then
		actual=$(sed -n 's/^GRUB_CMDLINE_LINUX_DEFAULT="//p' "${archivo}" | head -n 1)
		actual=${actual%\"}
		for palabra in ${extra}; do
			case " ${actual} " in
			*" ${palabra} "*) ;;
			*) actual="${actual} ${palabra}" ;;
			esac
		done
		actual=${actual# }
		sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${actual}\"|" "${archivo}"
	else
		printf 'GRUB_CMDLINE_LINUX_DEFAULT="%s"\n' "${extra}" >>"${archivo}"
	fi
}

activar_tema_grub() {
	local tema=/usr/share/grub/themes/pekarchos/theme.txt
	[[ -f "${tema}" ]] || return 0
	if grep -q '^GRUB_THEME=' /etc/default/grub; then
		sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"${tema}\"|" /etc/default/grub
	else
		printf 'GRUB_THEME="%s"\n' "${tema}" >>/etc/default/grub
	fi
	if ! grep -q '^GRUB_GFXMODE=' /etc/default/grub; then
		echo 'GRUB_GFXMODE=auto' >>/etc/default/grub
	fi
	if [[ -f /usr/share/grub/themes/pekarchos/pekarchos.pf2 ]] && ! grep -q '^GRUB_FONT=' /etc/default/grub; then
		echo 'GRUB_FONT="/usr/share/grub/themes/pekarchos/pekarchos.pf2"' >>/etc/default/grub
	fi
	echo "Tema de GRUB: ${tema}"
}

enganchar_plymouth() {
	[[ -f /usr/lib/initcpio/install/plymouth ]] || return 0
	[[ -f /etc/mkinitcpio.conf ]] || return 0
	if grep -q 'plymouth' /etc/mkinitcpio.conf; then
		return 0
	fi
	if grep -q '^HOOKS=.*udev' /etc/mkinitcpio.conf; then
		sed -i '/^HOOKS=/ s/udev/udev plymouth/' /etc/mkinitcpio.conf
		echo "Hook plymouth añadido al initramfs."
	else
		echo "AVISO: no se encontró HOOKS con udev; Plymouth no entra en el initramfs."
	fi
	if [[ -x /usr/bin/plymouth ]]; then
		anadir_parametros_nucleo "quiet splash"
	fi
}

quitar_paquetes_live() {
	local virt="" paquete
	local -a quitar=()
	virt=$(systemd-detect-virt 2>/dev/null || true)
	for paquete in mkinitcpio-archiso edk2-shell memtest86+ memtest86+-efi syslinux; do
		if pacman -Q "${paquete}" >/dev/null 2>&1; then
			quitar+=("${paquete}")
		fi
	done
	if [[ -z "${virt}" || "${virt}" == none ]]; then
		for paquete in virtualbox-guest-utils qemu-guest-agent; do
			if pacman -Q "${paquete}" >/dev/null 2>&1; then
				quitar+=("${paquete}")
			fi
		done
	else
		echo "Máquina virtual (${virt}): se dejan las utilidades de invitado."
	fi
	if ((${#quitar[@]} == 0)); then
		return 0
	fi
	echo "Quitando paquetes que solo sirven en el live: ${quitar[*]}"
	for paquete in "${quitar[@]}"; do
		if ! pacman -R --noconfirm "${paquete}"; then
			echo "AVISO: no se pudo quitar ${paquete}. El sistema sigue."
		fi
	done
}

instalar_firmware() {
	if ! command -v ip >/dev/null 2>&1; then
		echo "Sin la orden ip: no se comprueba la red. Se queda el firmware de la ISO."
		return 0
	fi
	if ! ip route show default 2>/dev/null | grep -q .; then
		echo "Sin red: el disco se queda con el firmware de la ISO (AMD, NVIDIA, Intel, Realtek y Broadcom)."
		return 0
	fi
	echo "Hay red: instalando el metapaquete linux-firmware."
	if ! timeout 180 pacman -S --needed --noconfirm linux-firmware; then
		echo "AVISO: no se pudo instalar linux-firmware. El firmware de GPU de la ISO se queda."
	fi
}

quitar_cuenta_live() {
	echo "==> Quitando la cuenta del live"
	if id live >/dev/null 2>&1; then
		userdel -r live 2>/dev/null || userdel live 2>/dev/null || true
	fi
	rm -rf /home/live
	if id live >/dev/null 2>&1; then
		fallo "el usuario live sigue en el sistema. No se puede terminar así: SDDM volvería a intentar esa cuenta."
	fi
	shopt -s nullglob
	for f in /etc/sddm.conf /etc/sddm.conf.d/*; do
		[[ -f "${f}" ]] || continue
		if grep -q 'User=live' "${f}"; then
			rm -f "${f}"
			echo "Quitado autologin: ${f}"
		fi
	done
	shopt -u nullglob
	rm -rf /etc/systemd/system/getty@tty1.service.d
	rm -f /etc/sudoers.d/live /etc/sudoers.d/g_wheel
	if [[ -f /etc/sudoers ]]; then
		sed -i '/^live[[:space:]]/d' /etc/sudoers
	fi
}

limpiar_archivos_live() {
	echo "==> Quitando archivos que solo sirven en el live"
	rm -f /etc/mkinitcpio.conf.d/archiso.conf
	install -d /etc/mkinitcpio.d /etc/mkinitcpio.conf.d
	if [[ ! -f /etc/mkinitcpio.d/linux.preset ]]; then
		cat >/etc/mkinitcpio.d/linux.preset <<'PRESET'
# mkinitcpio preset file for the 'linux' package
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default' 'fallback')
default_image="/boot/initramfs-linux.img"
fallback_image="/boot/initramfs-linux-fallback.img"
fallback_options="-S autodetect"
PRESET
	fi
	if [[ ! -f /etc/mkinitcpio.conf.d/pekarchos.conf ]]; then
		printf '%s\n' 'MODULES+=(ext4 vfat)' >/etc/mkinitcpio.conf.d/pekarchos.conf
	fi
	local u
	for u in pacman-init.service choose-mirror.service livecd-talk.service livecd-alsa-unmuter.service \
		etc-pacman.d-gnupg.mount pekarchos-export-branding.service reflector.service; do
		find /etc/systemd/system -name "${u}" \( -type l -o -path "*.wants/*" \) -delete 2>/dev/null || true
		case "${u}" in
		pacman-init.service | choose-mirror.service | livecd-*.service | etc-pacman.d-gnupg.mount | pekarchos-export-branding.service)
			rm -f "/etc/systemd/system/${u}"
			;;
		esac
	done
	rm -f /etc/systemd/journald.conf.d/volatile-storage.conf \
		/etc/systemd/logind.conf.d/do-not-suspend.conf \
		/etc/ssh/sshd_config.d/10-archiso.conf \
		/root/.automated_script.sh /root/.zlogin /root/customize_airootfs.sh \
		/usr/local/bin/choose-mirror /usr/local/bin/Installation_guide /usr/local/bin/livecd-sound \
		/usr/local/bin/pekarchos-export-branding \
		/usr/share/applications/pekarchos-install.desktop \
		/usr/share/applications/pekarchos-calamares.desktop
	rm -rf /usr/share/pekarchos/repo /etc/pacman.d/gnupg
	printf 'PekarchOS — basado en Arch Linux. Hecho por Pekapro.\n' >/etc/motd
	printf 'PekarchOS \\r (\\l)\n\n' >/etc/issue
}
