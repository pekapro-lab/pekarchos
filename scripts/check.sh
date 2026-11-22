#!/usr/bin/env bash
# Comprobaciones ligeras: versión única, menú de la ISO, marca y sintaxis.
# No construye la ISO.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

fallo() {
	echo "ERROR: $*" >&2
	exit 1
}

ver="$(tr -d '[:space:]' < VERSION)"
[[ "${ver}" == "0.3.0" ]] || fallo "VERSION es «${ver}» y esta fase es 0.3.0."

grep -q '@PEKARCHOS_VERSION@' branding/pekarchos-branding/root/usr/share/pekarchos/os-release \
	|| fallo "os-release no toma la versión de VERSION."
grep -q 'LOGO=pekarchos' branding/pekarchos-branding/root/usr/share/pekarchos/os-release
grep -q '@PEKARCHOS_VERSION@' branding/pekarchos-branding/root/etc/xdg/kcm-about-distrorc
grep -q 'LogoPath=/usr/share/pekarchos/logo-full.png' branding/pekarchos-branding/root/etc/xdg/kcm-about-distrorc

(
	# shellcheck disable=SC1091
	source branding/pekarchos-branding/PKGBUILD
	[[ "${pkgver}" == "${ver}" ]] || fallo "El PKGBUILD resolvió ${pkgver}."
)

PEKARCHOS_VERSION="${ver}" bash -c '
	declare -A file_permissions
	# shellcheck disable=SC1091
	source archiso/profiledef.sh
	[[ "${iso_version}" == "0.3.0" ]]
	[[ " ${bootmodes[*]} " == *" uefi.grub "* ]]
	[[ " ${bootmodes[*]} " == *" bios.syslinux "* ]]
	[[ "${kernel_params_x86_64}" != *ttyS0* ]]
' || fallo "profiledef.sh no lee la versión o el modo de arranque."

paquetes=archiso/packages.x86_64
for necesario in kinfocenter vulkan-tools wayland-utils clinfo aha plymouth \
	linux-firmware-nvidia linux-firmware-amd linux-firmware-amdgpu firefox \
	calamares-git ckbcomp; do
	grep -qx "${necesario}" "${paquetes}" || fallo "Falta ${necesario} en la ISO."
done
if grep -qx 'google-chrome' "${paquetes}"; then
	fallo "google-chrome no puede ir en la ISO."
fi
if grep -q 'try_aur google-chrome' scripts/build-iso.sh; then
	fallo "La construcción sigue empaquetando Chrome."
fi
if grep -R -I -n --exclude=check.sh -- '--ozone-platform=wayland' branding archiso scripts tools .github; then
	fallo "Hay un --ozone-platform=wayland fijo. En X11 Chrome no arranca."
fi

for menu in archiso/grub/grub.cfg archiso/grub/loopback.cfg archiso/syslinux/archiso_sys-linux.cfg; do
	grep -q 'nomodeset' "${menu}" || fallo "${menu} no tiene gráficos seguros."
	grep -q 'processor.max_cstate=5' "${menu}" || fallo "${menu} no tiene el límite de C-state."
	grep -q 'usbcore.autosuspend=-1' "${menu}" || fallo "${menu} no tiene el ajuste de USB."
	grep -q 'pcie_aspm=off' "${menu}" || fallo "${menu} no tiene pcie_aspm=off."
done
grep -q 'gráficos seguros' archiso/grub/grub.cfg
grep -q 'graficos seguros' archiso/syslinux/archiso_sys-linux.cfg

test -f branding/pekarchos-branding/root/usr/share/icons/hicolor/48x48/apps/pekarchos.png
test -f branding/pekarchos-branding/root/usr/share/icons/hicolor/scalable/apps/pekarchos.svg
test -f branding/pekarchos-branding/root/usr/share/pekarchos/logo-full.png
test -f branding/pekarchos-branding/root/usr/share/pekarchos/logo.png
test -f branding/pekarchos-branding/root/usr/share/plymouth/themes/pekarchos/pekarchos.script
test -f branding/pekarchos-branding/root/usr/share/grub/themes/pekarchos/theme.txt
test -f branding/pekarchos-branding/root/etc/skel/.face.icon
grep -q 'install -m 0755' branding/pekarchos-branding/root/usr/lib/pekarchos/colocar-lanzadores.sh
grep -q 'Icon=pekarchos' branding/pekarchos-branding/root/usr/share/applications/pekarchos-welcome.desktop
grep -q 'unpackfs' branding/pekarchos-branding/root/etc/calamares/settings.conf
grep -q 'netinstall@escritorios' branding/pekarchos-branding/root/etc/calamares/settings.conf
grep -q 'netinstall@gpu' branding/pekarchos-branding/root/etc/calamares/settings.conf
grep -q 'immutable: true' branding/pekarchos-branding/root/etc/calamares/modules/netinstall_gpu.conf
grep -q 'nvidia-open' branding/pekarchos-branding/root/etc/calamares/modules/netinstall_gpu.conf
if grep -R -n -E 'pacman .*390|nvidia-390xx-dkms' branding/pekarchos-branding/root/etc/calamares >/dev/null; then
	fallo "Calamares no puede instalar el controlador 390 en esta fase."
