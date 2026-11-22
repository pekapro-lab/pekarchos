# PekarchOS 0.3.0

Primera imagen pensada para publicarse. Sigue siendo un rolling de Arch Linux
con KDE Plasma 6 en Wayland, en español.

## Novedades

- Firefox es el navegador por defecto. Google Chrome ya no va dentro de la ISO: se ofrece desde la bienvenida, por Flathub.
- Logotipo nuevo (Peka / Pekapro, CC BY-SA 4.0) en los iconos, la bienvenida, el avatar, Acerca de KDE, Plymouth y GRUB.
- Animación de arranque Plymouth y tema de GRUB, en la ISO y en el sistema instalado.
- Centro de información de KDE (`kinfocenter`) instalado, con las páginas de Vulkan, Wayland y OpenCL.
- Firmware de GPU en el disco aunque no haya red: AMD, AMDGPU, Intel y NVIDIA. Con red, el instalador añade el metapaquete `linux-firmware`.
- Menú de la ISO, en BIOS y en UEFI: «gráficos seguros» (`nomodeset`) y «compatibilidad Ryzen/USB».
- Los lanzadores del escritorio son ejecutables. Solo se crea `Escritorio`, no también `Desktop`.
- La versión 0.3.0 sale de un único archivo `VERSION`.

## Requisitos

- Procesador de 64 bits
- 4 GiB de RAM (8 GiB van más holgados)
- 20 GiB de disco para instalar
- UEFI o BIOS
- Para grabar: un USB de 8 GiB o más

## Usuario del medio en vivo

| | |
| --- | --- |
| Usuario | `live` |
| Contraseña | `live` |

El escritorio entra solo. `live` puede usar sudo sin contraseña. Antes de instalar, haz una copia de seguridad.

## Comprobar la descarga

`SHA256SUMS` lista el nombre del archivo, sin carpetas. También trae la suma de cada parte.

```bash
sha256sum -c SHA256SUMS
```

## Unir las partes

GitHub no admite un archivo de release de 2 GiB o más. Si la imagen viene partida:

Linux y Termux:

```bash
cat pekarchos-0.3.0-x86_64.iso.part*.bin > pekarchos-0.3.0-x86_64.iso
sha256sum -c SHA256SUMS
```

Windows (símbolo del sistema), en la carpeta de las partes:

```bat
copy /b pekarchos-0.3.0-x86_64.iso.part00.bin+pekarchos-0.3.0-x86_64.iso.part01.bin+pekarchos-0.3.0-x86_64.iso.part02.bin pekarchos-0.3.0-x86_64.iso
```

El número de partes puede cambiar. Únelas en orden (`part00`, `part01`, …).

## Instalación

En el escritorio, «Instalar PekarchOS». Copia este sistema al disco y no necesita internet. Escribe `BORRAR` y después `INSTALAR`. Para convivir con Windows, elige una partición ya creada: en UEFI no se formatea la partición EFI.

`sudo pekarchos-install --archinstall` es la alternativa con red: instala con archinstall usando el perfil de PekarchOS.

## Problemas conocidos

- NVIDIA Fermi (serie 390, por ejemplo una GTX 570) no tiene controlador en esta versión. Nouveau en Wayland puede dejar Chromium en blanco: al entrar, si el controlador es nouveau, se añade `--disable-gpu` y la pista de plataforma `auto`. No se fuerza Wayland, para no romper XFCE ni Cinnamon.
- En algunas placas Ryzen de primera generación (se vio en una MSI MS-7A33 con un 1700X) el live se quedó congelado y murieron ratón y teclado. Prueba la entrada «compatibilidad Ryzen/USB» y, si sigue, un puerto USB 2.0 trasero. «Gráficos seguros» descarta la gráfica.
- Plymouth con nouveau antiguo puede dejar la pantalla negra un momento. La entrada de gráficos seguros arranca sin la animación.
- No hay sesión X11 de Plasma en los repos actuales de Arch.
- Calamares, el repositorio propio `[pekarchos]` y el controlador `nvidia-390xx` no entran en esta versión.
