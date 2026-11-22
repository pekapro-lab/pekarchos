# PekarchOS

PekarchOS es un sistema en vivo basado en Arch Linux, hecho por Pekapro. Arranca en KDE Plasma 6 (Wayland), en español, con el teclado de España y la zona horaria de Madrid. El nombre en `/etc/os-release` es PekarchOS y el hostname del medio en vivo es `pekarchos`.

PekarchOS no está afiliado a Arch Linux. No usa el logotipo de Arch. «Arch de Peka» es el lema del logotipo de Pekapro.

La versión de esta rama es la **0.3.0**. Sale del archivo [`VERSION`](VERSION) y de ahí pasan a `os-release`, el paquete de marca, la bienvenida y el nombre de la ISO: `pekarchos-0.3.0-x86_64.iso`.

## Requisitos

- Procesador de 64 bits
- 4 GiB de RAM (con 8 GiB va más holgado)
- 20 GiB libres en el disco donde se instale
- UEFI o BIOS
- Un USB de 8 GiB o más, si se graba

## Qué trae el escritorio

Conjunto corto de Plasma (`plasma-desktop`), no `plasma-meta`:

- Sesión Plasma en Wayland. En los repos actuales de Arch no está `plasma-x11-session`.
- SDDM con el tema PekarchOS. En el live, el usuario entra solo.
- Fondo y esquemas PekarchOS Neon (CC0), iconos [Candy](THIRD-PARTY.md) (GPL-3.0) con respaldo Breeze, cursor y widgets Breeze, decoración Plastik.
- Logotipo de Peka / Pekapro (CC BY-SA 4.0): iconos, bienvenida, avatar, Acerca de, Plymouth y GRUB. Ver [LICENSE-ARTWORK](LICENSE-ARTWORK).
- Animación de arranque Plymouth y tema de GRUB, en la ISO y en el sistema instalado.
- Centro de información (`kinfocenter`), con `vulkan-tools`, `wayland-utils`, `clinfo` y `aha` para que esas páginas no salgan vacías.
- fastfetch al abrir una terminal.

Usuario del medio en vivo:

| | |
| --- | --- |
| Usuario | `live` |
| Contraseña | `live` |
| sudo | sin contraseña |

La cuenta `root` está bloqueada. SSH no se arranca solo.

## Programas

- Navegador por defecto: **Firefox** (`firefox-i18n-es-es`). También van Falkon y KTorrent.
- Google Chrome **no** se redistribuye. La bienvenida puede instalarlo desde Flathub (`com.google.Chrome`), que lo descarga de Google y lo actualiza.
- LibreOffice Fresh en español, VLC, GIMP, Kate, Dolphin, Konsole, Ark y Spectacle.
- Vídeo: OBS Studio, Kdenlive, Shotcut, guvcview y HandBrake.
- Gráficos: Blender, Krita y Vokoscreen.
- Audio: Audacity, Hydrogen, Yoshimi y Elisa.
- Juegos: Wine Staging, Lutris, PlayOnLinux, Steam (multilib), FooBillard++, DXVK, Winetricks, GameMode y MangoHud.
- Flatpak, Discover y Flathub (si la construcción pudo añadir el remoto).
- NetworkManager, PipeWire, Bluetooth e impresión.

DXVK, PlayOnLinux y FooBillard++ se construyen desde el AUR con el commit fijado en `branding/pins/`. No hay un helper tipo `yay`. Si uno de esos paquetes no compila, la ISO sale igual y el fallo queda en `AUR-OMITIDOS.txt`. Las licencias están en [THIRD-PARTY.md](THIRD-PARTY.md).

## Firmware

La ISO, y por tanto una instalación sin red, lleva el firmware de GPU e inalámbrico habitual:

- `linux-firmware-amd`, `linux-firmware-amdgpu`, `linux-firmware-radeon`
- `linux-firmware-intel`
- `linux-firmware-nvidia` (hace falta para nouveau/NVK en GTX 16 y RTX)
- `linux-firmware-realtek`, `linux-firmware-broadcom` y `sof-firmware`
- microcódigos Intel y AMD

No es el metapaquete `linux-firmware` entero: faltan, entre otros, Atheros y MediaTek. Si al instalar hay red, el instalador ejecuta `pacman -S linux-firmware` y completa el resto. Si no hay red, se puede instalar después. La alternativa `pekarchos-install --archinstall` sí pide el metapaquete, porque descarga los paquetes.

## Instalador

Hay dos instaladores en el live. Los dos dejan Plasma en Wayland.

