#!/usr/bin/env bash
# Se ejecuta con arch-chroot, dentro del sistema ya copiado al disco.
# Lee /root/.pekarchos-creds y lo borra antes de seguir.
set -euo pipefail

ESP_GUID=c12a7328-f81f-11d2-ba4b-00a0c93ec93b
BIOS_GUID=21686148-6449-6e6f-744e-656564454649

tipo_part() {
	local part="$1" disco="" n="" tipo=""
	disco=$(lsblk -no PKNAME "${part}" 2>/dev/null || true)
	disco=${disco%%$'\n'*}
	if [[ -n "${disco}" ]]; then
		n=$(cat "/sys/class/block/$(basename "${part}")/partition" 2>/dev/null || true)
		disco="/dev/${disco}"
	elif [[ "${part}" =~ ^(/dev/.*[0-9])p([0-9]+)$ ]]; then
		disco="${BASH_REMATCH[1]}"
		n="${BASH_REMATCH[2]}"
	elif [[ "${part}" =~ ^(/dev/[^0-9]+)([0-9]+)$ ]]; then
		disco="${BASH_REMATCH[1]}"
		n="${BASH_REMATCH[2]}"
	fi
	if [[ -n "${disco}" && -n "${n}" ]]; then
		tipo=$(sfdisk --part-type "${disco}" "${n}" 2>/dev/null || true)
		tipo=$(printf '%s' "${tipo}" | tr 'A-F' 'a-f')
		tipo=${tipo//[[:space:]]/}
		if [[ -n "${tipo}" ]]; then
			printf '%s' "${tipo}"
			return 0
		fi
	fi
	tipo=$(lsblk -dno PARTTYPE "${part}" 2>/dev/null | tr 'A-F' 'a-f' || true)
	printf '%s' "${tipo//[[:space:]]/}"
}

fallo() {
	echo
	echo "ERROR: $*"
	exit 1
}

# shellcheck source=comun.sh
source /usr/lib/pekarchos/comun.sh


dec() {
	if [[ -z "${1:-}" ]]; then
		printf ''
		return 0
	fi
	printf '%s' "$1" | base64 -d
}

if [[ ! -f /root/.pekarchos-creds ]]; then
	fallo "faltan los datos del usuario. No se puede crear la cuenta."
fi
# shellcheck disable=SC1091
source /root/.pekarchos-creds
USUARIO=$(dec "${USUARIO:-}")
NOMBRE=$(dec "${NOMBRE:-}")
PASS=$(dec "${PASS:-}")
ROOTPASS=$(dec "${ROOTPASS:-}")
MODO=${MODO:-}
DISCO=${DISCO:-}
OPCION=${OPCION:-}
EFI_DIR=${EFI_DIR:-}
rm -f /root/.pekarchos-creds
trap 'rm -f /root/.pekarchos-creds; unset PASS ROOTPASS' EXIT

if [[ -z "${USUARIO}" || -z "${PASS}" ]]; then
	fallo "el usuario o la contraseña llegaron vacíos. No se deja un sistema sin cuenta."
fi
if [[ -z "${DISCO}" || -z "${MODO}" ]]; then
	fallo "faltan el disco o el modo de arranque."
fi

echo "==> Idioma"
sed -i 's/^#\s*\(es_ES.UTF-8 UTF-8\)/\1/; s/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
systemd-machine-id-setup >/dev/null 2>&1 || true

quitar_cuenta_live

echo "==> Creando ${USUARIO}"
if ! getent group wheel >/dev/null; then
	fallo "no existe el grupo wheel. Sin ese grupo no hay sudo y el escritorio no se puede administrar."
fi
if id "${USUARIO}" >/dev/null 2>&1; then
	fallo "el usuario ${USUARIO} ya existe. No lo reutilizo."
fi
grupos=()
for g in wheel audio video optical storage network lp scanner users render input; do
	if getent group "${g}" >/dev/null; then
		grupos+=("${g}")
	fi
done
if ((${#grupos[@]})); then
	useradd -m -G "$(IFS=,; echo "${grupos[*]}")" -s /bin/bash -c "${NOMBRE}" "${USUARIO}"
else
	fallo "no hay grupos a los que añadir la cuenta."
fi
install -d -o "${USUARIO}" -g "${USUARIO}" "/home/${USUARIO}/.config"
cat >"/home/${USUARIO}/.config/kxkbrc" <<'KB'
[Layout]
LayoutList=es
Model=pc105
Use=true
KB
chown "${USUARIO}:${USUARIO}" "/home/${USUARIO}/.config/kxkbrc"
preparar_cuenta "${USUARIO}"

printf '%s:%s\n' "${USUARIO}" "${PASS}" | chpasswd

install -d -m 0750 /etc/sudoers.d
printf '%%wheel ALL=(ALL:ALL) ALL\n' >/etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
visudo -cf /etc/sudoers.d/10-wheel

if [[ -n "${ROOTPASS}" ]]; then
	printf 'root:%s\n' "${ROOTPASS}" | chpasswd
	echo "root tiene contraseña."
else
	passwd -l root >/dev/null
	echo "root queda bloqueado a propósito."
fi

echo "==> Comprobando que la cuenta puede autenticar"
if ! command -v python3 >/dev/null 2>&1; then
	fallo "hace falta python3 para comprobar la contraseña. No se da por creada la cuenta."
fi
export PEKARCHOS_CHK_USER="${USUARIO}"
export PEKARCHOS_CHK_PASS="${PASS}"
export PEKARCHOS_CHK_ROOT="${ROOTPASS}"
python3 - <<'PY'
import ctypes
import ctypes.util
import os
import sys

def shadow(user):
    with open("/etc/shadow", encoding="utf-8") as fh:
        for line in fh:
            parts = line.rstrip("\n").split(":")
            if parts and parts[0] == user:
                return parts[1]
    sys.exit(f"ERROR: no hay entrada de {user} en /etc/shadow.")

def libcrypt():
    names = []
    found = ctypes.util.find_library("crypt")
    if found:
        names.append(found)
    names.extend(["libcrypt.so.2", "libcrypt.so.1", "libcrypt.so"])
    for name in names:
        try:
            lib = ctypes.CDLL(name)
        except OSError:
            continue
        lib.crypt.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
        lib.crypt.restype = ctypes.c_char_p
        return lib
    sys.exit("ERROR: no encuentro libcrypt para comprobar la contraseña.")

def autentica(user, password):
    hashed = shadow(user)
    if not hashed or hashed[0] in "*!":
        sys.exit(f"ERROR: la cuenta {user} no tiene una contraseña usable.")
    got = libcrypt().crypt(password.encode(), hashed.encode())
    if not got or got.decode() != hashed:
        sys.exit(f"ERROR: la contraseña de {user} no coincide con /etc/shadow.")
    print(f"Contraseña de {user} comprobada contra /etc/shadow.")

autentica(os.environ["PEKARCHOS_CHK_USER"], os.environ["PEKARCHOS_CHK_PASS"])
root_hash = shadow("root")
root_pass = os.environ.get("PEKARCHOS_CHK_ROOT", "")
if root_pass:
    autentica("root", root_pass)
else:
    if not root_hash or root_hash[0] not in "*!":
        sys.exit("ERROR: root no ha quedado bloqueado.")
    print("root bloqueado a propósito.")
PY
unset PEKARCHOS_CHK_USER PEKARCHOS_CHK_PASS PEKARCHOS_CHK_ROOT PASS ROOTPASS

grupos_id=$(id -nG "${USUARIO}")
echo "Grupos de ${USUARIO}: ${grupos_id}"
case " ${grupos_id} " in
*" wheel "*) ;;
*) fallo "${USUARIO} no está en el grupo wheel." ;;
esac
if [[ ! -d "/home/${USUARIO}" ]]; then
	fallo "no existe /home/${USUARIO}."
fi
dueno=$(stat -c '%U' "/home/${USUARIO}")
if [[ "${dueno}" != "${USUARIO}" ]]; then
	fallo "el hogar de ${USUARIO} pertenece a ${dueno}."
fi
sudo_lista=$(sudo -l -U "${USUARIO}" 2>&1 || true)
printf '%s\n' "${sudo_lista}"
case "${sudo_lista}" in
*NOPASSWD*) fallo "sudo del usuario nuevo no puede ser sin contraseña." ;;
esac
if ! grep -q '(ALL' <<<"${sudo_lista}"; then
	fallo "${USUARIO} no puede usar sudo."
fi
if id live >/dev/null 2>&1; then
	fallo "el usuario live ha vuelto a aparecer."
fi
if [[ -e /etc/sudoers.d/live ]]; then
	fallo "sigue /etc/sudoers.d/live."
fi
if grep -Rqs 'User=live' /etc/sddm.conf /etc/sddm.conf.d 2>/dev/null; then
	fallo "sigue un autologin del usuario live. SDDM entraría en bucle."
fi
if ! grep -q 'XkbLayout" "es"' /etc/X11/xorg.conf.d/00-keyboard.conf; then
	fallo "el teclado de X11 no está en español."
fi
if ! grep -q '^KEYMAP=es$' /etc/vconsole.conf; then
	fallo "el teclado de consola no está en español."
fi
if ! grep -q 'XKB_DEFAULT_LAYOUT=es' /etc/sddm.conf.d/20-pekarchos-keyboard.conf; then
	fallo "SDDM no tiene el teclado español."
fi
if ! grep -q '^LayoutList=es$' "/home/${USUARIO}/.config/kxkbrc"; then
	fallo "Plasma no tiene el teclado español para ${USUARIO}."
fi
if ! grep -q '^LANG=es_ES.UTF-8$' /etc/locale.conf; then
	fallo "el idioma del sistema no es es_ES.UTF-8."
fi
echo "Usuario ${USUARIO} comprobado: existe, autentica, está en wheel y tiene sudo."

echo "==> Llavero de pacman"
pacman-key --init
pacman-key --populate archlinux || true

echo "==> Paquetes del live y firmware"
quitar_paquetes_live
instalar_firmware

echo "==> initramfs"
enganchar_plymouth
install -d /etc/mkinitcpio.conf.d
printf '%s\n' 'MODULES+=(ext4 vfat)' >/etc/mkinitcpio.conf.d/pekarchos.conf
if ! mkinitcpio -P; then
	fallo "no se pudo generar el initramfs. Sin él GRUB no puede arrancar el sistema."
fi

echo "==> Servicios"
activar() { systemctl list-unit-files "$1" >/dev/null 2>&1 && systemctl enable "$1" || true; }
activar NetworkManager.service
activar bluetooth.service
activar cups.socket
activar power-profiles-daemon.service
activar systemd-timesyncd.service
activar_sddm() {
	local unidad=""
	if [[ -f /usr/lib/systemd/system/sddm.service ]]; then
		unidad=/usr/lib/systemd/system/sddm.service
	elif [[ -f /etc/systemd/system/sddm.service ]]; then
		unidad=/etc/systemd/system/sddm.service
	else
		fallo "no está la unidad de SDDM. El escritorio no arrancaría."
	fi
	if systemctl enable sddm.service; then
		return 0
	fi
	install -d /etc/systemd/system/graphical.target.wants
	ln -sfn "${unidad}" /etc/systemd/system/graphical.target.wants/sddm.service
}
activar_sddm
if ! systemctl set-default graphical.target; then
	ln -sfn /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target
fi

echo "==> GRUB"
sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grep -q '^GRUB_DISABLE_OS_PROBER=false' /etc/default/grub || echo 'GRUB_DISABLE_OS_PROBER=false' >>/etc/default/grub
if grep -q '^GRUB_DISTRIBUTOR=' /etc/default/grub; then
	sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="PekarchOS"/' /etc/default/grub
else
	echo 'GRUB_DISTRIBUTOR="PekarchOS"' >>/etc/default/grub
fi
if grep -q '^GRUB_TIMEOUT=' /etc/default/grub; then
	sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
else
	echo 'GRUB_TIMEOUT=5' >>/etc/default/grub
fi
activar_tema_grub
echo "Disco ${DISCO}:"
lsblk -o NAME,SIZE,FSTYPE,PARTTYPENAME,PARTTYPE,MOUNTPOINTS "${DISCO}" || true
echo "Tabla:"
sfdisk -d "${DISCO}" || true

if [[ "${MODO}" == uefi ]]; then
	if [[ -z "${EFI_DIR}" ]]; then
		fallo "arranque UEFI sin directorio EFI."
	fi
	if ! mountpoint -q "${EFI_DIR}"; then
		fallo "${EFI_DIR} no es un punto de montaje. La partición EFI no está montada."
	fi
	fstype=$(findmnt -no FSTYPE "${EFI_DIR}" || true)
	if [[ "${fstype}" != vfat ]]; then
		fallo "la partición EFI montada en ${EFI_DIR} no es FAT (es ${fstype:-desconocido})."
	fi
	origen=$(findmnt -no SOURCE "${EFI_DIR}" || true)
	origen=${origen%%[*}
	origen=${origen%%$'\n'*}
	ptype=$(tipo_part "${origen}")
	echo "EFI ${origen} tipo ${ptype:-desconocido}, montada en ${EFI_DIR}, sistema de archivos ${fstype}."
	case "${ptype}" in
	"${ESP_GUID}" | ef | 0xef) ;;
	*)
		nombre=$(lsblk -dno PARTTYPENAME "${origen}" 2>/dev/null || true)
		case "${nombre}" in
		"EFI System" | "EFI system partition") ;;
		*)
			fallo "la partición ${origen} no es EFI System (tipo «${ptype:-vacío}», nombre «${nombre}»). GRUB no puede instalarse ahí."
			;;
		esac
		;;
	esac

	nvram_ok=0
	echo "Orden: grub-install --target=x86_64-efi --efi-directory=${EFI_DIR} --bootloader-id=PekarchOS"
	if grub-install --target=x86_64-efi --efi-directory="${EFI_DIR}" --bootloader-id=PekarchOS; then
		nvram_ok=1
		echo "GRUB quedó registrado en la NVRAM con el identificador PekarchOS."
	else
		echo "AVISO: grub-install no pudo registrar PekarchOS en la NVRAM."
		echo "En VirtualBox y en algunas máquinas virtuales efibootmgr falla aquí."
		echo "A veces el núcleo acompaña el fallo con «GPT: Use GNU Parted to correct GPT errors»."
		echo "Se intenta la copia de reserva, que no usa la NVRAM."
	fi

	if [[ "${OPCION}" == 1 ]]; then
		echo "Orden: grub-install --target=x86_64-efi --efi-directory=${EFI_DIR} --bootloader-id=PekarchOS --removable --no-nvram"
		if grub-install --target=x86_64-efi --efi-directory="${EFI_DIR}" --bootloader-id=PekarchOS --removable --no-nvram; then
			echo "Copia de reserva escrita en EFI/BOOT/BOOTX64.EFI."
		elif [[ "${nvram_ok}" == 1 ]]; then
			echo "AVISO: no se pudo escribir EFI/BOOT/BOOTX64.EFI. La entrada de la NVRAM sí está."
		else
			fallo "no se pudo instalar GRUB para UEFI: falló el registro en la NVRAM y también la copia --removable. El disco no arrancará."
		fi
	elif [[ "${nvram_ok}" != 1 ]]; then
		echo "Orden: grub-install --target=x86_64-efi --efi-directory=${EFI_DIR} --bootloader-id=PekarchOS --no-nvram"
		if ! grub-install --target=x86_64-efi --efi-directory="${EFI_DIR}" --bootloader-id=PekarchOS --no-nvram; then
			fallo "no se pudo copiar GRUB a la partición EFI. En un disco compartido con Windows no se pisa EFI/BOOT."
		fi
		echo "AVISO: el binario está en EFI/PekarchOS pero el firmware no lo ha registrado."
		echo "No se toca EFI/BOOT para no quitar el arranque de Windows."
		echo "Si el equipo no muestra PekarchOS, elige ese archivo en el menú del firmware."
	fi

	mapa=$(find "${EFI_DIR}" \( -iname 'grubx64.efi' -o -iname 'bootx64.efi' \) -print || true)
	if [[ -z "${mapa}" ]]; then
		echo "Contenido de ${EFI_DIR}:"
		find "${EFI_DIR}" -maxdepth 4 -type f -print || true
		fallo "la partición EFI no contiene grubx64.efi ni BOOTX64.EFI."
	fi
	echo "Binarios EFI:"
	printf '%s\n' "${mapa}"
