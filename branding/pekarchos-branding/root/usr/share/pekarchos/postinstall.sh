#!/usr/bin/env bash
# Se ejecuta dentro del sistema recién instalado (arch-chroot).
# /run está montado desde el live, donde pekarchos-export-branding
# publica /usr/share/pekarchos.
set -euo pipefail

enable_multilib() {
	if grep -q '^\[multilib\]' /etc/pacman.conf; then
		return
	fi
	if grep -q '^#\[multilib\]' /etc/pacman.conf; then
		awk '
			/^#\[multilib\]$/ { print "[multilib]"; getline; if ($0 ~ /^#Include/) sub(/^#/, ""); print; next }
			{ print }
		' /etc/pacman.conf >/etc/pacman.conf.pekarchos
		mv /etc/pacman.conf.pekarchos /etc/pacman.conf
	else
		cat >>/etc/pacman.conf <<'EOF'

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
	fi
}

if [[ -d /run/pekarchos/repo ]]; then
	if ! grep -q '^\[pekarchos\]' /etc/pacman.conf; then
		cat >>/etc/pacman.conf <<'EOF'

[pekarchos]
SigLevel = Optional TrustAll
Server = file:///run/pekarchos/repo
EOF
	fi
fi

enable_multilib
pacman -Sy --noconfirm

packages=(
	pekarchos-branding
	dxvk-bin
	foobillard++
	playonlinux
	steam
	lib32-mesa
	lib32-vulkan-radeon
	lib32-vulkan-intel
	lib32-vulkan-icd-loader
	lib32-gamemode
	lib32-vkd3d
)

installable=()
for pkg in "${packages[@]}"; do
	if pacman -Si "${pkg}" >/dev/null 2>&1; then
		installable+=("${pkg}")
	else
		echo "AVISO: ${pkg} no está disponible; se omite."
	fi
done

if [[ ${#installable[@]} -gt 0 ]]; then
	pacman -S --needed --noconfirm "${installable[@]}"
fi

if [[ -f /etc/mkinitcpio.conf ]] && [[ -f /usr/lib/initcpio/install/plymouth ]] && ! grep -q 'plymouth' /etc/mkinitcpio.conf; then
	sed -i '/^HOOKS=/ s/udev/udev plymouth/' /etc/mkinitcpio.conf || true
fi
tema=/usr/share/grub/themes/pekarchos/theme.txt
if [[ -f "${tema}" && -f /etc/default/grub ]]; then
	if grep -q '^GRUB_THEME=' /etc/default/grub; then
		sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"${tema}\"|" /etc/default/grub
	else
		printf 'GRUB_THEME="%s"\n' "${tema}" >>/etc/default/grub
	fi
	grep -q '^GRUB_GFXMODE=' /etc/default/grub || echo 'GRUB_GFXMODE=auto' >>/etc/default/grub
	if [[ -f /usr/share/grub/themes/pekarchos/pekarchos.pf2 ]] && ! grep -q '^GRUB_FONT=' /etc/default/grub; then
		echo 'GRUB_FONT="/usr/share/grub/themes/pekarchos/pekarchos.pf2"' >>/etc/default/grub
	fi
fi
if [[ -x /usr/bin/plymouth ]] && [[ -f /etc/default/grub ]] && ! grep -q 'splash' /etc/default/grub; then
	if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub; then
		sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' /etc/default/grub
	else
		echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' >>/etc/default/grub
	fi
fi
if command -v mkinitcpio >/dev/null 2>&1; then
	mkinitcpio -P || true
fi
if command -v grub-mkconfig >/dev/null 2>&1 && [[ -d /boot/grub || -d /boot/efi ]]; then
	grub-mkconfig -o /boot/grub/grub.cfg || true
fi