**Instalar PekarchOS (gráfico)** abre Calamares. Copia el live al disco y, si hay red, deja añadir escritorios (XFCE, Cinnamon y MATE en X11; GNOME en Wayland; LXQt en las dos) y el controlador `nvidia-open` para NVIDIA Turing o más nueva. La serie 390 no se puede elegir: el gancho está, y no instala nada del AUR. Se puede borrar el disco, instalar al lado de Windows o particionar a mano. El idioma y el teclado salen en español y se pueden cambiar. GRUB detecta Windows.

El icono **Instalar PekarchOS** abre `pekarchos-install`, el instalador de terminal. Copia el live al disco sin internet. Lo instalado queda con el mismo tema, los mismos programas y el mismo firmware de la ISO. La bienvenida también tiene un botón para Calamares.

1. Aviso y detección de UEFI o BIOS.
2. Elegir el disco (no se ofrece el USB del live).
3. Borrar el disco entero, o usar una partición ya creada para convivir con Windows. En UEFI se reutiliza la partición EFI **sin formatearla**.
4. Usuario y contraseña, los dos obligatorios. root se bloquea salvo que se le ponga contraseña.
5. Resumen. El disco sigue intacto.
6. Escribir `BORRAR` y después `INSTALAR`.

Luego quita lo que solo sirve en el live (usuario `live`, autologin, sudo sin contraseña, servicios de archiso y, en un PC real, las utilidades de invitado de VirtualBox y QEMU). Crea la cuenta, comprueba que la contraseña autentica y que está en `wheel`, instala GRUB y genera el initramfs. El teclado queda en español. Idioma `es_ES.UTF-8`, zona `Europe/Madrid`, hostname `pekarchos`. GRUB lleva os-prober para que aparezca Windows.

Si algo falla, el mensaje es en español y el registro queda en `/var/log/pekarchos-install.log`.

`sudo pekarchos-install --archinstall` abre archinstall con el perfil de PekarchOS. **Necesita red**: no copia este live, descarga los paquetes.

## Menú de arranque de la ISO

BIOS usa Syslinux. UEFI usa GRUB, con el tema de PekarchOS. En los dos hay, además de la entrada normal:

- **Gráficos seguros**: `nomodeset` y sin Plymouth. Para una pantalla negra o para probar si el cuelgue viene de la gráfica. En el menú de BIOS el rótulo va sin tilde (`graficos seguros`) porque la fuente de Syslinux no es Unicode. En GRUB se lee «gráficos seguros».
- **Compatibilidad Ryzen/USB**: `processor.max_cstate=5 usbcore.autosuspend=-1 pcie_aspm=off`. Pensada para cuelgues de ratón y teclado en Ryzen de primera generación (se vio en una MSI MS-7A33 con un Ryzen 7 1700X). Si sigue, prueba un puerto USB 2.0 trasero.

Memtest86+ sigue en el menú.

## Bienvenida

En el sistema instalado, al entrar la primera vez se abre **Bienvenida PekarchOS**. En el live no se abre sola: está en el menú y en el escritorio. Muestra versión, núcleo, Plasma, CPU, RAM y GPU. Los packs que ya trae el sistema salen como instalados. El de desarrollo (`code`, Node.js, Docker) no viene preinstalado; si se elige Docker, se activa el servicio y el usuario entra en el grupo `docker`.

Hay una casilla para instalar Google Chrome desde Flathub. Hace falta red.

## Descargar

La ISO se construye al publicar una etiqueta `v*` o al lanzar el flujo a mano (**Actions → Construir ISO de PekarchOS → Run workflow**). Un pull request no construye la ISO: solo corre estas comprobaciones y la prueba del instalador en QEMU.

No se sube la ISO como artefacto de Actions: no cabe en la cuota. Si se etiqueta `v*` y la prueba del instalador ha pasado, la release adjunta las partes (menos de 2 GiB cada una) y `SHA256SUMS`. Si la prueba falla, no hay release.

Las sumas usan el nombre del archivo, sin carpeta `out/`. También está la suma de cada parte, para comprobarlas antes de unirlas.

```bash
sha256sum -c SHA256SUMS
cat pekarchos-0.3.0-x86_64.iso.part*.bin > pekarchos-0.3.0-x86_64.iso
sha256sum -c SHA256SUMS
```

En Windows, en la carpeta de las partes:

```bat
copy /b pekarchos-0.3.0-x86_64.iso.part00.bin+pekarchos-0.3.0-x86_64.iso.part01.bin+pekarchos-0.3.0-x86_64.iso.part02.bin pekarchos-0.3.0-x86_64.iso
```

En Termux vale el mismo `cat` que en Linux. El número de partes puede cambiar: únelas en orden.

Si en el repositorio están los secretos `SOURCEFORGE_USER`, `SOURCEFORGE_SSH_KEY` y `SOURCEFORGE_PROJECT`, el mismo flujo intenta subir la ISO entera a SourceForge. Sin esos secretos, ese paso no hace nada y no falla.

