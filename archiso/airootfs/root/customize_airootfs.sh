#!/usr/bin/env bash
# Se ejecuta dentro del airootfs, después de instalar paquetes.
# mkarchiso lo borra al terminar. Sigue existiendo en archiso actual;
# está marcado como obsoleto aguas arriba.
set -euo pipefail

echo "==> Locale, reloj y teclado"
sed -i 's/^#\s*\(es_ES.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
grep -q '^es_ES.UTF-8 UTF-8' /etc/locale.gen
locale-gen
printf 'LANG=es_ES.UTF-8\nLC_TIME=es_ES.UTF-8\n' >/etc/locale.conf
printf 'KEYMAP=es\nFONT=lat9w-16\n' >/etc/vconsole.conf
ln -sfn /usr/share/zoneinfo/Europe/Madrid /etc/localtime
printf 'pekarchos\n' >/etc/hostname
cat >/etc/hosts <<'EOF'
127.0.0.1 localhost
::1       localhost
127.0.1.1 pekarchos.localdomain pekarchos
EOF

install -d /etc/X11/xorg.conf.d
cat >/etc/X11/xorg.conf.d/00-keyboard.conf <<'EOF'
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "es"
    Option "XkbModel" "pc105"
EndSection
EOF

if [[ -f /usr/share/pekarchos/os-release ]]; then
	install -Dm644 /usr/share/pekarchos/os-release /usr/lib/os-release
	ln -sfn ../usr/lib/os-release /etc/os-release
fi

cat >/etc/motd <<'EOF'
PekarchOS — sistema en vivo basado en Arch Linux.

Usuario live, contraseña live. El escritorio entra solo.
Instalar: menú de aplicaciones, «Instalar PekarchOS».
Haz una copia de seguridad antes de tocar un disco.
EOF
cp /etc/motd /etc/issue

echo "==> Red: NetworkManager, sin systemd-networkd ni iwd"
# resolv.conf lo monta arch-chroot; no se borra. systemd-resolved se queda
# para que NetworkManager tenga DNS y el enlace de releng siga siendo válido.
rm -f \
	/etc/systemd/system/multi-user.target.wants/systemd-networkd.service \
	/etc/systemd/system/multi-user.target.wants/iwd.service \
	/etc/systemd/system/multi-user.target.wants/sshd.service \
	/etc/systemd/system/multi-user.target.wants/ModemManager.service \
	/etc/systemd/system/sockets.target.wants/systemd-networkd.socket \
	/etc/systemd/system/sockets.target.wants/pcscd.socket \
	/etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service \
	/etc/systemd/system/dbus-org.freedesktop.network1.service \
	/etc/systemd/system/dbus-org.freedesktop.ModemManager1.service
rm -rf /etc/systemd/system/cloud-init.target.wants
rm -rf /etc/systemd/system/getty@tty1.service.d
install -d /etc/NetworkManager/conf.d
printf '[main]\ndns=systemd-resolved\n' >/etc/NetworkManager/conf.d/pekarchos-dns.conf

link_unit() {
	local unit="$1"
	local target="$2"
	local src="/usr/lib/systemd/system/${unit}"
	if [[ ! -f "${src}" && -f "/etc/systemd/system/${unit}" ]]; then
		src="/etc/systemd/system/${unit}"
	fi
	if [[ ! -e "${src}" ]]; then
		echo "No existe la unidad ${unit}" >&2
		exit 1
	fi
	install -d "/etc/systemd/system/${target}.wants"
	ln -sfn "${src}" "/etc/systemd/system/${target}.wants/${unit}"
}

link_unit NetworkManager.service multi-user.target
link_unit bluetooth.service multi-user.target
link_unit cups.socket sockets.target
link_unit pekarchos-export-branding.service multi-user.target
link_unit systemd-timesyncd.service sysinit.target

ln -sfn /usr/lib/systemd/system/sddm.service /etc/systemd/system/display-manager.service
install -d /etc/systemd/system/graphical.target.wants
ln -sfn /usr/lib/systemd/system/sddm.service /etc/systemd/system/graphical.target.wants/sddm.service
ln -sfn /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target

echo "==> Sesión de SDDM"
session_file=$(find /usr/share/wayland-sessions -name 'plasma*.desktop' | head -n 1 || true)
if [[ -z "${session_file}" ]]; then
	echo "No hay sesión Wayland de Plasma" >&2
	ls -la /usr/share/wayland-sessions /usr/share/xsessions >&2 || true
	exit 1
fi
session=$(basename "${session_file}" .desktop)
cat >/etc/sddm.conf.d/10-autologin.conf <<EOF
[Autologin]
User=live
Session=${session}

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
EOF

echo "==> Usuario live"
groups=()
for group in wheel audio video optical storage network lp scanner users render input; do
	if getent group "${group}" >/dev/null; then
		groups+=("${group}")
	fi
done
group_csv=$(IFS=,; echo "${groups[*]}")
if ! id live >/dev/null 2>&1; then
	useradd -m -u 1000 -G "${group_csv}" -s /bin/bash -c "PekarchOS Live" live
fi
echo 'live:live' | chpasswd
passwd -l root

install -d -m 0750 /etc/sudoers.d
printf 'live ALL=(ALL) NOPASSWD: ALL\n' >/etc/sudoers.d/live
chmod 0440 /etc/sudoers.d/live
visudo -cf /etc/sudoers.d/live

for folder in Desktop Escritorio; do
	install -d -o live -g live "/home/live/${folder}"
	install -m 0644 -o live -g live /usr/share/pekarchos/LEEME.txt "/home/live/${folder}/LEEME.txt"
	install -m 0644 -o live -g live /usr/share/applications/pekarchos-install.desktop "/home/live/${folder}/pekarchos-install.desktop"
done
chown -R live:live /home/live

if command -v flatpak >/dev/null 2>&1; then
	flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
		|| echo "No se pudo añadir Flathub; se puede hacer luego con flatpak remote-add."
fi

echo "==> PekarchOS live listo (sesión ${session})"
