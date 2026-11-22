#!/usr/bin/env bash
# Construye la ISO de PekarchOS dentro de Arch Linux (contenedor o metal).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${WORK:-/tmp/pekarchos-build}"
OUT="${ISO_OUT:-${ROOT}/out}"

if [[ ! -f "${ROOT}/VERSION" ]]; then
	echo "Falta ${ROOT}/VERSION." >&2
	exit 1
fi
PEKARCHOS_VERSION="$(tr -d '[:space:]' < "${ROOT}/VERSION")"
if [[ -z "${PEKARCHOS_VERSION}" ]]; then
	echo "VERSION está vacío." >&2
	exit 1
fi
export PEKARCHOS_VERSION

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
	pacman -S --noconfirm --needed archiso base-devel git sudo squashfs-tools reflector python grub
fi
if [[ ! -f /usr/share/grub/unicode.pf2 ]]; then
	pacman -S --noconfirm --needed grub
fi
if [[ -f /etc/makepkg.conf ]] && ! grep -q 'pekarchos-nodebug' /etc/makepkg.conf; then
	# Sin esto, makepkg deja un paquete -debug enorme (Calamares pasa de 60 MiB).
	printf '\n# pekarchos-nodebug\nOPTIONS+=(!debug)\n' >>/etc/makepkg.conf
fi
if ! command -v python3 >/dev/null; then
	pacman -S --noconfirm --needed python
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

echo "==> Candy Icons (commit fijado)"
candy_pin="$(tr -d '[:space:]' < "${ROOT}/branding/pins/candy-icons.commit")"
candy_tmp="$(mktemp -d)"
git -C "${candy_tmp}" init
git -C "${candy_tmp}" remote add origin https://github.com/EliverLara/candy-icons.git
git -C "${candy_tmp}" fetch --depth 1 origin "${candy_pin}"
git -C "${candy_tmp}" checkout --detach FETCH_HEAD
got="$(git -C "${candy_tmp}" rev-parse HEAD)"
if [[ "${got}" != "${candy_pin}" ]]; then
	echo "El commit de candy-icons es ${got}, se esperaba ${candy_pin}." >&2
	exit 1
fi
rm -rf "${candy_tmp}/.git" "${candy_tmp}/preview"
sed -i 's/^Inherits=.*/Inherits=breeze-dark,breeze,Adwaita,hicolor/' "${candy_tmp}/index.theme"
if grep -q '^FollowsColorScheme=' "${candy_tmp}/index.theme"; then
	sed -i 's/^FollowsColorScheme=.*/FollowsColorScheme=false/' "${candy_tmp}/index.theme"
else
	printf '\nFollowsColorScheme=false\n' >>"${candy_tmp}/index.theme"
fi
mkdir -p "${src}/root/usr/share/icons"
rm -rf "${src}/root/usr/share/icons/candy-icons"
mv "${candy_tmp}" "${src}/root/usr/share/icons/candy-icons"

cp "${ROOT}/VERSION" "${src}/VERSION"
chown -R builder:builder "${src}"
sudo -u builder bash -c "cd '${src}' && makepkg -s --noconfirm"
cp "${src}"/pekarchos-branding-*.pkg.tar.zst "${WORK}/repo/"

