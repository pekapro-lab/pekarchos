#!/usr/bin/env bash
# Prueba el instalador de verdad.
# El núcleo de este entorno no monta FAT, así que las instalaciones corren
# dentro de QEMU con el núcleo de Arch (que sí tiene vfat, como la ISO).
# Luego se arranca cada disco instalado: UEFI con OVMF y BIOS con SeaBIOS.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
INST="${ROOT}/branding/pekarchos-branding/root/usr/local/bin/pekarchos-install"
HELPER="${ROOT}/branding/pekarchos-branding/root/usr/lib/pekarchos/install-chroot.sh"
WORK="${PEKARCHOS_TEST_WORK:-/tmp/pekarchos-install-test}"
USER_NAME=peka
USER_PASS='Peka-Clave-9'

if [[ "${1:-}" == "--inside" ]]; then
	ROOT=/src
	INST=/src/branding/pekarchos-branding/root/usr/local/bin/pekarchos-install
	HELPER=/src/branding/pekarchos-branding/root/usr/lib/pekarchos/install-chroot.sh
	WORK=/work
fi

log() { printf '==> %s\n' "$*"; }

inside() {
	log "Preparando Arch para probar el instalador"
	pacman-key --init
	pacman-key --populate archlinux
	pacman -Sy --noconfirm archlinux-keyring
	pacman -S --noconfirm --needed \
		base linux grub efibootmgr sudo dosfstools e2fsprogs \
		arch-install-scripts gptfdisk parted rsync python kbd zstd

	mkdir -p /run/archiso /etc/sddm.conf.d /etc/sudoers.d \
		/etc/systemd/system/getty@tty1.service.d \
		/etc/mkinitcpio.conf.d /etc/systemd/system/multi-user.target.wants
	if ! id live >/dev/null 2>&1; then
		useradd -m -s /bin/bash live
	fi
	echo 'live:live' | chpasswd
	cat >/etc/sddm.conf.d/10-autologin.conf <<'EOF'
[Autologin]
User=live
Session=plasma
EOF
	printf 'live ALL=(ALL) NOPASSWD: ALL\n' >/etc/sudoers.d/live
	chmod 0440 /etc/sudoers.d/live
	printf '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin live --noclear %%I $TERM\n' \
		>/etc/systemd/system/getty@tty1.service.d/autologin.conf
	cat >/etc/systemd/system/sddm.service <<'EOF'
[Unit]
Description=SDDM de prueba
[Service]
Type=oneshot
ExecStart=/usr/bin/true
RemainAfterExit=yes
[Install]
WantedBy=graphical.target
EOF
	ln -sfn /usr/lib/systemd/system/serial-getty@.service \
		/etc/systemd/system/multi-user.target.wants/serial-getty@ttyS0.service
	cat >/etc/mkinitcpio.conf.d/qemu-test.conf <<'EOF'
MODULES+=(ext4 vfat fat nls_cp437 ata_piix ata_generic ahci sd_mod virtio_blk virtio_pci virtio_scsi)
COMPRESSION="zstd"
COMPRESSION_OPTIONS=(-1)
EOF
	if [[ -f /etc/mkinitcpio.d/linux.preset ]]; then
		sed -i '/_uki=/d' /etc/mkinitcpio.d/linux.preset
	fi
	if [[ -f /etc/default/grub ]]; then
		sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200"/' /etc/default/grub
		grep -q '^GRUB_TERMINAL_OUTPUT=' /etc/default/grub || cat >>/etc/default/grub <<'EOF'
GRUB_TERMINAL_INPUT="console serial"
GRUB_TERMINAL_OUTPUT="console serial"
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
EOF
	fi
	printf '%s\n' '# La raíz la monta el initramfs.' >/etc/fstab
	ln -sfn /usr/share/zoneinfo/Europe/Madrid /etc/localtime
	printf 'LANG=C.UTF-8\n' >/etc/locale.conf
	ln -sfn /dev/null /etc/systemd/system/systemd-firstboot.service
	# console-getty y serial-getty a la vez se pisan si la consola es la serie.
	ln -sfn /dev/null /etc/systemd/system/console-getty.service
	mkinitcpio -P

	esperar_fallo() {
		local texto="$1"
		shift
		local out rc
		set +e
		out=$(env "$@" bash "${INST}" 2>&1)
		rc=$?
		set -e
		printf '%s\n' "${out}" | tail -n 15
		if [[ "${rc}" -eq 0 ]]; then
			echo "Se esperaba un fallo (${texto}) y el instalador terminó bien."
			exit 1
		fi
		if ! grep -qi "${texto}" <<<"${out}"; then
			echo "El fallo no contiene «${texto}»."
			exit 1
		fi
		log "Fallo esperado correcto: ${texto}"
	}

	log "Usuario vacío, contraseña vacía, nombre reservado y nombre inválido"
	esperar_fallo obligatorio PEKARCHOS_INSTALL_NONINTERACTIVE=1 PEKARCHOS_USER= PEKARCHOS_PASS=x
	esperar_fallo obligatoria PEKARCHOS_INSTALL_NONINTERACTIVE=1 PEKARCHOS_USER=peka PEKARCHOS_PASS=
	esperar_fallo reservado PEKARCHOS_INSTALL_NONINTERACTIVE=1 PEKARCHOS_USER=live PEKARCHOS_PASS=x
	esperar_fallo 'no es válido' PEKARCHOS_INSTALL_NONINTERACTIVE=1 PEKARCHOS_USER=Peka PEKARCHOS_PASS=x

	install -D -m755 "${INST}" /usr/local/bin/pekarchos-install
	install -D -m755 "${HELPER}" /usr/lib/pekarchos/install-chroot.sh
	for extra in /src/branding/pekarchos-branding/root/usr/lib/pekarchos/*.sh; do
		install -D -m755 "${extra}" "/usr/lib/pekarchos/$(basename "${extra}")"
	done
	cat >/usr/local/bin/pekarchos-probar <<EOF
#!/bin/bash
set -euo pipefail
grep -q 'pekarchos.test=1' /proc/cmdline || exit 0
mkdir -p /run/archiso
modprobe vfat || true
modprobe fat || true
echo PEKARCHOS_TEST_BEGIN
for _i in \$(seq 1 50); do
	[[ -b /dev/vdb && -b /dev/vdc && -b /dev/vdd ]] && break
	sleep 0.2
done
[[ -b /dev/vdb && -b /dev/vdc && -b /dev/vdd ]] || { echo PEKARCHOS_INSTALL_FAIL discos; lsblk; exit 1; }
echo '--- UEFI ---'
PEKARCHOS_MODO=uefi PEKARCHOS_DISK=/dev/vdb PEKARCHOS_OPTION=1 \\
	bash /usr/local/bin/pekarchos-install <<'ANSWERS'

live
Apeka
${USER_NAME}
Peka Pro


${USER_PASS}
otra-clave
${USER_PASS}
${USER_PASS}
n
BORRAR
INSTALAR
ANSWERS
echo PEKARCHOS_INSTALL_UEFI_OK
echo '--- BIOS GPT ---'
PEKARCHOS_INSTALL_NONINTERACTIVE=1 PEKARCHOS_MODO=bios PEKARCHOS_DISK=/dev/vdc \\
	PEKARCHOS_OPTION=1 PEKARCHOS_USER='${USER_NAME}' PEKARCHOS_PASS='${USER_PASS}' \\
	PEKARCHOS_FULLNAME='Peka Pro' bash /usr/local/bin/pekarchos-install
echo PEKARCHOS_INSTALL_BIOSGPT_OK
echo '--- BIOS MBR ---'
sfdisk /dev/vdd <<'SF'
label: dos
start=2048, type=83, bootable
SF
udevadm settle || true
sleep 0.5
PEKARCHOS_INSTALL_NONINTERACTIVE=1 PEKARCHOS_MODO=bios PEKARCHOS_DISK=/dev/vdd \\
	PEKARCHOS_OPTION=2 PEKARCHOS_ROOT_PART=/dev/vdd1 \\
	PEKARCHOS_USER='${USER_NAME}' PEKARCHOS_PASS='${USER_PASS}' \\
	PEKARCHOS_FULLNAME='Peka Pro' bash /usr/local/bin/pekarchos-install
echo PEKARCHOS_INSTALL_BIOSMBR_OK
echo PEKARCHOS_INSTALLS_OK
systemctl poweroff || poweroff
EOF
	chmod 755 /usr/local/bin/pekarchos-probar
	cat >/etc/systemd/system/pekarchos-test.service <<'EOF'
[Unit]
Description=Prueba del instalador
After=local-fs.target systemd-udevd.service
[Service]
Type=oneshot
ExecStart=/usr/local/bin/pekarchos-probar
StandardOutput=journal+console
StandardError=journal+console
[Install]
WantedBy=multi-user.target
EOF
	ln -sfn /etc/systemd/system/pekarchos-test.service \
		/etc/systemd/system/multi-user.target.wants/pekarchos-test.service

	log "Copiando el sistema vivo"
	mkdir -p "${WORK}/rootfs"
	rsync -aAX --one-file-system \
		--exclude=/work --exclude=/src --exclude=/proc --exclude=/sys --exclude=/dev \
		--exclude=/tmp --exclude=/run --exclude=/var/cache/pacman/pkg \
		/ "${WORK}/rootfs/"
	mkdir -p "${WORK}/rootfs"/{proc,sys,dev,run,tmp}
	cp -a /boot/vmlinuz-linux "${WORK}/vmlinuz"
	cp -a /boot/initramfs-linux.img "${WORK}/initramfs"
	printf 'listo\n' >"${WORK}/rootfs-ready"
	log "Sistema vivo listo"
}

qemu_bin() {
	if [[ "$(id -u)" -eq 0 ]]; then
		printf '%s\n' qemu-system-x86_64
	else
		printf '%s\n' "sudo -n qemu-system-x86_64"
	fi
}

esperar_serie() {
	local puerto="$1" marca="$2" segundos="$3" logf="$4"
	shift 4
	PEKARCHOS_QEMU_PORT="${puerto}" \
		PEKARCHOS_QEMU_LOG="${logf}" \
		PEKARCHOS_QEMU_MARK="${marca}" \
		PEKARCHOS_QEMU_SECONDS="${segundos}" \
		python3 - "$@" <<'PY'
import os, socket, subprocess, sys, time
port = int(os.environ["PEKARCHOS_QEMU_PORT"])
log_path = os.environ["PEKARCHOS_QEMU_LOG"]
mark = os.environ["PEKARCHOS_QEMU_MARK"]
limit = int(os.environ["PEKARCHOS_QEMU_SECONDS"])
cmd = sys.argv[1:]
log = open(log_path, "wb")
proc = subprocess.Popen(cmd)
sock = None
buf = b""
try:
    deadline = time.time() + 30
    while time.time() < deadline:
        try:
            sock = socket.create_connection(("127.0.0.1", port), 2)
            break
        except OSError:
            if proc.poll() is not None:
                sys.exit(f"QEMU terminó antes del serie ({proc.returncode}).")
            time.sleep(0.2)
    if sock is None:
        sys.exit("No se pudo conectar a la consola serie.")
    sock.settimeout(1)
    end = time.time() + limit
    while time.time() < end:
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            chunk = b""
        except OSError:
            chunk = b""
        if chunk:
            log.write(chunk)
            log.flush()
            sys.stdout.buffer.write(chunk)
            sys.stdout.buffer.flush()
            buf += chunk
        text = buf.decode("utf-8", "replace")
        if "PEKARCHOS_INSTALL_FAIL" in text or "Kernel panic" in text:
            sys.exit("La instalación dentro de QEMU ha fallado.")
        if mark in text:
            print("\nMarca vista: " + mark, flush=True)
            sys.exit(0)
        if proc.poll() is not None and mark not in text:
            sys.exit(f"QEMU cerró sin la marca {mark} ({proc.returncode}).")
    sys.exit("Tiempo agotado esperando " + mark)
finally:
    if sock is not None:
        sock.close()
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=15)
        except subprocess.TimeoutExpired:
            proc.kill()
    log.close()
PY
}

arrancar() {
	local img="$1" modo="$2" puerto="$3"
	log "Arranque QEMU ${modo}: ${img}"
	local -a qemu
	read -r -a qemu <<<"$(qemu_bin)"
	local -a args=(
		-machine "pc,accel=kvm:tcg"
		-m 1280
		-smp 2
		-drive "file=${img},format=raw,if=ide,index=0,media=disk"
		-serial "tcp:127.0.0.1:${puerto},server=on,wait=off"
		-display none
		-no-reboot
		-boot order=c
		-monitor none
	)
	if [[ "${modo}" == uefi ]]; then
		local code=/usr/share/OVMF/OVMF_CODE_4M.fd
		local vars=/usr/share/OVMF/OVMF_VARS_4M.fd
		[[ -f "${code}" && -f "${vars}" ]] || { echo "No está OVMF."; exit 1; }
		cp "${vars}" "${WORK}/ovmf-${modo}.fd"
		args+=(
			-drive "if=pflash,format=raw,readonly=on,file=${code}"
			-drive "if=pflash,format=raw,file=${WORK}/ovmf-${modo}.fd"
		)
	fi
	PEKARCHOS_QEMU_PORT="${puerto}" \
		PEKARCHOS_QEMU_LOG="${WORK}/serial-${modo}.log" \
		PEKARCHOS_QEMU_USER="${USER_NAME}" \
		PEKARCHOS_QEMU_PASS="${USER_PASS}" \
		python3 - "${qemu[@]}" "${args[@]}" <<'PY'
import os, socket, subprocess, sys, time

port = int(os.environ["PEKARCHOS_QEMU_PORT"])
log_path = os.environ["PEKARCHOS_QEMU_LOG"]
user = os.environ["PEKARCHOS_QEMU_USER"]
password = os.environ["PEKARCHOS_QEMU_PASS"]
cmd = sys.argv[1:]
log = open(log_path, "wb")
proc = subprocess.Popen(cmd)
sock = None
try:
    deadline = time.time() + 20
    while time.time() < deadline:
        try:
            sock = socket.create_connection(("127.0.0.1", port), 2)
            break
        except OSError:
            if proc.poll() is not None:
                sys.exit(f"QEMU terminó antes de abrir el serie ({proc.returncode}).")
            time.sleep(0.2)
    if sock is None:
        sys.exit("No se pudo conectar a la consola serie.")
    sock.settimeout(1)
    buf = b""
    stage = "login"
    step = 0
    # Órdenes cortas, de una en una. El resultado no aparece en el eco.
    # El resultado lleva un prefijo que no está en la orden (allí sale %s o $?).
    steps = [
        ("printf 'WHO:%s\\n' \"$(id -un)\"\n".encode(), b"WHO:" + user.encode()),
        ("printf 'GROUPS:%s\\n' \"$(id -nG)\"\n".encode(), b"GROUPS:"),
        (b"id live >/dev/null 2>&1; printf 'LIVE:%s\\n' $?\n", b"LIVE:1"),
        (b"grep -q es /etc/X11/xorg.conf.d/00-keyboard.conf; printf 'XKB:%s\\n' $?\n", b"XKB:0"),
        (b"grep -q XKB_DEFAULT_LAYOUT=es /etc/sddm.conf.d/20-pekarchos-keyboard.conf; printf 'SDDM:%s\\n' $?\n", b"SDDM:0"),
        (b"grep -q '^KEYMAP=es$' /etc/vconsole.conf; printf 'VC:%s\\n' $?\n", b"VC:0"),
        (("printf '%s\\n' '" + password + "' | sudo -S -p '' true; printf 'SUDO:%s\\n' $?\n").encode(), b"SUDO:0"),
        (b"test -f /var/log/pekarchos-install.log; printf 'LOG:%s\\n' $?\n", b"LOG:0"),
    ]
    end = time.time() + 300
    while time.time() < end:
        if proc.poll() is not None and stage != "step":
            sys.exit(f"QEMU se cerró antes de entrar ({proc.returncode}).")
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            chunk = b""
        except OSError:
            chunk = b""
        if chunk:
            log.write(chunk)
            log.flush()
            sys.stdout.buffer.write(chunk)
            sys.stdout.buffer.flush()
            buf += chunk
            if b"[6n" in chunk:
                sock.sendall(b"\x1b[24;80R")
        text = buf.decode("utf-8", "replace")
        low = text.lower()
        if "kernel panic" in low or "emergency mode" in low:
            sys.exit("El sistema no ha arrancado: pánico o modo de emergencia.")
        if stage == "login" and "login:" in low:
            sock.sendall((user + "\n").encode())
            stage = "password"
            buf = b""
        elif stage == "password" and ("assword" in text or "ontrase" in text):
            sock.sendall((password + "\n").encode())
            stage = "shell"
            buf = b""
        elif stage == "shell" and ("incorrect" in low):
            sys.exit("La contraseña del usuario no ha valido en el arranque.")
        elif stage == "shell" and ("$ " in text or "# " in text or text.rstrip().endswith("$") or text.rstrip().endswith("#")):
            sock.sendall(steps[0][0])
            stage = "step"
            buf = b""
        elif stage == "step" and steps[step][1] in buf.replace(b"\r", b""):
            if steps[step][1] == b"GROUPS:" and b"wheel" not in buf:
                continue
            step += 1
            if step == len(steps):
                print("\nArranque y entrada correctos.", flush=True)
                sys.exit(0)
            sock.sendall(steps[step][0])
            buf = b""
    sys.exit(f"Tiempo agotado esperando el arranque (fase {stage}, orden {step}).")
finally:
    if sock is not None:
        sock.close()
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()
    log.close()
PY
}

if [[ "${1:-}" == "--inside" ]]; then
	inside
	exit 0
fi

bash -n "${INST}"
bash -n "${HELPER}"
bash -n "${BASH_SOURCE[0]}"

if ! command -v qemu-system-x86_64 >/dev/null 2>&1 || [[ ! -f /usr/share/OVMF/OVMF_CODE_4M.fd ]]; then
	sudo apt-get update
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y qemu-system-x86 ovmf
fi

if docker info >/dev/null 2>&1; then
	DOCKER=(docker)
elif sudo docker info >/dev/null 2>&1; then
	DOCKER=(sudo docker)
else
	echo "Docker no está en marcha."
	exit 1
fi

rm -rf "${WORK}"
mkdir -p "${WORK}" /tmp/pekarchos-pacman
log "Preparando el sistema vivo de Arch"
"${DOCKER[@]}" run --rm \
	-v "${ROOT}:/src:ro" \
	-v "${WORK}:/work" \
	-v /tmp/pekarchos-pacman:/var/cache/pacman/pkg \
	archlinux:latest \
	bash /src/scripts/test-install-qemu.sh --inside

[[ -f "${WORK}/rootfs-ready" && -f "${WORK}/vmlinuz" && -f "${WORK}/initramfs" ]] || {
	echo "No se ha preparado el sistema vivo."
	exit 1
}

megs=$(sudo du -sm "${WORK}/rootfs" | awk '{print $1}')
log "Imagen del sistema vivo ($((megs + 1200)) MiB)"
truncate -s "$((megs + 1200))M" "${WORK}/live.img"
sudo mkfs.ext4 -F -d "${WORK}/rootfs" -L live "${WORK}/live.img"
truncate -s 8G "${WORK}/uefi.img"
truncate -s 8G "${WORK}/bios-gpt.img"
truncate -s 6G "${WORK}/bios-mbr.img"

log "Instalando dentro de QEMU con el núcleo de Arch"
read -r -a QEMU <<<"$(qemu_bin)"
esperar_serie 45450 PEKARCHOS_INSTALLS_OK 2400 "${WORK}/serial-instalacion.log" \
	"${QEMU[@]}" \
	-machine "pc,accel=kvm:tcg" \
	-m 2048 -smp 2 \
	-kernel "${WORK}/vmlinuz" \
	-initrd "${WORK}/initramfs" \
	-append "root=/dev/vda rw rootfstype=ext4 rootwait console=ttyS0,115200 systemd.firstboot=0 pekarchos.test=1" \
	-drive "file=${WORK}/live.img,if=virtio,format=raw" \
	-drive "file=${WORK}/uefi.img,if=virtio,format=raw" \
	-drive "file=${WORK}/bios-gpt.img,if=virtio,format=raw" \
	-drive "file=${WORK}/bios-mbr.img,if=virtio,format=raw" \
	-serial tcp:127.0.0.1:45450,server=on,wait=off \
	-display none -no-reboot -monitor none

arrancar "${WORK}/uefi.img" uefi 45454
arrancar "${WORK}/bios-gpt.img" bios-gpt 45455
arrancar "${WORK}/bios-mbr.img" bios-mbr 45456

log "UEFI, BIOS GPT y BIOS MBR arrancan, y ${USER_NAME} entra."
