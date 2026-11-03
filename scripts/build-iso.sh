#!/usr/bin/env bash
# Construye la ISO de PekarchOS dentro de Arch Linux (contenedor o metal).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${WORK:-/tmp/pekarchos-build}"
OUT="${ISO_OUT:-${ROOT}/out}"

if [[ "$(id -u)" -ne 0 ]]; then
	echo "build-iso.sh tiene que ejecutarse como root." >&2
	exit 1
fi

echo "==> Herramientas de construcción"
if [[ ! -x /usr/bin/mkarchiso ]]; then
	rm -rf /etc/pacman.d/gnupg
	pacman-key --init
	pacman-key --populate archlinux
	pacman -Sy --noconfirm archlinux-keyring
	pacman -Su --noconfirm
	pacman -S --noconfirm --needed archiso base-devel git sudo squashfs-tools reflector
fi

rm -rf "${WORK}"
mkdir -p "${WORK}/repo" "${WORK}/profile" "${OUT}"

if ! id builder >/dev/null 2>&1; then
	useradd -m builder
fi
printf 'builder ALL=(ALL) NOPASSWD: ALL\n' >/etc/sudoers.d/builder
chmod 0440 /etc/sudoers.d/builder

echo "==> Paquete de marca"
src="${WORK}/pkgbuild"
cp -a "${ROOT}/branding/pekarchos-branding" "${src}"
chown -R builder:builder "${src}"
sudo -u builder bash -c "cd '${src}' && makepkg -s --noconfirm"
cp "${src}"/pekarchos-branding-*.pkg.tar.zst "${WORK}/repo/"
repo-add "${WORK}/repo/pekarchos.db.tar.gz" "${WORK}/repo"/pekarchos-branding-*.pkg.tar.zst

echo "==> Perfil a partir de releng"
if [[ ! -d /usr/share/archiso/configs/releng ]]; then
	echo "No está el perfil releng de archiso." >&2
	exit 1
fi
cp -a /usr/share/archiso/configs/releng/. "${WORK}/profile/"
cp -a "${ROOT}/archiso/." "${WORK}/profile/"

cat >>"${WORK}/profile/pacman.conf" <<EOF

[pekarchos]
SigLevel = Optional TrustAll
Server = file://${WORK}/repo
EOF

mkdir -p "${WORK}/profile/airootfs/usr/share/pekarchos/repo"
cp "${WORK}/repo"/pekarchos-branding-*.pkg.tar.zst "${WORK}/profile/airootfs/usr/share/pekarchos/repo/"
cp "${ROOT}/branding/pekarchos-branding/root/usr/share/pekarchos/splash.png" "${WORK}/profile/syslinux/splash.png"

while IFS= read -r -d '' file; do
	sed -i \
		-e 's/Arch Linux install medium/PekarchOS/g' \
		-e 's/MENU TITLE Arch Linux/MENU TITLE PekarchOS/g' \
		"${file}"
done < <(find "${WORK}/profile/syslinux" "${WORK}/profile/efiboot" "${WORK}/profile/grub" -type f \( -name '*.cfg' -o -name '*.conf' \) -print0)

echo "==> Comprobar que los paquetes existen"
pacman -Sy --noconfirm --config "${WORK}/profile/pacman.conf"
missing=0
while IFS= read -r line || [[ -n "${line}" ]]; do
	pkg="${line%%#*}"
	pkg="${pkg//[[:space:]]/}"
	[[ -z "${pkg}" ]] && continue
	if pacman -Si --config "${WORK}/profile/pacman.conf" "${pkg}" >/dev/null 2>&1; then
		continue
	fi
	if pacman -Sg --config "${WORK}/profile/pacman.conf" "${pkg}" 2>/dev/null | grep -q .; then
		continue
	fi
	echo "Paquete o grupo desconocido: ${pkg}" >&2
	missing=1
done <"${WORK}/profile/packages.x86_64"
if [[ "${missing}" -ne 0 ]]; then
	exit 1
fi

echo "==> mkarchiso"
mkdir -p "${WORK}/work"
mkarchiso -v -r -w "${WORK}/work" -o "${OUT}" "${WORK}/profile"

echo "==> Resultado"
ls -lh "${OUT}"/*.iso
sha256sum "${OUT}"/*.iso | tee "${OUT}/SHA256SUMS"
stat -c '%n %s' "${OUT}"/*.iso