aur_build() {
	local name="$1"
	local pin="$2"
	local tmp got
	tmp="$(mktemp -d)"
	git -C "${tmp}" init
	git -C "${tmp}" remote add origin "https://aur.archlinux.org/${name}.git"
	git -C "${tmp}" fetch --depth 1 origin "${pin}"
	git -C "${tmp}" checkout --detach FETCH_HEAD
	got="$(git -C "${tmp}" rev-parse HEAD)"
	if [[ "${got}" != "${pin}" ]]; then
		echo "El commit de ${name} es ${got}, se esperaba ${pin}." >&2
		rm -rf "${tmp}"
		return 1
	fi
	rm -rf "${tmp}/.git"
	if [[ "${name}" == "calamares-git" ]]; then
		python3 - "${tmp}/PKGBUILD" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
old = 'source=("git+${url}.git")'
new = 'source=("git+${url}.git#commit=d62849a39a97dbcd4bd9389ebc38e9643a81fa86")'
if old not in text:
    raise SystemExit("el PKGBUILD de calamares-git ya no clona el git sin commit")
text = text.replace(old, new, 1)
if "-DWITH_PYTHONQT=ON" in text:
    text = text.replace("-DWITH_PYTHONQT=ON", "-DWITH_PYTHON=ON", 1)
elif "-DWITH_PYTHON=ON" not in text:
    raise SystemExit("el PKGBUILD de calamares-git no activa Python")
path.write_text(text)
PY
	fi
	if [[ "${name}" == "foobillard++" ]]; then
		# El PKGBUILD ya quita inline y freetype-config. GCC actual además
		# rechaza abs() sobre un float. No se añade otra función prepare():
		# en bash la segunda sustituye a la primera.
		python3 - "${tmp}/PKGBUILD" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
needle = "  sed -e 's|inline float|float|g' -i src/vmath.*\n"
insert = needle + "  sed -i 's/#include \"vmath.h\"/#include \"vmath.h\"\\n#include <math.h>/' src/vmath.c\n  sed -i 's/abs(y)/fabsf(y)/' src/vmath.c\n"
if needle not in text:
    raise SystemExit("no se encontró prepare() de foobillard++")
path.write_text(text.replace(needle, insert, 1))
PY
	fi
	chown -R builder:builder "${tmp}"
	if ! sudo -u builder bash -c "cd '${tmp}' && makepkg -s --noconfirm"; then
		echo "AVISO: ${name} no se ha podido construir. Se omite." >&2
		rm -rf "${tmp}"
		return 1
	fi
	cp "${tmp}"/*.pkg.tar.zst "${WORK}/repo/"
	rm -rf "${tmp}"
}

echo "==> Paquetes del AUR fijados"
AUR_DROPPED=()
try_aur() {
	if ! aur_build "$1" "$2"; then
		AUR_DROPPED+=("$1")
	fi
}
aur_build_required() {
	if ! aur_build "$1" "$2"; then
		echo "ERROR: ${1} es obligatorio. La ISO no se construye sin él." >&2
		exit 1
	fi
}
aur_build_required calamares-git "$(tr -d '[:space:]' < "${ROOT}/branding/pins/calamares-git.commit")"
aur_build_required ckbcomp "$(tr -d '[:space:]' < "${ROOT}/branding/pins/ckbcomp.commit")"
try_aur dxvk-bin "$(tr -d '[:space:]' < "${ROOT}/branding/pins/dxvk-bin.commit")"
try_aur playonlinux "$(tr -d '[:space:]' < "${ROOT}/branding/pins/playonlinux.commit")"
try_aur "foobillard++" "$(tr -d '[:space:]' < "${ROOT}/branding/pins/foobillard++.commit")"
if [[ ${#AUR_DROPPED[@]} -gt 0 ]]; then
	echo "Omitidos del AUR: ${AUR_DROPPED[*]}"
fi

repo-add "${WORK}/repo/pekarchos.db.tar.gz" "${WORK}/repo"/*.pkg.tar.zst

echo "==> Perfil a partir de releng"
if [[ ! -d /usr/share/archiso/configs/releng ]]; then
	echo "No está el perfil releng de archiso." >&2
	exit 1
fi
cp -a /usr/share/archiso/configs/releng/. "${WORK}/profile/"
cp -a "${ROOT}/archiso/." "${WORK}/profile/"
cp "${ROOT}/VERSION" "${WORK}/profile/VERSION"
install -d "${WORK}/profile/grub/themes/pekarchos" "${WORK}/profile/grub/fonts"
cp -a "${ROOT}/branding/pekarchos-branding/root/usr/share/grub/themes/pekarchos/." \
	"${WORK}/profile/grub/themes/pekarchos/"
cp /usr/share/grub/unicode.pf2 "${WORK}/profile/grub/fonts/unicode.pf2"
if [[ ${#AUR_DROPPED[@]} -gt 0 ]]; then
	for dropped in "${AUR_DROPPED[@]}"; do
		grep -vxF "${dropped}" "${WORK}/profile/packages.x86_64" >"${WORK}/profile/packages.x86_64.tmp"
		mv "${WORK}/profile/packages.x86_64.tmp" "${WORK}/profile/packages.x86_64"
		echo "AVISO: ${dropped} fuera de la lista de paquetes de la ISO."
	done
	printf '%s\n' "${AUR_DROPPED[@]}" >"${OUT}/AUR-OMITIDOS.txt"
fi

if grep -q '^#\[multilib\]' "${WORK}/profile/pacman.conf"; then
	awk '
		/^#\[multilib\]$/ { print "[multilib]"; getline; if ($0 ~ /^#Include/) sub(/^#/, ""); print; next }
		{ print }
	' "${WORK}/profile/pacman.conf" >"${WORK}/profile/pacman.conf.tmp"
	mv "${WORK}/profile/pacman.conf.tmp" "${WORK}/profile/pacman.conf"
else
	printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >>"${WORK}/profile/pacman.conf"
fi

cat >>"${WORK}/profile/pacman.conf" <<EOF

[pekarchos]
SigLevel = Optional TrustAll
Server = file://${WORK}/repo
EOF

mkdir -p "${WORK}/profile/airootfs/usr/share/pekarchos/repo"
cp -a "${WORK}/repo/." "${WORK}/profile/airootfs/usr/share/pekarchos/repo/"
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
# Nombres pelados: sha256sum -c falla si la suma lleva la ruta /out/.
(
	cd "${OUT}"
	sha256sum ./*.iso | sed 's| \./| |' | tee SHA256SUMS
)
stat -c '%n %s' "${OUT}"/*.iso
iso_size="$(stat -c%s "${OUT}"/*.iso)"
# Tope de seguridad. El objetivo es quedarse cerca de 4 GiB; las releases de
# GitHub no aceptan un archivo de más de 2 GiB y por eso el workflow las parte.
iso_limit=$((9 * 1024 * 1024 * 1024 / 2))
if (( iso_size >= iso_limit )); then
	echo "La ISO pesa ${iso_size} bytes y el tope de esta construcción es ${iso_limit}." >&2
	exit 1
fi