Las notas de la release salen de [`RELEASE_NOTES.md`](RELEASE_NOTES.md). La plantilla para la siguiente versión es [`PLANTILLA-NOTAS.md`](PLANTILLA-NOTAS.md).

## Probarla en QEMU

Con KVM, 4 GiB de RAM y gráfica virtio (Plasma va por Wayland y necesita DRM):

```bash
qemu-system-x86_64 \
  -enable-kvm -cpu host -m 4G -smp 2 \
  -cdrom pekarchos-0.3.0-x86_64.iso -boot d \
  -vga virtio \
  -netdev user,id=n0 -device virtio-net-pci,netdev=n0
```

El primer arranque tarda: tiene que montar el squashfs y levantar Plasma. El escritorio entra solo como `live`.

## Probarla en VirtualBox

1. Máquina nueva, tipo Linux, 64 bits.
2. 4 GiB de RAM, 2 CPUs y al menos 128 MiB de vídeo.
3. Gráfica VMSVGA o VBoxSVGA.
4. La ISO como disco óptico. BIOS (Syslinux) y UEFI (GRUB) arrancan los dos.
5. La ISO lleva `virtualbox-guest-utils`. En un PC real el instalador las quita.

No instales sobre el disco del anfitrión. Crea un disco virtual vacío.

## Grabarla en un USB

Esto borra el dispositivo. Mira el nombre con `lsblk` y desmonta sus particiones.

Ventoy, balenaEtcher o `dd` valen. Con `dd`, el destino es el disco entero, no una partición:

```bash
sudo dd if=pekarchos-0.3.0-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## Copia de seguridad

**Antes de instalar, copia lo que no quieras perder.** El instalador puede borrar un disco entero. El medio en vivo no toca los discos hasta que lo confirmas.

## Construirla

En Arch Linux, como root, con red:

```bash
sudo ./scripts/build-iso.sh
```

La ISO queda en `out/`, con `SHA256SUMS` al lado (nombres sin ruta). Hacen falta `archiso` y varios GiB libres.

En otra distro, el mismo contenedor que usa Actions:

```bash
mkdir -p out
docker run --privileged --rm \
  -v "$PWD":/src:ro -v "$PWD/out":/out -e ISO_OUT=/out \
  archlinux:latest bash /src/scripts/build-iso.sh
```

Para regenerar el fondo (CC0), sin tocar el logotipo:

```bash
python3 tools/generate_assets.py
```

Para regenerar iconos, splash, Plymouth y el fondo del tema de GRUB a partir del logo oficial:

```bash
python3 tools/make_logo_icons.py
```

Hace falta Pillow solo para esos dos scripts, no para construir la ISO.

Comprobaciones sin construir la ISO:

```bash
bash scripts/check.sh
bash scripts/test-install-qemu.sh
```

## Limitaciones de esta versión

- Es un rolling de Arch: la ISO es una foto del día en que se construyó.
- No hay sesión X11 de Plasma.
- El controlador legado NVIDIA 390 (Fermi, por ejemplo una GTX 570) no entra. Nouveau en Wayland puede dejar Chrome o Chromium en blanco: al iniciar sesión, si el controlador es nouveau, se escribe `--disable-gpu` y `--ozone-platform-hint=auto`. No se fuerza `--ozone-platform=wayland`, porque eso rompe las sesiones X11.
- Plymouth con nouveau antiguo puede dejar la pantalla a oscuras. La entrada de gráficos seguros no lo carga.
- Calamares y un repositorio propio de paquetes `[pekarchos]` quedan para más adelante. El instalador de esta versión es el de terminal.
- `customize_airootfs.sh` sigue funcionando, pero aguas arriba está marcado como obsoleto.
- El fondo de Plasma se aplica en el primer inicio de sesión. Hasta entonces se ve el de Breeze.
- Idioma, teclado y zona del live están fijos en español, España y Madrid.

## Avisos y licencia

El código (perfil, instalador, construcción y el flujo de Actions) es GPL-3.0-or-later. El texto está en [LICENSE](LICENSE).

El logotipo es CC BY-SA 4.0, de Peka / Pekapro. El resto del arte original de Pekapro (fondo, esquemas, tema QML de SDDM) es CC0-1.0. Detalle en [LICENSE-ARTWORK](LICENSE-ARTWORK), [CREDITS.md](CREDITS.md) y [THIRD-PARTY.md](THIRD-PARTY.md).

Para informar de un fallo, abre una incidencia en el repositorio con el modelo del equipo, si arrancaste en BIOS o UEFI, la entrada del menú y, si el sistema ya está instalado, `journalctl -b -1 -k`.
