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
	google-chrome
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