fi
if grep -n 'pacman ' branding/pekarchos-branding/root/usr/lib/pekarchos/gpu-390-hook.sh >/dev/null; then
	fallo "El gancho de NVIDIA 390 no puede llamar a pacman todavía."
fi
python3 - <<'PY'
import re
from pathlib import Path
root = Path("branding/pekarchos-branding/root/etc/calamares")
text = (root / "settings.conf").read_text()
names = re.findall(r"^\s+- ([a-z0-9]+(?:@[a-z0-9]+)?)\s*$", text, re.M)
missing = []
for name in names:
    base, _, inst = name.partition("@")
    conf = root / "modules" / (f"{base}_{inst}.conf" if inst else f"{base}.conf")
    if not conf.is_file():
        missing.append(str(conf))
if missing:
    raise SystemExit("Faltan configuraciones de Calamares: " + ", ".join(missing))
PY
grep -q 'aur_build_required calamares-git' scripts/build-iso.sh
grep -q 'd62849a39a97dbcd4bd9389ebc38e9643a81fa86' scripts/build-iso.sh
test -f branding/pins/calamares-git.commit
test -f branding/pins/ckbcomp.commit
grep -q 'CC BY-SA 4.0' LICENSE-ARTWORK
grep -q 'CC BY-SA 4.0' THIRD-PARTY.md
python3 -c 'import json; json.load(open("branding/pekarchos-branding/root/usr/share/pekarchos/archinstall.json"))'

if grep -q 'upload-artifact' .github/workflows/build-iso.yml; then
	fallo "El flujo todavía sube la ISO como artefacto."
fi
if grep -q 'branches:' .github/workflows/build-iso.yml; then
	fallo "El flujo no debe construir en cada push a una rama."
fi

tmp=$(mktemp -d)
printf 'x\n' >"${tmp}/pekarchos-0.3.0-x86_64.iso"
(
	cd "${tmp}"
	sha256sum ./*.iso | sed 's| \./| |' > SHA256SUMS
)
grep -q 'pekarchos-0.3.0-x86_64.iso$' "${tmp}/SHA256SUMS"
if grep -q '/' "${tmp}/SHA256SUMS"; then
	fallo "La suma de prueba de ejemplo lleva una ruta."
fi
rm -rf "${tmp}"

scripts=(
	scripts/build-iso.sh
	scripts/check.sh
	scripts/test-install-qemu.sh
	archiso/profiledef.sh
	archiso/airootfs/root/customize_airootfs.sh
	archiso/airootfs/usr/local/bin/pekarchos-export-branding
	branding/pekarchos-branding/root/usr/lib/pekarchos/install-chroot.sh
	branding/pekarchos-branding/root/usr/lib/pekarchos/comun.sh
	branding/pekarchos-branding/root/usr/lib/pekarchos/colocar-lanzadores.sh
	branding/pekarchos-branding/root/usr/lib/pekarchos/poner-avatar.sh
	branding/pekarchos-branding/root/usr/lib/pekarchos/calamares-limpiar.sh
	branding/pekarchos-branding/root/usr/lib/pekarchos/gpu-390-hook.sh
	branding/pekarchos-branding/root/usr/lib/pekarchos/instalar-firmware.sh
	branding/pekarchos-branding/root/usr/local/bin/pekarchos-calamares
	branding/pekarchos-branding/root/usr/local/bin/pekarchos-install
	branding/pekarchos-branding/root/usr/local/bin/pekarchos-install-archinstall
	branding/pekarchos-branding/root/usr/local/bin/pekarchos-welcome-install
	branding/pekarchos-branding/root/usr/local/bin/pekarchos-gpu-quirks
	branding/pekarchos-branding/root/usr/local/bin/pekarchos-trust-launchers
	branding/pekarchos-branding/root/usr/local/bin/pekarchos-apply-look
	branding/pekarchos-branding/root/usr/local/bin/pekarchos-sddm-xsetup
	branding/pekarchos-branding/root/usr/share/pekarchos/postinstall.sh
)
for script in "${scripts[@]}"; do
	bash -n "${script}"
done

if command -v shellcheck >/dev/null 2>&1; then
	# info: avisos previos (comillas a propósito, printf -v). warning y error sí paran.
	shellcheck -S warning -x "${scripts[@]}"
else
	echo "shellcheck no está instalado; solo se hizo bash -n."
fi

python3 -m py_compile \
	tools/generate_assets.py \
	tools/make_logo_icons.py \
	branding/pekarchos-branding/root/usr/local/bin/pekarchos-welcome

echo "Comprobaciones ligeras correctas (versión ${ver})."