else
	label=$(blkid -o value -s PTTYPE "${DISCO}" || true)
	if [[ -z "${label}" ]]; then
		if sfdisk -d "${DISCO}" 2>/dev/null | grep -q 'label: gpt'; then
			label=gpt
		elif sfdisk -d "${DISCO}" 2>/dev/null | grep -q 'label: dos'; then
			label=dos
		fi
	fi
	echo "Tabla de particiones para BIOS: ${label:-desconocida}"
	if [[ "${label}" == gpt ]]; then
		bios=""
		while read -r parte tipo_parte; do
			[[ "${tipo_parte}" == part ]] || continue
			tipo=$(tipo_part "${parte}")
			if [[ "${tipo}" == "${BIOS_GUID}" ]]; then
				bios="${parte}"
				break
			fi
		done < <(lsblk -lnpo NAME,TYPE "${DISCO}")
		if [[ -z "${bios}" ]]; then
			echo "GRUB, si se fuerza, diría: this GPT partition label contains no BIOS Boot Partition."
			fallo "el disco ${DISCO} es GPT y no tiene partición BIOS boot (${BIOS_GUID}), sin formatear, de aproximadamente 1 MiB. Sin ella GRUB no puede incrustarse y el disco no arranca en BIOS."
		fi
		echo "Partición BIOS boot: ${bios}"
	elif [[ "${label}" == dos ]]; then
		echo "Disco MBR: GRUB se instala en el sector de arranque. La primera partición tiene que dejar el hueco de 1 MiB (empezar en el sector 2048)."
	else
		fallo "la tabla «${label:-vacía}» no sirve para instalar GRUB en BIOS. Hace falta GPT con partición BIOS boot, o MBR."
	fi
	echo "Orden: grub-install --target=i386-pc ${DISCO}"
	if ! grub-install --target=i386-pc "${DISCO}"; then
		fallo "grub-install --target=i386-pc ${DISCO} ha fallado. No se ha instalado el arranque."
	fi
	firma=$(dd if="${DISCO}" bs=1 skip=510 count=2 2>/dev/null | od -An -tx1 | tr -d ' \n' || true)
	echo "Firma del sector de arranque: ${firma:-vacía}"
	if [[ "${firma}" != *55*aa* && "${firma}" != *55aa* ]]; then
		fallo "el primer sector de ${DISCO} no tiene la firma de arranque 55 aa. GRUB no ha quedado escrito."
	fi
fi

echo "Orden: grub-mkconfig -o /boot/grub/grub.cfg"
if ! grub-mkconfig -o /boot/grub/grub.cfg; then
	fallo "grub-mkconfig no ha podido escribir /boot/grub/grub.cfg."
fi
if ! grep -q 'menuentry' /boot/grub/grub.cfg; then
	fallo "el menú de GRUB está vacío."
fi
if ! grep -q 'vmlinuz' /boot/grub/grub.cfg; then
	fallo "el menú de GRUB no arranca ningún núcleo."
fi
echo "Entradas de GRUB:"
awk '/menuentry /{print; n++; if (n==20) exit}' /boot/grub/grub.cfg
echo "GRUB instalado."
