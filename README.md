# PekarchOS

PekarchOS es un sistema en vivo basado en Arch Linux, hecho para Pekapro. Arranca en KDE Plasma, en español, con el teclado de España y la zona horaria de Madrid. El repositorio es **privado** y tiene que seguir siéndolo: la ISO no se publica en ningún sitio público.

La imagen se construye con [archiso](https://gitlab.archlinux.org/archlinux/archiso), a partir del perfil oficial `releng`. El nombre en `/etc/os-release` es PekarchOS y el hostname del medio en vivo es `pekarchos`.

## Qué trae el escritorio

Conjunto corto de Plasma (`plasma-desktop`), no `plasma-meta`:

- Sesión Plasma (Wayland). En los repos actuales de Arch ya no está el paquete `plasma-x11-session`.
- SDDM con el tema PekarchOS y entrada automática del usuario en vivo.
- Fondo, logotipo, esquema PekarchOS Neon, acento magenta, perfil de Konsole y tema de SDDM (CC0). Iconos [Candy](THIRD-PARTY.md) (GPL-3.0) con respaldo Breeze. Cursor y estilo de widgets: Breeze.
- fastfetch con el logo de PekarchOS al abrir una terminal.

Usuario del medio en vivo:

| | |
| --- | --- |
| Usuario | `live` |
| Contraseña | `live` |
| sudo | sin contraseña |

La cuenta `root` está bloqueada. SSH no se arranca solo.

## Programas incluidos

- Firefox (con el paquete de idioma `firefox-i18n-es-es`)
- LibreOffice Fresh y el paquete de idioma español, más guiones y sinónimos (`hyphen-es`, `mythes-es`)
- VLC, GIMP, Kate, Dolphin, Konsole, Ark, Spectacle
- Bienvenida PekarchOS (ficha del equipo y paquetes opcionales). Kdenlive, OBS y OpenShot no van en la ISO: no caben bajo 2 GiB. OpenShot además ya no está en los repos oficiales. Se instalan desde la bienvenida, salvo OpenShot.
- `git` y el grupo `base-devel`
- Flatpak, Discover y PackageKit. En la construcción se intenta añadir el remoto de Flathub
- NetworkManager, PipeWire (Pulse, ALSA y JACK) con WirePlumber
- Bluetooth (BlueZ y Bluedevil) y impresión (CUPS, `cups-pdf`, Print Manager)
- Firmware habitual en el live (`linux-firmware` de Intel, AMD/AMDGPU, Radeon, Realtek y Broadcom, más `sof-firmware`) y microcódigos Intel y AMD. El instalador mete el metapaquete `linux-firmware` completo en el disco
- Mesa, Vulkan para AMD, Intel y Nouveau, y utilidades de invitado para VirtualBox y QEMU

No lleva un helper del AUR. `yay` y `paru` salen del AUR y alargarían una construcción que tiene que salir solo de `core` y `extra`. Con `git` y `base-devel` ya se puede instalar `paru` después, si hace falta.

Las traducciones de KDE van dentro de cada paquete: en los repos oficiales ya no existe `kde-l10n-es`.

## Instalador

El icono **Instalar PekarchOS** abre [archinstall](https://github.com/archlinux/archinstall) con un perfil de PekarchOS:

- idioma del instalador en español
- locale `es_ES.UTF-8`, teclado `es`, zona `Europe/Madrid`
- KDE Plasma (`plasma-desktop`) y SDDM
- PipeWire, NetworkManager, Bluetooth y CUPS
- controladores gráficos libres
- GRUB, para que sirva igual en BIOS y en UEFI
- hostname `pekarchos`
- los mismos programas de arriba

El disco y las contraseñas no vienen rellenados: hay que elegirlos en el menú y leer el resumen antes de confirmar. Hace falta red, porque archinstall descarga el sistema; no clona el live a ciegas.

Al terminar, un comando del perfil instala el paquete `pekarchos-branding` (fondo, tema, fastfetch y `os-release`) desde la propia ISO.

**Calamares no entra en esta versión.** No está en los repositorios oficiales, solo en el AUR, y el empaquetado arrastra más piezas del AUR. Un instalador a medias sería peor que archinstall, que es el que Arch mantiene y el que ya usa el perfil `releng`.

## Bienvenida

En el sistema instalado, al entrar la primera vez se abre **Bienvenida PekarchOS** (si dejas marcada «Mostrar al iniciar»). En el live no se abre sola; está en el menú y en el escritorio. Muestra versión, núcleo, Plasma, CPU, RAM y GPU, y puede instalar paquetes oficiales con `pkexec` y `pacman`:

- Vídeo y streaming: Kdenlive, OBS Studio, HandBrake, frei0r, ffmpeg. OpenShot se omite: ya no está en `extra`.
- Juegos: Steam (activa `multilib`), Lutris, Wine, GameMode, MangoHud
- Gráficos: Krita, Inkscape, Blender
- Oficina extra: LibreOffice en español, diccionario y Okular
- Desarrollo: `code` (compilación abierta, MIT), Python, Node.js, Docker
- Multimedia: Audacity, mpv y códecs GStreamer
- Internet: Thunderbird, Chromium, qBittorrent
- Opción aparte para instalar Flatpak y añadir Flathub

Esas colecciones no van preinstaladas en la ISO: Kdenlive y OBS, con sus dependencias (sobre todo `cef` y OpenCV), suman unos 190 MiB y pasarían de 2 GiB.

## Descargar la ISO

Hace falta acceso al repositorio privado `pekapro-lab/pekarchos`. Nada de esto es público.

### Desde Actions

1. Abre la pestaña **Actions**.
2. Elige el flujo **Construir ISO de PekarchOS**.
3. Entra en una ejecución en verde.
4. Al final, en **Artifacts**, descarga `pekarchos-iso`.

El artefacto caduca a los 14 días. El archivo se llama `pekarchos-AAAA.MM.DD-x86_64.iso`. Comprueba la suma con el `SHA256SUMS` que va al lado:

```bash
sha256sum -c SHA256SUMS
```

El flujo se lanza al abrir una pull request, al empujar a `main`, al publicar una etiqueta `v*` y también a mano (**Run workflow**).

### Desde una release

Solo cuando alguien empuja una etiqueta `v*` (por ejemplo `v0.1.0`). La release queda en el mismo repositorio privado.

GitHub no acepta un archivo de release de 2 GiB o más. Si la ISO se pasa, el flujo la parte. Para unirla:

```bash
cat pekarchos-*.iso.part* > pekarchos.iso
sha256sum -c SHA256SUMS
```

## Probarla en QEMU

Con KVM, 4 GiB de RAM y la gráfica virtio (Plasma va por Wayland y necesita DRM):

```bash
qemu-system-x86_64 \
  -enable-kvm -cpu host -m 4G -smp 2 \
  -cdrom pekarchos-*.iso -boot d \
  -vga virtio \
  -netdev user,id=n0 -device virtio-net-pci,netdev=n0
```

Sin ventana gráfica, VNC en el puerto 5901:

```bash
qemu-system-x86_64 \
  -enable-kvm -cpu host -m 4G -smp 2 \
  -cdrom pekarchos-*.iso -boot d \
  -vga virtio -display vnc=127.0.0.1:1 \
  -netdev user,id=n0 -device virtio-net-pci,netdev=n0
```

El primer arranque tarda: tiene que montar el squashfs y levantar Plasma. El escritorio entra solo como `live`.

## Probarla en VirtualBox

1. Máquina nueva, tipo Linux, versión Arch o Linux 2.6 / 3.x / 4.x / 5.x (64-bit).
2. 4 GiB de RAM, 2 CPUs y al menos 128 MiB de vídeo.
3. Gráfica VMSVGA o VBoxSVGA.
4. La ISO como disco óptico. BIOS y UEFI arrancan los dos: Syslinux en BIOS y systemd-boot en UEFI.
5. La ISO ya lleva `virtualbox-guest-utils`.

No instales sobre el disco de la máquina anfitriona. Crea un disco virtual vacío.

## Grabarla en un USB

Esto borra el dispositivo que elijas. Mira el nombre con `lsblk` antes de seguir y desmonta sus particiones.

### Ventoy

Instala Ventoy en el USB y copia la ISO a la partición de datos. Ventoy arranca la ISO sin volver a grabar el dispositivo.

### balenaEtcher

Abre Etcher, elige la ISO, elige el USB y pulsa Flash. No hace falta descomprimir nada.

### dd

Sustituye `/dev/sdX` por el disco entero, no por una partición (`/dev/sdX`, no `/dev/sdX1`):

```bash
sudo dd if=pekarchos-AAAA.MM.DD-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## Copia de seguridad

**Antes de instalar, copia lo que no quieras perder.** El instalador puede borrar un disco entero. Revisa el dispositivo en el resumen de archinstall. Si no estás seguro de cuál es, cancela.

El medio en vivo no toca los discos hasta que lo confirmas en el instalador.

## Construirla en local

En Arch Linux, como root:

```bash
sudo ./scripts/build-iso.sh
```

La ISO queda en `out/`. Hacen falta red, `archiso` y bastante disco (el árbol de trabajo ocupa varios GiB; el script lo borra al terminar).

En otra distro vale el mismo contenedor que usa Actions:

```bash
mkdir -p out
docker run --privileged --rm \
  -v "$PWD":/src:ro -v "$PWD/out":/out -e ISO_OUT=/out \
  archlinux:latest bash /src/scripts/build-iso.sh
```

`--privileged` hace falta porque `mkarchiso` monta sistemas de archivos.

Para regenerar el fondo y el logotipo (no hace falta para construir la ISO; los PNG ya están en el repo):

```bash
python3 tools/generate_assets.py
```

## Limitaciones de esta versión

- Es un rolling de Arch: la ISO es una foto del día en que se construyó.
- El instalador necesita red.
- No hay sesión X11 de Plasma en los repos oficiales ahora mismo.
- En el live no van `linux-firmware-nvidia`, `linux-firmware-atheros`, `linux-firmware-mediatek` ni `linux-firmware-other`, ni la fuente de emoji: con el metapaquete entero la ISO pasa de 2 GiB y GitHub no admite ese asset en una release. Esos paquetes se instalan con pacman si el equipo los necesita. En el disco, archinstall sí instala el metapaquete `linux-firmware` completo.
- El live tampoco lleva `open-vm-tools` ni las páginas de manual en español. El perfil de archinstall pide `noto-fonts-emoji` y `man-pages-es` para el sistema instalado.
- GitHub Actions tiene poca cuota de artefactos en los planes gratuitos, y cada asset de una release tiene que pesar menos de 2 GiB. Si la ISO se pasa, la release va en partes; el artefacto del flujo intenta subir el archivo entero.
- `customize_airootfs.sh` sigue funcionando en el archiso actual, pero aguas arriba está marcado como obsoleto.
- El fondo se aplica en el primer inicio de sesión. Hasta ese momento se ve el fondo de Breeze.
- El teclado de Plasma queda en `es` por el esqueleto de usuario. En el instalador también se puede cambiar.
